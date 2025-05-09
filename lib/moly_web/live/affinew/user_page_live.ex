defmodule MolyWeb.Affinew.UserPageLive do
  use MolyWeb, :live_view
  require Ash.Query

  alias Phoenix.HTML.FormField

  @per_page 18

  def mount(_params, _session, socket) do
    country_category =
      Moly.Terms.read_by_term_slug!("countries", actor: %{roles: [:user]}) |> List.first()

    industry_category =
      Moly.Terms.read_by_term_slug!("industries", actor: %{roles: [:user]}) |> List.first()

    socket =
      socket
      |> assign(country_category: country_category, industry_category: industry_category)
      |> assign(:modal_id, Moly.Helper.generate_random_id())
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

    {:ok, socket, layout: {MolyWeb.Layouts, :affinew}}
  end

  def handle_params(%{"username" => username} = params, _uri, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    post_type = Map.get(params, "type", "published")

    user =
      Ash.Query.new(Moly.Accounts.User)
      |> Ash.Query.filter(user_meta.meta_key == :username and user_meta.meta_value == ^username)
      |> Ash.Query.load([:user_meta])
      |> Ash.read_first!(
        actor: %{roles: [:user]},
        context: %{private: %{ash_authentication?: true}}
      )

    form = generate_form(user, socket.assigns.current_user)

    socket =
      socket
      |> assign(:page, page)
      |> assign(:username, username)
      |> assign(:post_type, post_type)
      |> assign(:user, user)
      |> assign(:form, form)
      |> get_user_posts()
      |> assign(:page_title, "#{username}")

    {:noreply, socket}
  end

  def handle_event("form-changed", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"form" => form}, socket) do
    user_meta = Moly.Helper.get_in_from_keys(form, ["user_meta"])

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

    new_username = Moly.Utilities.Account.load_meta_value_by_meta_key(record, "username")

    socket =
      assign(socket, :current_user, record)
      |> push_navigate(to: ~p"/user/@#{new_username}")

    {:noreply, socket}
  end

  defp handle_progress(uploader, entry, socket) do
    uploader = if is_atom(uploader), do: to_string(uploader), else: uploader

    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{path: path} = _meta ->
          old_file =
            Moly.Utilities.Account.load_meta_value_by_meta_key(
              socket.assigns.current_user,
              uploader
            )

          if old_file do
            filename = old_file["filename"]
            Moly.Helper.remove_object(filename)
          end

          uploaded_file =
            case uploader do
              "avatar" -> Moly.Utilities.Account.generate_avatar_from_entry(entry, path)
              "banner" -> Moly.Utilities.Account.generate_banner_from_entry(entry, path)
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

  defp get_user_posts(
         %{assigns: %{page: page, post_type: "published", username: _username}} = socket
       ) do
    {count, posts} =
      MolyWeb.Affinew.QueryEs.list_query_by_user_posted(socket.assigns.user.id, page, @per_page)

    page_meta = Moly.Helper.pagination_meta(count, @per_page, page, 5)
    socket = assign(socket, posts: posts, page_meta: page_meta)

    socket
  end

  defp get_user_posts(%{assigns: %{page: page, post_type: "saved", user: user}} = socket) do
    offset = (page - 1) * @per_page

    opts = [
      action: :read,
      actor: %{roles: [:user]},
      page: [limit: @per_page, offset: offset, count: true]
    ]

    query_result =
      Ash.Query.filter(
        Moly.Contents.Post,
        post_type == :affiliate and post_status in [:pending, :publish]
      )
      |> Ash.Query.filter(post_actions.action == :bookmark and post_actions.user_id == ^user.id)
      |> Ash.Query.select([:id])
      |> Ash.read!(opts)

    posts =
      Enum.map(query_result.results, & &1.id)
      |> MolyWeb.Affinew.QueryEs.list_query_by_post_ids()

    page_meta = Moly.Helper.pagination_meta(query_result.count, @per_page, page, 8)
    socket = assign(socket, posts: posts, page_meta: page_meta)

    socket
  end

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

  defp generate_form(_, _), do: nil

  def render(assigns) do
    ~H"""
    <div>
      <div class="relative h-[135px] lg:h-[250px] bg-primary mb-20 lg:mb-0">
        <div class="w-full h-full overflow-hidden">
          <img
            :if={Moly.Utilities.Account.user_banner(@user, "xxl")}
            class="w-full h-full object-cover overflow-hidden"
            src={Moly.Utilities.Account.user_banner(@user, "xxl")}
          />
        </div>

        <div class="absolute w-full lg:static">
          <div class="px-2 lg:px-4 flex justify-between items-end -mt-10 lg:-mt-12">
            <div>
              <img
                :if={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "avatar")}
                class="inline-block size-20 lg:size-24 rounded-full border-base-content/4 border-1"
                src={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "avatar")["128"]}
                alt=""
              />
              <span
                :if={!Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "avatar")}
                class="inline-flex size-20 lg:size-24 items-center justify-center rounded-full bg-primary border-2 border-white"
              >
                <span class="font-medium text-white uppercase text-4xl">
                  {Moly.Utilities.Account.user_name(@user, 1)}
                </span>
              </span>
            </div>
            <div
              :if={@current_user && @current_user.id == @user.id}
              class="lg:mt-0  space-y-2"
              phx-click={MolyWeb.TailwindUI.show_modal(@modal_id)}
            >
              <div class="lg:hidden flex items-center"></div>
              <button type="button" class="btn btn-sm md:btn-md">
                Edit Profile
              </button>
            </div>
          </div>
          <div class="lg:hidden pt-2">
            <div class="px-4">
              <p class="text-gray-900">{Moly.Utilities.Account.user_name(@user)}</p>
              <p class="text-xs/6 text-gray-500">
                @{Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "username")}
              </p>
              <p>{Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "bio")}</p>
            </div>
          </div>
        </div>
      </div>

      <div class="flex items-start gap-8">
        <div class="w-80 py-4 px-2 mt-16 hidden lg:block">
          <div class="text-2xl px-4 text-gray-900">
            <p>{Moly.Utilities.Account.user_name(@user)}</p>
            <p class="text-xs/6">
              @{Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "username")}
            </p>
          </div>
          <p class="text-sm text-gray-500 my-2 px-4">
            {Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "bio")}
          </p>
          <div class="mb-12">
            <div>
              <div class="px-4 w-full text-sm  !text-gray-500 !outline-none break-words resize-none overflow-hidden">
                {Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "description")}
              </div>
            </div>

            <div
              :if={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "location")}
              class="grid grid-cols-1"
            >
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "location")}
              </div>
              <.icon
                name="hero-map-pin"
                class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4"
              />
            </div>

            <div
              :if={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "website")}
              class="grid grid-cols-1"
            >
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "website")}
              </div>
              <.icon
                name="hero-globe-alt"
                class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4"
              />
            </div>

            <div
              :if={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "twitter")}
              class="grid grid-cols-1"
            >
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "twitter")}
              </div>
              <Lucideicons.twitter
                name="hero-globe-alt"
                class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4"
              />
            </div>

            <div
              :if={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "facebook")}
              class="grid grid-cols-1"
            >
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "facebook")}
              </div>
              <Lucideicons.facebook
                name="hero-globe-alt"
                class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4"
              />
            </div>

            <div
              :if={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "instagram")}
              class="grid grid-cols-1"
            >
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "instagram")}
              </div>
              <Lucideicons.instagram
                name="hero-globe-alt"
                class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4"
              />
            </div>
          </div>
        </div>

    <!--start tab-->
        <div class="grow container mx-auto px-2 sm:px-6 lg:px-8">
          <div class="border-b border-gray-200 -mx-2 sm:mx-0 px-2 sm:pb-0">
            <div class="mt-16">
              <div>
                <nav class="-mb-px flex space-x-8">
                  <.link
                    :for={{value, label} <- [published: :Published, saved: :Saved]}
                    patch={live_url(%{username: @username, type: value})}
                    class={[
                      "border-b-2 px-1 pb-2 sm:pb-4 text-sm font-medium whitespace-nowrap",
                      (@post_type == to_string(value) && "border-green-500 text-green-600") ||
                        "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
                    ]}
                  >
                    {label}
                  </.link>
                </nav>
              </div>
            </div>
          </div>
          <div
            id={"#{@post_type}-list"}
            class="mx-auto pt-4 grid max-w-2xl grid-cols-1 gap-2 lg:mx-0 lg:max-w-none lg:grid-cols-3"
            phx-page-loading
          >
            <MolyWeb.Affinew.Components.card :for={post <- @posts} post={post} />
          </div>
          <div class="mx-auto my-8 lg:my-16">
            <nav :if={@page_meta.total_pages > 1} class="flex items-center justify-center space-x-2">
              <!-- Previous Button -->
              <.link
                :if={@page_meta.prev}
                navigate={live_url(%{username: @username, type: @post_type, page: @page_meta.prev})}
                class="rounded-full  p-2 bg-gray-50 hover:bg-gray-100"
              >
                <Lucideicons.arrow_left class="w-4 h-4 md:w-5 md:h-5" />
              </.link>

    <!-- Page Numbers -->
              <.link
                :for={page <- @page_meta.page_range}
                navigate={live_url(%{username: @username, type: @post_type, page: page})}
                class={[
                  "px-3 py-2 text-gray-500 border-b-2 border-white hover:border-gray-900 hover:text-gray-900",
                  page == @page && "border-gray-900 text-gray-900"
                ]}
              >
                {page}
              </.link>

              <.link
                :if={@page_meta.next}
                navigate={live_url(%{username: @username, type: @post_type, page: @page_meta.next})}
                class="rounded-full  p-2 bg-gray-50 hover:bg-gray-100"
              >
                <Lucideicons.arrow_right class="w-4 h-4 md:w-5 md:h-5" />
              </.link>
            </nav>
          </div>
        </div>
        <!--end-->
      </div>
    </div>
    <MolyWeb.TailwindUI.modal
      :if={@current_user && @current_user.id == @user.id}
      id={@modal_id}
      inner_class="!p-0 !m-0 w-[300px] max-h-[80%] overflow-scroll-y"
      show={false}
    >
      <.form for={@form} phx-change="form-changed" phx-submit="save">
        <div class="relative lg:h-[120px] bg-primary">
          <div class="w-full h-full overflow-hidden">
            <img
              :if={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "banner")["xl"]}
              class="w-full h-full object-cover overflow-hidden"
              src={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "banner")["xl"]}
            />
            <div class="w-full h-full">
              <label
                for={@uploads.banner.ref}
                class="p-1 rounded-full  bg-black absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 opacity-60 hover:opacity-80 cursor-pointer"
              >
                <Lucideicons.camera class="size-5 text-white" />
                <.live_file_input class="hidden" upload={@uploads.banner} />
              </label>
            </div>
          </div>
          <div class="mx-2 flex justify-between items-end -mt-10">
            <div class="relative size-20">
              <img
                :if={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "avatar")}
                class="inline-block size-20 rounded-full"
                src={Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "avatar")["128"]}
                alt=""
              />
              <span
                :if={!Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "avatar")}
                class="inline-flex size-20 items-center justify-center rounded-full bg-primary border-2 border-white"
              >
                <span class="font-medium text-white uppercase text-4xl">
                  {Moly.Utilities.Account.load_meta_value_by_meta_key(@user, "name")
                  |> String.slice(0, 1)}
                </span>
              </span>
              <label
                for={@uploads.avatar.ref}
                class="p-1 rounded-full  bg-black absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 opacity-60 hover:opacity-80 cursor-pointer"
              >
                <Lucideicons.camera class="size-5 text-white" />
                <.live_file_input class="hidden" upload={@uploads.avatar} />
              </label>
            </div>
          </div>
        </div>

        <div class="px-4 mt-16 space-y-6">
          <.user_meta_input
            :for={
              {{f, l}, i} <-
                Enum.with_index([
                  {"name", :Name},
                  {"username", :UserName},
                  {"location", :Location},
                  {"bio", :Bio},
                  {"website", :Website},
                  {"twitter", :Twitter},
                  {"facebook", :Facebook},
                  {"instagram", :Instagram}
                ])
            }
            :if={f !== :username || !is_modified_username?(@user)}
            field={
              %FormField{
                id: "#{@form[:user_meta].id}-#{i}-meta-value",
                name: "#{@form[:user_meta].name}[#{i}][meta_value]",
                value: Moly.Utilities.Account.load_meta_value_by_meta_key(@user, f),
                errors: [],
                field: :user_meta,
                form: @form
              }
            }
            label={l}
            meta_key={%{key: "#{@form[:user_meta].name}[#{i}][meta_key]", value: f}}
            id={"user-meta-#{i}-meta-value-input"}
          />
        </div>
        <div class="p-4 flex items-end justify-end">
          <button
            type="submit"
            class="rounded-md bg-green-600 px-2.5 py-1.5 text-sm font-semibold text-white shadow-xs hover:bg-green-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-green-600"
          >
            Save
          </button>
        </div>
      </.form>
    </MolyWeb.TailwindUI.modal>
    """
  end

  defp user_meta_input(assigns) do
    ~H"""
    <div id={@id} class="relative">
      <label
        for={@field.id}
        class="absolute -top-2 left-2 inline-block rounded-lg bg-white px-1 text-xs font-medium text-gray-500"
      >
        {@label}
      </label>
      <input
        id={@field.id}
        type="text"
        name={@field.name}
        value={@field.value}
        class="block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
      />
      <input type="hidden" name={@meta_key.key} value={@meta_key.value} />
    </div>
    """
  end

  defp is_modified_username?(user) do
    username = Moly.Utilities.Account.load_meta_value_by_meta_key(user, "username")
    name = Moly.Utilities.Account.load_meta_value_by_meta_key(user, "name")
    email = user.email |> to_string()

    if username == name and String.contains?(email, name) do
      false
    else
      true
    end
  end

  defp live_url(params) do
    ~p"/user/@#{params[:username]}?#{params}"
  end
end
