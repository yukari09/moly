defmodule MonorepoWeb.Affiliate.ProductSubmitLive do
  use MonorepoWeb, :live_view

  require Ash.Query

  import MonorepoWeb.UI

  alias Phoenix.HTML.FormField

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    is_active_user = Monorepo.Accounts.Helper.is_active_user(current_user)

    if is_active_user do
      form = resource_form(current_user)

      socket =
        assign(socket, form: form)
        |> allow_upload(:media, accept: ~w(.jpg .jpeg .png .gif), max_entries: 6)
        |> assign(:is_active_user, is_active_user)

      categories = get_term_taxonomy("countries", current_user)
      industries = get_term_taxonomy("industries", current_user)

      {:ok, socket, temporary_assigns: [categories: categories, industries: industries]}
    else
      socket =
        push_navigate(socket, to: ~p"/")

      {:ok, socket}
    end
  end

  def handle_event("upload-media", _, socket) do
    socket =
      socket.assigns.uploads.media.errors
      |> Enum.reduce(socket, fn {ref, error}, socket ->
        case error do
          :not_accepted ->
            cancel_upload(socket, :media, ref)

          :too_many_files ->
            socket
            |> put_flash(:error, "Up to 6 pictures can be uploaded.")
        end
      end)

    socket = push_event(socket, "validate-and-exec", %{form_name: "form"})
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    socket =
      cancel_upload(socket, :media, ref)
      |> push_event("validate-and-exec", %{form_name: "form"})

    {:noreply, socket}
  end

  def handle_event("save", %{"form" => params}, socket) do
    # IO.inspect(socket.assigns.form)
    uploaded_files =
      consume_uploaded_entries(socket, :media, fn %{path: path}, entry ->
        media_info = Monorepo.Helper.upload_entry_information(entry, path)

        case media_info do
          :error ->
            {:error, "Error uploading file \"#{entry.client_name}\""}

          %{mime_type: mime_type, file: file, filename: filename, filesize: filesize} = meta_data ->
            client_name_with_extension =
              Monorepo.Helper.extract_filename_without_extension(entry.client_name)

            metas =
              [
                %{meta_key: :attached_file, meta_value: filename},
                %{meta_key: :attachment_filesize, meta_value: "#{filesize}"},
                %{meta_key: :attachment_metadata, meta_value: Jason.encode!(meta_data)},
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

            Monorepo.Contents.create_media(attrs, actor: current_user)
        end
      end)

    params =
      Enum.with_index(uploaded_files)
      |> Enum.reduce(params, fn {media, i}, params ->
        insert_index = Enum.count(params["post_meta"]) + 1
        post_meta = %{"meta_key" => :attachment_affiliate_media, "meta_value" => media.id}
        params = put_in(params, ["post_meta", "#{insert_index}"], post_meta)

        if i == 0 do
          put_in(
            params,
            ["post_meta", "#{insert_index + 1}"],
            Map.put(post_meta, "meta_key", :attachment_affiliate_media_feature)
          )
        else
          params
        end
      end)

    socket =
      case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
        {:ok, post} ->
          socket
          |> put_flash(:info, "Saved post for #{post.post_title}!")
          |> push_navigate(to: ~p"/product/#{post.id}")

        {:error, form} ->
          socket
          |> assign(form: form)
          |> put_flash(:error, "Oops, some thing wrong.")
      end

    {:noreply, socket}
  end

  defp resource_form(id \\ nil, current_user) do
    current_user = set_current_user_as_owner(current_user)

    data =
      if is_nil(id) do
        AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post,
          forms: [
            auto?: true
          ],
          actor: current_user
        )
      else
        post =
          Ash.Query.filter(
            Monorepo.Contents.Post,
            id == ^id and auth(author_id == current_user.id)
          )
          |> Ash.read_first!(actor: current_user)

        AshPhoenix.Form.for_update(post, :update_post,
          forms: [
            auto?: true
          ],
          data: post,
          actor: current_user
        )
      end

    to_form(data)
  end

  # terms  slug
  defp get_term_taxonomy(slug, current_user) do
    Ash.Query.filter(Monorepo.Terms.TermTaxonomy, parent.slug == ^slug)
    |> Ash.Query.load([:term])
    |> Ash.read!(actor: current_user)
  end

  def render(assigns) do
    ~H"""
    <div class="xl:w-[1280px] mx-auto my-40">
      <div>
        <div class="px-6 py-4  text-4xl">Submit Competitive Products</div>
        <.form  :let={f} for={@form} class="space-y-2 px-6 my-6 space-y-4" phx-submit="save" phx-change={JS.dispatch("app:validate-and-exec")}>
          <div class="rounded-lg p-6 border space-y-4">
            <h3 class="font-semibold text-xl">Detail</h3>
            <!--Start title-->
            <.input field={f[:post_title]}  input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "length", params: [10, 255]}}]])}>
              <:label>Product or Service Title <span class="text-red-500">*</span></:label>
              <:input_helper>Product or Service Title must be more than 10 words.</:input_helper>
            </.input>
            <!--End title-->
            <!--Start Link-->
            <.input  field={%FormField{field: :post_meta, id: "#{f[:post_meta].id}_5_meta_value", name: "#{f[:post_meta].name}[5][meta_value]", value: "", errors: [], form: f}}  input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "isURL", params: []}}]])}>
              <:label>What is the link to your service(product)? <span class="text-red-500">*</span></:label>
              <:input_helper>The link of your service(product).</:input_helper>
              <:foot_other><input name={"#{f[:post_meta].name}[5][meta_key]"} type="hidden" value={:affiliate_link}/></:foot_other>
            </.input>
            <!--End Link-->
            <!--Start Tags-->
            <div class="text-xs text-gray-500 h-0" id="tagify-input-target" phx-update="ignore">
              <input :for={{tag, i} <- Enum.with_index(f.data && @form.data.post_tags || [])} name={"#{f[:tags].name}[#{i}][name]"} value={tag.name} data-value={tag.name}  type="hidden"/>
              <input :for={{tag, i} <- Enum.with_index(f.data && @form.data.post_tags || [])} name={"#{f[:tags].name}[#{i}][term_taxonomy][][taxonomy]"} data-value={tag.name}  value={hd(tag.term_taxonomy) |> Map.get(:id)} type="hidden"/>
            </div>
            <.input  field={f[:post_tags]} type="text" phx-hook="TagsTagify" data-target-container="#tagify-input-target" data-target-name={"#{f[:term_taxonomy_tags].name}"}>
              <:label>Tags <span class="text-red-500">*</span></:label>
            </.input>
            <!--End Tags-->
            <!--Start Description-->
            <.input  field={f[:post_content]} type="textarea"  input_dispatch={JSON.encode!([["app:count_word"],["app:fill_text_with_attribute", %{detail: %{to_el: "#count_word_text", from_attr: "data-count-word"}}],["app:input-validate", %{detail: %{validator: "length", params: [20, 3000]}}]])}>
              <:label>Description <span class="text-red-500">*</span></:label>
              <:foot_other class="text-gray-500"><span id="count_word_text" data-count-word="0">0</span>/3000</:foot_other>
            </.input>
            <!--End Description-->
          </div>

          <div class="rounded-lg p-6 border space-y-4">
            <h3 class="font-semibold text-xl">Location and Category</h3>
            <!--Start Location-->
            <.input type="select"  field={%FormField{field: :categories, id: "categories_0_term_taxonomy", name: "#{f[:categories].name}[]", value: "", errors: [], form: f}}  input_dispatch = "" options={Map.new(@categories, &({&1.id, &1.term.name}))} option_selectd="">
              <:label>Select a country where your service(product) from?</:label>
            </.input>
            <!--End Location-->
            <!--Start Industry-->
            <.input type="select"  field={%FormField{field: :categories, id: "categories_1_term_taxonomy_id", name: "#{f[:categories].name}[]", value: "", errors: [], form: f}}  input_dispatch = "" options={Map.new(@industries, &({&1.id, &1.term.name}))} option_selectd="">
              <:label>What industry is your service(product) in?</:label>
            </.input>
            <!--End Industry-->
          </div>

          <div class="rounded-lg p-6 border space-y-4">
            <h3 class="font-semibold text-xl">Commission</h3>
            <div class="grid grid-cols-4">
              <div class="col-span-3 divide-y space-y-4">
                <!--Start Minimum Commission-->
                <div class="flex justify-between">
                  <div>
                    <div class="font-medium text-gray-700">Minimum Commission</div>
                    <div class="text-gray-500 text-sm">Enter the minimum commission amount you are willing to accept, e.g., 10.</div>
                  </div>
                  <.input type="text" field={%FormField{field: :post_meta, id: "#{f[:post_meta].id}_1_meta_value", name: "#{f[:post_meta].name}[1][meta_value]", value: "", errors: [], form: f}} input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "isNumber", params: []}}]])} >
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
                  <.input type="text" field={%FormField{field: :post_meta, id: "#{f[:post_meta].id}_2_meta_value", name: "#{f[:post_meta].name}[2][meta_value]", value: "", errors: [], form: f}} input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "isNumber", params: []}}]])} >
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
                  <.input type="text" type="select" field={%FormField{field: :post_meta, id: "#{f[:post_meta].id}_3_meta_value", name: "#{f[:post_meta].name}[3][meta_value]", value: "", errors: [], form: f}} options={get_unit()} option_selectd="" input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "inList", params: [Enum.map(get_unit(), &(elem(&1,0)))]}}]])} >
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
                  <.input type="text" type="select" field={%FormField{field: :post_meta, id: "#{f[:post_meta].id}_4_meta_value", name: "#{f[:post_meta].name}[4][meta_value]", value: "", errors: [], form: f}} options={Map.new(commission_model(), &({&1, &1}))} option_selectd="" input_dispatch = {JSON.encode!([["app:input-validate", %{detail: %{validator: "inList", params: [commission_model()]}}]])} >
                  </.input>
                  <input type="text" name={"#{f[:post_meta].name}[4][meta_key]"} value={:commission_model} class="hidden"/>
                </div>
                <!--End Commission Model-->
              </div>
            </div>
          </div>

          <div class="rounded-lg p-6 border space-y-4">
            <.form_media uploads={@uploads} />
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
      <div class="grid grid-cols-3 gap-2 border border-dashed border-gray-900/25 p-2 rounded-md">
        <label :if={Enum.count(@uploads.media.entries) < 6} for={@uploads.media.ref} phx-drop-target={@uploads.media.ref} class="flex flex-col cursor-pointer justify-center bg-gray-50 aspect-video rounded-md hover:opacity-80">
          <div class="text-center w-full">
            <.icon name="hero-photo" class="mx-auto size-10 text-gray-300" />
            <div class="mt-4 flex justify-center text-sm/6 text-gray-600">
              <div class="relative cursor-pointer rounded-md  font-semibold text-green-600 focus-within:outline-none focus-within:ring-green-600 focus-within:ring-offset-2 hover:text-green-500">
                <span>Upload a file</span>
              </div>
              <p class="pl-1">or drag and drop</p>
            </div>
            <p class="text-xs/5 text-gray-600">PNG, JPG, GIF up to 8MB</p>
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
      <%!-- <input id="upload-file-meida-id" type="file" class="hidden"/> --%>
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

  defp commission_model(), do: ["CPC", "CPS", "CPL", "CPI", "Recurring"]
  defp set_current_user_as_owner(current_user), do: %{current_user | roles: [:owner | current_user.roles]}

end
