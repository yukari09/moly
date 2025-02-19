defmodule MonorepoWeb.Affiliate.UserPageLive do
  use MonorepoWeb, :live_view
  require Ash.Query

  alias Phoenix.HTML.FormField

  @per_page 20

  def mount(_params, _session, socket) do
    country_category =
      Monorepo.Terms.read_by_term_slug!("countries", actor: %{roles: [:user]}) |> List.first()

    industry_category =
      Monorepo.Terms.read_by_term_slug!("industries", actor: %{roles: [:user]}) |> List.first()

    socket =
      socket
      |> assign(country_category: country_category, industry_category: industry_category)
      |> assign(:modal_id, Monorepo.Helper.generate_random_id())
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        auto_upload: true,
        progress: &handle_progress/3
      )
      |> allow_upload(:banner,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        auto_upload: true,
        progress: &handle_progress/3
      )

    {:ok, socket}
  end

  def handle_params(%{"username" => "@" <> username} = params, _uri, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    post_type = Map.get(params, "type", "published")
    posts = get_user_posts(username, page, post_type)

    user =
      Ash.Query.new(Monorepo.Accounts.User)
      |> Ash.Query.filter(user_meta.meta_key == :username and user_meta.meta_value == ^username)
      |> Ash.Query.load([:user_meta])
      |> Ash.read_first!(
        actor: %{roles: [:user]},
        context: %{private: %{ash_authentication?: true}}
      )

    form = generate_form(user, socket.assigns.current_user)

    socket =
      assign(socket,
        page: page,
        post_type: post_type,
        end_of_timeline?: false,
        username: username
      )
      |> stream(:posts, posts)
      |> assign(:user, user)
      |> assign(:form, form)

    {:noreply, socket}
  end

  def handle_event("form-changed", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"form" => form}, socket) do
    user_meta = Monorepo.Helper.get_in_from_keys(form, ["user_meta"])

    user_meta =
      case user_meta do
        %{"1" => %{"meta_key" => "username", "meta_value" => username}} ->
          username =
            if Regex.match?(~r/^@/, username) do
              String.replace(username, "@", "")
            else
              username
            end

          Map.put_new(user_meta, "1", %{"meta_value" => username, "meta_key" => "username"})

        _ ->
          user_meta
      end

    {_result, record} =
      Ash.Changeset.new(socket.assigns.current_user)
      |> Ash.update(%{"user_meta" => user_meta},
        action: :update_user_meta,
        context: %{private: %{ash_authentication?: true}}
      )

    new_username = Monorepo.Accounts.Helper.load_meta_value_by_meta_key(record, :username)

    socket =
      assign(socket, :current_user, record)
      |> push_navigate(to: ~p"/user/page/@#{new_username}")

    {:noreply, socket}
  end

  defp handle_progress(uploader, entry, socket) do
    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{path: path} = _meta ->
          old_file =
            Monorepo.Accounts.Helper.load_meta_value_by_meta_key(
              socket.assigns.current_user,
              uploader
            )

          if old_file do
            filename = old_file["filename"]
            Monorepo.Helper.remove_object(filename)
          end

          uploaded_file =
            case uploader do
              :avatar -> Monorepo.Accounts.Helper.generate_avatar_from_entry(entry, path)
              :banner -> Monorepo.Accounts.Helper.generate_banner_from_entry(entry, path)
            end

          {:ok, uploaded_file}
        end)

      new_user_meta_party = [%{meta_key: uploader, meta_value: uploaded_file}]
      changeset = Ash.Changeset.new(socket.assigns.current_user)

      result =
        Ash.update(changeset, %{user_meta: new_user_meta_party},
          action: :update_user_meta,
          context: %{private: %{ash_authentication?: true}}
        )

      socket =
        case result do
          {:ok, user} ->
            put_flash(socket, :info, "Your information has been updated.")
            |> assign(:user, user)

          {:error, _} ->
            put_flash(socket, :error, "Your information update failed, please try again later")
        end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp get_user_posts(username, page, "published") do
    offset = (page - 1) * @per_page

    opts = [
      action: :read,
      actor: %{roles: [:user]},
      page: [limit: @per_page, offset: offset, count: true]
    ]

    Ash.Query.filter(
      Monorepo.Contents.Post,
      post_type == :affiliate and post_status in [:pending, :publish]
    )
    |> Ash.Query.filter(
      author.user_meta.meta_key == :username and author.user_meta.meta_value == ^username
    )
    |> Ash.Query.load([:author, :post_tags, :post_categories, post_meta: :children])
    |> Ash.read!(opts)
    |> Map.get(:results)
  end

  defp get_user_posts(username, page, "saved") do
    offset = (page - 1) * @per_page

    opts = [
      action: :read,
      actor: %{roles: [:user]},
      page: [limit: @per_page, offset: offset, count: true]
    ]

    Ash.Query.filter(Monorepo.Contents.Post, post_type == :affiliate)
    |> Ash.Query.filter(
      author.user_meta.meta_key == :username and author.user_meta.meta_value == ^username
    )
    |> Ash.Query.filter(post_actions.action == :saved)
    |> Ash.read!(opts)
    |> Map.get(:results)
  end

  defp generate_form(_, nil), do: nil

  defp generate_form(%{id: user_id} = user, %{id: current_user_id})
       when user_id == current_user_id do
    AshPhoenix.Form.for_update(user, :update_user_meta,
      forms: [
        auto?: true
      ],
      data: user,
      actor: user
    )
    |> to_form()
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="relative lg:h-[250px] bg-primary">
        <div class="w-full h-full overflow-hidden">
          <img class="w-full h-full object-cover overflow-hidden" src={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :banner)["xxl"]} />
        </div>

        <div class="mx-4 flex justify-between items-end -mt-12">
          <div>
            <img :if={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :avatar)} class="inline-block size-24 rounded-full" src={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :avatar)["128"]} alt="">
            <span :if={!Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :avatar)} class="inline-flex size-24 items-center justify-center rounded-full bg-primary border-2 border-white">
              <span class="font-medium text-white uppercase text-4xl">{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :name) |> String.slice(0, 1)}</span>
            </span>
          </div>
          <div :if={@current_user && @current_user.id == @user.id} phx-click={MonorepoWeb.TailwindUI.show_modal(@modal_id)}>
            <button type="button" class="rounded-full bg-white px-2.5 py-1 text-sm font-semibold text-gray-500 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">Edit Profile</button>
          </div>
        </div>
      </div>

      <div class="flex items-start gap-8">
        <div class="w-80 py-4 px-2 mt-16">
          <div class="text-2xl px-4 text-gray-900">
            <p><%= Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :name) %></p>
            <p class="text-xs/6">@{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :username)}</p>
          </div>
          <p class="text-sm text-gray-500 my-2 px-4">{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :bio)}</p>
          <div class="mb-12">
            <div>
              <div class="px-4 w-full text-sm  !text-gray-500 !outline-none break-words resize-none overflow-hidden">{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :description)}</div>
            </div>

            <div class="grid grid-cols-1">
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :location)}
              </div>
              <.icon name="hero-map-pin" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
            </div>

            <div class="grid grid-cols-1">
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :website)}
              </div>
              <.icon name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
            </div>

            <div class="grid grid-cols-1">
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :twitter)}
              </div>
              <Lucideicons.twitter name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
            </div>

            <div class="grid grid-cols-1">
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :facebook)}
              </div>
              <Lucideicons.facebook name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
            </div>

            <div class="grid grid-cols-1">
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :instagram)}
              </div>
              <Lucideicons.instagram name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
            </div>
          </div>
        </div>
        <!--start tab-->
        <div class="grow container mx-auto sm:px-6 lg:px-8">
          <div class="relative border-b border-gray-200 pb-5 sm:pb-0">
            <%!-- <div class="md:flex md:items-center md:justify-between">
              <div class="mt-3 flex md:absolute md:top-3 md:right-0 md:mt-0">
                <button type="button" class="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 ring-1 shadow-xs ring-gray-300 ring-inset hover:bg-gray-50">Share</button>
                <button type="button" class="ml-3 inline-flex items-center rounded-md bg-gray-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-gray-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-600">Create</button>
              </div>
            </div> --%>
            <div class="mt-10">
              <div class="grid grid-cols-1 sm:hidden">
                <!-- Use an "onChange" listener to redirect the user to the selected tab URL. -->
                <select aria-label="Select a tab" class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-2 pr-8 pl-3 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600">
                  <option>Applied</option>
                  <option>Phone Screening</option>
                  <option selected>Interview</option>
                  <option>Offer</option>
                  <option>Hired</option>
                </select>
                <svg class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end fill-gray-500" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true" data-slot="icon">
                  <path fill-rule="evenodd" d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd" />
                </svg>
              </div>
              <!-- Tabs at small breakpoint and up -->
              <div class="hidden sm:block">
                <nav class="-mb-px flex space-x-8">
                  <!-- Current: "border-gray-500 text-gray-600", Default: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700" -->
                  <.link
                    :for={{value, label} <- [published: :Published, saved: :Saved]}
                    patch={~p"/user/page/@#{@username}?#{%{type: value}}"}
                    class={[
                      "border-b-2 px-1 pb-4 text-sm font-medium whitespace-nowrap",
                      @post_type == to_string(value) && "border-green-500 text-green-600" || "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
                    ]}
                  >{label}</.link>
                </nav>
              </div>
            </div>
          </div>
          <div
            id={"#{@post_type}-list"}
            phx-update="stream"
            class="mx-auto pt-6 pb-10 grid max-w-2xl grid-cols-1 gap-x-8 gap-y-20 lg:mx-0 lg:max-w-none lg:grid-cols-3"
            phx-page-loading
          >
            <article :for={{id, post} <- @streams.posts} id={id} class="flex flex-col items-start justify-between">
              <div class="relative w-full">
                <img src={Monorepo.Utilities.MetaValue.post_feature_image(post, :attachment_affiliate_media_feature, "medium")} alt="" class="aspect-video w-full rounded-2xl bg-gray-100 object-cover sm:aspect-[2/1] lg:aspect-[3/2]">
                <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-900/10"></div>
              </div>
              <div class="max-w-xl">
                <div class="relative">
                  <h3 class="mt-3 text-lg/6 font-semibold text-gray-900 group-hover:text-gray-600 line-clamp-2">
                    <.link navigate={~p"/product/#{post.post_name}"}>
                      <span class="absolute inset-0"></span>
                      {post.post_title}
                    </.link>
                  </h3>
                </div>
                <div class="mt-2 flex items-center gap-x-4 text-xs">
                  <time datetime={post.inserted_at |> Timex.format!("{YYYY}-{D}-{0M}")} class="text-gray-500">{post.inserted_at |> Timex.format!("{Mshort} {D}, {YYYY}")}</time>
                  <.link navigate={"/c/#{Monorepo.Utilities.Term.get_first_and_return_by_keys(post.post_categories, "category", [:slug], @industry_category.id)}"}  class="relative z-10 rounded-full bg-gray-50 px-3 py-1.5 font-medium text-gray-600 hover:bg-gray-100">{Monorepo.Utilities.Term.get_first_and_return_by_keys(post.post_categories, "category", [:name], @industry_category.id)}</.link>
                  <div class="relative z-10 rounded-full bg-gray-50 px-3 py-1.5 font-medium text-gray-600 hover:bg-gray-100" :if={({Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_unit) |> Monorepo.Utilities.MetaValue.format_meta_value}) == "%"}>
                    <span class="font-bold">{Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_min) |> Monorepo.Utilities.MetaValue.format_meta_value}</span>
                    {Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_unit) |> Monorepo.Utilities.MetaValue.format_meta_value}
                    -
                    <span class="font-bold">{Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_max) |> Monorepo.Utilities.MetaValue.format_meta_value}</span>
                    {Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_unit) |> Monorepo.Utilities.MetaValue.format_meta_value}

                    <span class="font-medium">{Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_model) |> Monorepo.Utilities.MetaValue.format_meta_value}</span>
                  </div>
                  <div  class="relative z-10 rounded-full bg-gray-50 px-3 py-1.5 font-medium text-gray-600 hover:bg-gray-100" :if={({Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_unit) |> Monorepo.Utilities.MetaValue.format_meta_value}) != "%"}>
                    {Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_unit) |> Monorepo.Utilities.MetaValue.format_meta_value}
                    <span class="font-bold">{Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_min) |> Monorepo.Utilities.MetaValue.format_meta_value}</span>
                    -
                    {Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_unit) |> Monorepo.Utilities.MetaValue.format_meta_value}
                    <span class="font-bold">{Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_max) |> Monorepo.Utilities.MetaValue.format_meta_value}</span>

                    <span class="font-medium">{Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_model) |> Monorepo.Utilities.MetaValue.format_meta_value}</span>
                  </div>
                </div>
              </div>
            </article>
          </div>
        </div>
        <!--end-->
      </div>
    </div>
    <MonorepoWeb.TailwindUI.modal
      id={@modal_id}
      :if={@current_user && @current_user.id == @user.id}
      inner_class="!p-0 !m-0 w-[300px] max-h-[80%] overflow-scroll-y"
      show={false}
    >
      <.form for={@form} phx-change="form-changed" phx-submit="save">
        <div class="relative lg:h-[120px] bg-primary">
          <div class="w-full h-full overflow-hidden">
            <img class="w-full h-full object-cover overflow-hidden" src={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :banner)["xl"]} />
            <div class="w-full h-full">
              <label for={@uploads.banner.ref} class="p-1 rounded-full  bg-black absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 opacity-60 hover:opacity-80 cursor-pointer">
                <Lucideicons.camera  class="size-5 text-white" />
                <.live_file_input class="hidden" upload={@uploads.banner}  />
              </label>
            </div>
          </div>
          <div class="mx-2 flex justify-between items-end -mt-10">
            <div class="relative size-20">
              <img :if={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :avatar)} class="inline-block size-20 rounded-full" src={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :avatar)["128"]} alt="">
              <span :if={!Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :avatar)} class="inline-flex size-20 items-center justify-center rounded-full bg-primary border-2 border-white">
                <span class="font-medium text-white uppercase text-4xl">{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, :name) |> String.slice(0, 1)}</span>
              </span>
              <label for={@uploads.avatar.ref} class="p-1 rounded-full  bg-black absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 opacity-60 hover:opacity-80 cursor-pointer">
                <Lucideicons.camera  class="size-5 text-white" />
                <.live_file_input class="hidden" upload={@uploads.avatar} />
              </label>
            </div>
          </div>
        </div>

        <div class="px-4 mt-16 space-y-6">
          <.user_meta_input
            :for={{{f, l}, i} <- Enum.with_index([
              {:name, :Name}, {:username, :UserName}, {:location, :Location},
              {:bio, :Bio}, {:website, :Website}, {:twitter, :Twitter}, {:facebook, :Facebook},
              {:instagram, :Instagram}
            ])}
            :if={f !== :username || !is_modified_username?(@user)}
            field={%FormField{
              id: "#{@form[:user_meta].id}-#{i}-meta-value",
              name: "#{@form[:user_meta].name}[#{i}][meta_value]",
              value: Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@user, f),
              errors: [],
              field: :user_meta,
              form: @form
            }}
            label={l}
            meta_key={%{key: "#{@form[:user_meta].name}[#{i}][meta_key]", value: f}}
            id="user-meta-#{i}-meta-value-input"
          />
        </div>
        <div class="p-4 flex items-end justify-end">
          <button type="submit" class="rounded-md bg-green-600 px-2.5 py-1.5 text-sm font-semibold text-white shadow-xs hover:bg-green-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-green-600">Save</button>
        </div>
      </.form>
    </MonorepoWeb.TailwindUI.modal>
    """
  end

  defp user_meta_input(assigns) do
    ~H"""
    <div id={@id} class="relative">
      <label for={@field.id} class="absolute -top-2 left-2 inline-block rounded-lg bg-white px-1 text-xs font-medium text-gray-500">{@label}</label>
      <input
        id={@field.id}
        type="text"
        name={@field.name}
        value={@field.value}
        class="block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
      />
      <input type="hidden" name={@meta_key.key} value={@meta_key.value}/>
    </div>
    """
  end

  defp is_modified_username?(user) do
    username = Monorepo.Accounts.Helper.load_meta_value_by_meta_key(user, :username)
    name = Monorepo.Accounts.Helper.load_meta_value_by_meta_key(user, :name)
    email = user.email

    if username == name and String.contains?(email, name) do
      false
    else
      true
    end
  end
end
