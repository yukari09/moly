defmodule MolyWeb.Affiliate.SubmitLive do
  use MolyWeb, :live_view

  require Ash.Query

  alias Phoenix.HTML.FormField

  def mount(params, _session, socket) do
    {:ok, resource_socket(socket, params)}
  end

  def handle_event("upload-media", _, socket) do
    socket =
      socket.assigns.uploads.media.errors
      |> Enum.reduce(socket, fn {ref, error}, socket ->
        case error do
          :not_accepted ->
            cancel_upload(socket, :media, ref)

          :too_large ->
            cancel_upload(socket, :media, ref)
            |> put_flash(:error, "The file size is too large.")

          :too_many_files ->
            socket
            |> put_flash(:error, "Up to 6 pictures can be uploaded.")
        end
      end)

    socket =
      push_event(socket, "validate-and-exec", %{form_name: "form"})
      |> push_event("TagsTagify", %{id: "#form_post_tags"})

    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    socket =
      cancel_upload(socket, :media, ref)
      |> push_event("validate-and-exec", %{form_name: "form"})
      |> push_event("TagsTagify", %{id: "#form_post_tags"})

    {:noreply, socket}
  end

  def handle_event("save", %{"form" => params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :media, fn %{path: path}, entry ->
        media_info = Moly.Helper.upload_entry_information(entry, path)

        case media_info do
          :error ->
            {:error, "Error uploading file \"#{entry.client_name}\""}

          %{mime_type: mime_type, file: file, filename: filename, filesize: filesize} = meta_data ->
            client_name_with_extension =
              Moly.Helper.extract_filename_without_extension(entry.client_name)

            metas =
              [
                %{meta_key: :attached_file, meta_value: filename},
                %{meta_key: :attachment_filesize, meta_value: "#{filesize}"},
                %{meta_key: :attachment_metadata, meta_value: JSON.encode!(meta_data)},
                %{meta_key: :attachment_image_alt, meta_value: client_name_with_extension},
                %{meta_key: :attachment_image_caption, meta_value: client_name_with_extension}
              ]

            attrs = %{
              post_title: client_name_with_extension,
              post_mime_type: mime_type,
              guid: file,
              post_content: "",
              metas: metas
            }

            current_user = set_current_user_as_owner(socket.assigns.current_user)

            Moly.Contents.create_media(attrs, actor: current_user)
        end
      end)

    meida_ids = Enum.map(uploaded_files, & &1.id) |> Enum.join(",")
    feture_id = List.first(uploaded_files) |> Map.get(:id)

    params =
      put_in(params, ["post_meta", "10"], %{
        "meta_key" => "attachment_affiliate_media",
        "meta_value" => meida_ids
      })

    params =
      put_in(params, ["post_meta", "11"], %{
        "meta_key" => "attachment_affiliate_media_feature",
        "meta_value" => feture_id
      })

    params = Map.put(params, "post_status", "pending")
    params = Map.put(params, "post_name", Moly.Helper.generate_random_str())

    post_excerpt =
      Floki.parse_document!(params["post_content"]) |> Floki.text() |> String.slice(0..255)

    params = Map.put(params, "post_excerpt", post_excerpt)

    post_tags =
      Map.get(params, "post_tags")
      |> case do
        nil ->
          %{}

        tags ->
          JSON.decode!(tags)
          |> Enum.with_index()
          |> Enum.reduce(%{}, fn {tag, i}, acc ->
            name = get_in(tag, ["value"]) |> String.trim()
            slug = Moly.Helper.string2slug(name)

            Map.put(acc, "#{i}", %{
              "name" => name,
              "slug" => slug,
              "term_taxonomy" => [%{"taxonomy" => "affiliate_tag"}]
            })
          end)
      end

    params = Map.put(params, "tags", post_tags)

    socket =
      case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
        {:ok, post} ->
          socket
          |> put_flash(:info, "Saved post for #{post.post_title}!")
          |> push_navigate(to: Moly.Utilities.Affiliate.link_view(post))

        {:error, form} ->
          socket
          |> assign(form: form)
          |> put_flash(:error, "Oops, some thing wrong.")
      end

    {:noreply, socket}
  end

  defp resource_socket(socket, params) do
    post_name = Map.get(params, "post_name")
    is_active_user = Moly.Utilities.Account.is_active_user(socket.assigns.current_user)

    post =
      if is_nil(post_name) do
        %Moly.Contents.Post{}
      else
        Ash.Query.filter(
          Moly.Contents.Post,
          post_name == ^post_name and author_id == ^socket.assigns.current_user.id
        )
        |> Ash.Query.load([:affiliate_categories, :post_tags, post_meta: :children])
        |> Ash.read_first!(actor: socket.assigns.current_user)
      end

    if is_active_user && post do
      form =
        if post_name do
          AshPhoenix.Form.for_update(post, :update_post,
            forms: [auto?: true],
            actor: set_current_user_as_owner(socket.assigns.current_user)
          )
        else
          AshPhoenix.Form.for_create(Moly.Contents.Post, :create_post,
            forms: [auto?: true],
            actor: set_current_user_as_owner(socket.assigns.current_user)
          )
        end
        |> to_form()

      countries = get_term_taxonomy("countries", socket.assigns.current_user)
      industries = get_term_taxonomy("industries", socket.assigns.current_user)

      assign(socket, countries: countries, industries: industries, form: form, post: post)
      |> allow_upload(:media,
        accept: ~w(.jpg .jpeg .png .gif),
        max_entries: 6,
        max_file_size: 4_000_000
      )
      |> assign(:is_active_user, is_active_user)
    else
      push_navigate(socket, to: ~p"/")
    end
  end

  # terms  slug
  defp get_term_taxonomy(slug, current_user) do
    Ash.Query.filter(Moly.Terms.TermTaxonomy, parent.slug == ^slug)
    |> Ash.Query.load([:term])
    |> Ash.read!(actor: current_user)
  end

  defp find_value(affiliate_categories, post_affiliate_categories)
       when is_list(post_affiliate_categories) do
    Enum.find(affiliate_categories, fn ac ->
      slugs = post_affiliate_categories |> Enum.map(& &1.slug)
      ac.term.slug in slugs
    end)
    |> case do
      nil -> nil
      t -> t.id
    end
  end

  defp find_value(_, _), do: nil

  def render(assigns) do
    ~H"""
    <div class="xl:w-[1280px] mx-auto lg:mt-24 lg:mb-24">
      <div class="pt-8">
        <div class="lg:px-6 lg:py-4  lg:text-4xl text-2xl px-4 border-b pb-4 lg:border-none font-medium lg:font-normal">Submit Competitive Products</div>
        <.form  :let={f} for={@form} class="px-4 lg:px-6 my-6 space-y-4" phx-submit="save" phx-change={JS.dispatch("app:validate-and-exec")}>
          <div class="rounded-lg lg:p-6 lg:border space-y-4">
            <h3 class="font-semibold  lg:text-xl">Detail</h3>
            <!--Start title-->
            <.input field={f[:post_title]}  input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "length", params: [8, 255]}}]])}>
              <:label>Product or Service Title <span class="text-red-500">*</span></:label>
              <:input_helper>Product or Service Title must be more than 8 words.</:input_helper>
            </.input>
            <!--End title-->
            <!--Start Link-->
            <.input  field={%FormField{
              field: :post_meta,
              id: "#{f[:post_meta].id}_5_meta_value",
              name: "#{f[:post_meta].name}[5][meta_value]",
              value: Moly.Utilities.MetaValue.format_meta_value(@post, :affiliate_link),
              errors: [],
              form: f
            }}  input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "isURL", params: []}}]])}>
              <:label>What is the link to your service(product)? <span class="text-red-500">*</span></:label>
              <:input_helper>The link of your service(product).</:input_helper>
              <:foot_other><input name={"#{f[:post_meta].name}[5][meta_key]"} type="hidden" value={:affiliate_link}/></:foot_other>
            </.input>
            <!--End Link-->
            <!--Start Tags-->
            <%!-- <div class="text-xs text-gray-500 hidden" id="tagify-input-target" phx-update="ignore">
              <input :for={{tag, i} <- Enum.with_index(f.data && @form.data.post_tags || [])} name={"#{f[:tags].name}[#{i}][name]"} value={tag.name} data-value={tag.name} />
              <input :for={{tag, i} <- Enum.with_index(f.data && @form.data.post_tags || [])} name={"#{f[:tags].name}[#{i}][term_taxonomy][][taxonomy]"} data-value={tag.name}  value={hd(tag.term_taxonomy) |> Map.get(:id)} />
            </div> --%>
            <.input field={%FormField{id: f[:post_tags].id, name: f[:post_tags].name, value: (f[:post_tags].value || []) |> Enum.map(& &1.name) |> Enum.join(","), errors: nil, form: f, field: :post_tags}} type="text" phx-mounted={JS.dispatch("phx:TagsTagify")}>
              <:label>Tags <span class="text-red-500">*</span></:label>
            </.input>
            <!--End Tags-->
            <!--Start Description-->
            <div>
              <div
                id="post-editor"
                phx-hook="DescriptionEditor"
                data-target={"##{f[:post_content].id}"}
                data-config={JSON.encode!(%{
                  theme: "snow",
                  placeholder: "Affiliate description(min 20 words)...",
                  modules: %{
                    toolbar: [
                      [%{ header: 2 }, %{ header: 4 }, %{ header: 5 }],
                      [%{ list: "ordered"}, %{list: "bullet"}],
                      ["bold", "italic", "underline"],[ %{ align: [] }]
                    ]
                  }
                })}
              >{raw @post.post_content}</div>
              <input class="hidden" phx-update="ignore" id={f[:post_content].id} name={f[:post_content].name} value={f[:post_content].value} data-input-dispatch={JSON.encode!([["app:input-validate", %{detail: %{validator: "length", params: [20, 3000]}}]])}/>
            </div>
            <%!-- <.input  field={f[:post_content]} type="textarea"  input_dispatch={JSON.encode!([["app:count_word"],["app:fill_text_with_attribute", %{detail: %{to_el: "#count_word_text", from_attr: "data-count-word"}}],["app:input-validate", %{detail: %{validator: "length", params: [20, 3000]}}]])}>
              <:label>Description <span class="text-red-500">*</span></:label>
              <div id="editor" phx-hook="MarkDownEditor"></div>
              <:foot_other class="text-gray-500"><span id="count_word_text" data-count-word="0">0</span>/3000</:foot_other>
            </.input> --%>
            <!--End Description-->
          </div>

          <div class="rounded-lg lg:p-6 lg:border space-y-4">
            <h3 class="font-semibold  lg:text-xl">Location and Category</h3>
            <!--Start Location-->
            <.input type="select"  field={%FormField{field: :countries, id: "categories_0_term_taxonomy", name: "#{f[:categories].name}[0]", value: find_value(@countries, @post.affiliate_categories), errors: [], form: f}}  input_dispatch = "" options={Map.new(@countries, &({&1.id, &1.term.name}))}>
              <:label>Select a country where your service(product) from?</:label>
            </.input>
            <!--End Location-->
            <!--Start Industry-->
            <.input type="select"  field={%FormField{field: :industries, id: "categories_1_term_taxonomy_id", name: "#{f[:categories].name}[1]", value: find_value(@industries, @post.affiliate_categories), errors: [], form: f}}  input_dispatch = "" options={Map.new(@industries, &({&1.id, &1.term.name}))}>
              <:label>What industry is your service(product) in?</:label>
            </.input>
            <!--End Industry-->
          </div>

          <div class="rounded-lg lg:p-6 lg:border space-y-4">
            <h3 class="font-semibold  lg:text-xl">Commission</h3>
            <div class="grid grid-cols-4">
              <div class="lg:col-span-3 col-span-4 divide-y space-y-4">
                <!--Start Minimum Commission-->
                <div class="flex justify-between">
                  <div>
                    <div class="font-medium text-gray-700">Minimum Commission</div>
                    <div class="text-gray-500 text-sm">Enter the minimum commission amount you are willing to accept, e.g., 10.</div>
                  </div>
                  <.input type="text" field={%FormField{field: :post_meta, id: "#{f[:post_meta].id}_1_meta_value", name: "#{f[:post_meta].name}[1][meta_value]", value: Moly.Utilities.MetaValue.format_meta_value(@post, :commission_min), errors: [], form: f}} input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "isNumber", params: []}}]])} >
                  </.input>
                  <input type="text" name={"#{f[:post_meta].name}[1][meta_key]"} value={:commission_min} class="hidden"/>
                </div>
                <!--End Minimum Commission-->
                <!--Start Maximum Commission-->
                <div class="flex justify-between pt-2">
                  <div>
                    <div class="font-medium text-gray-700">Maximum Commission</div>
                    <div class="text-gray-500 text-sm">Enter the maximum commission amount you are willing to accept, e.g., 20.</div>
                  </div>
                  <.input type="text" field={%FormField{field: :post_meta, id: "#{f[:post_meta].id}_2_meta_value", name: "#{f[:post_meta].name}[2][meta_value]", value: Moly.Utilities.MetaValue.format_meta_value(@post, :commission_max), errors: [], form: f}} input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "isNumber", params: []}}]])} >
                  </.input>
                  <input type="text" name={"#{f[:post_meta].name}[2][meta_key]"} value={:commission_max} class="hidden"/>
                </div>
                <!--End Maximum Commission-->
                <!--Start Commission Unit-->
                <div class="flex justify-between pt-2">
                  <div>
                    <div class="font-medium text-gray-700">Commission Unit</div>
                    <div class="text-gray-500 text-sm">Commission Unit</div>
                  </div>
                  <.input type="text" type="select" field={%FormField{field: :post_meta, id: "#{f[:post_meta].id}_3_meta_value", name: "#{f[:post_meta].name}[3][meta_value]", value: Moly.Utilities.MetaValue.format_meta_value(@post, :commission_unit), errors: [], form: f}} options={get_unit()} option_selectd="" input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "inList", params: [Enum.map(get_unit(), &(elem(&1,0)))]}}]])} >
                  </.input>
                  <input type="text" name={"#{f[:post_meta].name}[3][meta_key]"} value={:commission_unit} class="hidden"/>
                </div>
                <!--End Commission Unit-->
                <!--Start Commission Model-->
                <div class="flex justify-between pt-2">
                  <div>
                    <div class="font-medium text-gray-700">Commission Model</div>
                    <div class="text-gray-500 text-sm">Commission Unit</div>
                  </div>
                  <.input type="text" type="select" field={%FormField{field: :post_meta, id: "#{f[:post_meta].id}_4_meta_value", name: "#{f[:post_meta].name}[4][meta_value]", value: Moly.Utilities.MetaValue.format_meta_value(@post, :commission_model), errors: [], form: f}} options={Map.new(commission_model(), &({&1, &1}))} option_selectd="" input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "inList", params: [commission_model()]}}]])} >
                  </.input>
                  <input type="text" name={"#{f[:post_meta].name}[4][meta_key]"} value={:commission_model} class="hidden"/>
                </div>
                <!--End Commission Model-->
                <!--Start Cookie Duration-->
                <div class="flex justify-between pt-2">
                  <div>
                    <div class="font-medium text-gray-700">Cookie Duration</div>
                    <div class="text-gray-500 text-sm">Cookie Duration (Days)</div>
                  </div>
                  <.input type="text" field={%FormField{field: :post_meta, id: "#{f[:post_meta].id}_6_meta_value", name: "#{f[:post_meta].name}[6][meta_value]", value: Moly.Utilities.MetaValue.format_meta_value(@post, :cookie_duration), errors: [], form: f}} input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "isNumber", params: []}}]])} />
                  <input type="text" name={"#{f[:post_meta].name}[6][meta_key]"} value={:cookie_duration} class="hidden"/>
                </div>
                <!--End Cookie Duration-->
              </div>
            </div>
          </div>

          <div class="rounded-lg lg:p-6 lg:border space-y-4">
            <.form_media uploads={@uploads} post={@post} />
          </div>

          <div class="flex py-4 px-2 !mt-6">
            <input name={f[:post_type].name} type="hidden" value={:affiliate}/>
            <input name={f[:post_date].name} type="hidden" value={DateTime.utc_now()}/>
            <button id={@form[:submit].id} type="submit" phx-disable-with="Saving..." class="rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-green-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-green-600 w-32"  disabled>Submit</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp form_media(assigns) do
    ~H"""
    <!--Start media-->
    <div>
      <div class="font-medium text-sm mb-2">Upload media <span class="text-red-500 font-normal">*</span></div>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2 border border-dashed border-gray-900/25 p-2 rounded-md">
        <label :if={Enum.count(@uploads.media.entries) < 6} for={@uploads.media.ref} phx-drop-target={@uploads.media.ref} class="flex flex-col cursor-pointer justify-center bg-gray-50 aspect-video rounded-md hover:opacity-80">
          <div class="text-center w-full">
            <.icon name="hero-photo" class="mx-auto size-10 text-gray-300" />
            <div class="mt-4 flex justify-center text-sm/6 text-gray-600">
              <div class="relative cursor-pointer rounded-md  font-semibold text-green-600 focus-within:outline-none focus-within:ring-green-600 focus-within:ring-offset-2 hover:text-green-500">
                <span>Upload a file</span>
              </div>
              <p class="pl-1">or drag and drop</p>
            </div>
            <p class="text-xs/5 text-gray-600">PNG, JPG, GIF up to 4MB</p>
          </div>
        </label>
        <div :for={entry <- @uploads.media.entries} class="bg-gray-50">
          <div class="relative">
            <.live_img_preview class="w-full object-cover aspect-video rounded-md" entry={entry} />
            <div class="absolute right-0 top-0 mr-2 mt-2">
              <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="bg-white rounded-full text-gray-500 p-1"><Lucideicons.x class="size-4" /></button>
            </div>
          </div>
        </div>
      </div>
      <.live_file_input class="hidden" phx-change="upload-media" upload={@uploads.media} data-input-dispatch="[]"  data-form-name="form" data-validate={Enum.count(@uploads.media.entries) > 0 && Enum.count(@uploads.media.entries) < 7 && "1" || "0"}/>
    </div>
    <!--End media-->
    """
  end

  defp get_unit(),
    do: [
      {"%", "%"},
      {"USD", "$ (USD - US Dollar)"},
      {"EUR", "€ (EUR - Euro)"},
      {"GBP", "£ (GBP - British Pound)"},
      {"JPY", "¥ (JPY - Japanese Yen)"},
      {"CNY", "¥ (CNY - Chinese Yuan)"},
      {"CHF", "CHF (CHF - Swiss Franc)"},
      {"CAD", "$ (CAD - Canadian Dollar)"},
      {"AUD", "$ (AUD - Australian Dollar)"},
      {"INR", "₹ (INR - Indian Rupee)"},
      {"KRW", "₩ (KRW - South Korean Won)"},
      {"RUB", "₽ (RUB - Russian Ruble)"},
      {"TWD", "NT$ (TWD - New Taiwan Dollar)"},
      {"MXN", "$ (MXN - Mexican Peso)"},
      {"SGD", "$ (SGD - Singapore Dollar)"},
      {"BRL", "R$ (BRL - Brazilian Real)"},
      {"MYR", "RM (MYR - Malaysian Ringgit)"},
      {"THB", "฿ (THB - Thai Baht)"},
      {"ZAR", "R (ZAR - South African Rand)"}
    ]

  defp commission_model(), do: ["CPC", "CPS", "CPL", "CPI","CPA", "Recurring"]

  defp set_current_user_as_owner(current_user),
    do: %{current_user | roles: [:owner | current_user.roles]}

  attr(:type, :string, required: false, default: "text")
  attr(:field, FormField, required: true)
  slot(:label, required: false)
  slot(:input_helper, required: false)
  slot(:foot_other, required: false)
  attr(:input_dispatch, :string, required: false, default: nil)
  attr(:options, :list, required: false)
  attr(:rest, :global)

  defp input(%{type: "text"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="block text-sm/6 font-medium text-gray-900">{render_slot(@label)}</label>
      <div class="mt-2 grid grid-cols-1">
        <input
          type="text"
          id={@field.id}
          name={@field.name}
          value={@field.value}
          autocomplete="off"
          class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 text-base outline outline-1 -outline-offset-1 focus:outline focus:outline-2 focus:-outline-offset-2 sm:text-sm/6 px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
          data-error-class="pl-3 pr-10 text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600 sm:pr-9"
          data-normal-class="px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
          phx-update="ignore"
          data-input-dispatch={@input_dispatch}
          {@rest}
        >
        <.icon name="hero-exclamation-circle-solid" class={["#{@field.id}-icon", "pointer-events-none col-start-1 row-start-1 mr-3 size-5 self-center justify-self-end text-red-500 sm:size-4 hidden"]}/>
      </div>
      <div class="mt-1 text-sm/6 flex justify-between">
        <p :if={@input_helper} class="text-sm text-gray-500" id={"#{@field.id}-helper"}>{render_slot(@input_helper)}</p>
        <p class="text-sm text-red-500" id={"#{@field.id}-error"}></p>
        <p :if={@foot_other}>{render_slot(@foot_other)}</p>
      </div>
    </div>
    """
  end

  defp input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="block text-sm/6 font-medium text-gray-900">{render_slot(@label)}</label>
      <div class="mt-2">
        <textarea
          id={@field.id}
          name={@field.name}
          placeholder="Description(text or markdown)"
          rows="5"
          phx-debounce="50"
          phx-update="ignore"
          data-input-dispatch={@input_dispatch}
          class="block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
          {@rest}
        >{@field.value}</textarea>
      </div>
      <div class="mt-1 text-sm/6 flex justify-between">
        <p :if={@input_helper} class="text-sm text-gray-500" id={"#{@field.id}-helper"}>{render_slot(@input_helper)}</p>
        <p class="text-sm text-red-500" id={"#{@field.id}-error"}></p>
        <p :if={@foot_other}>{render_slot(@foot_other)}</p>
      </div>
    </div>
    """
  end

  defp input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="block text-sm/6 font-medium text-gray-900">{render_slot(@label)}</label>
      <div class="mt-2 grid grid-cols-1">
        <select
          id={@field.id}
          name={@field.name}
          phx-update="ignore"
          class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-1.5 pl-3 pr-8 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
          {@rest}
        >
          <option :for={{value, key} <- @options} value={value} selected={value == @field.value}>{key}</option>
        </select>
        <.icon name="hero-chevron-down" class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end text-gray-500 sm:size-4"/>
      </div>
      <div class="mt-1 text-sm/6 flex justify-between">
        <p :if={@input_helper} class="text-sm text-gray-500" id={"#{@field.id}-helper"}>{render_slot(@input_helper)}</p>
        <p class="text-sm text-red-500" id={"#{@field.id}-error"}></p>
        <p :if={@foot_other}>{render_slot(@foot_other)}</p>
      </div>
    </div>
    """
  end
end
