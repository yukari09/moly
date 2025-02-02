defmodule MonorepoWeb.Affiliate.ProductSubmitLive do
  use MonorepoWeb, :live_view

  require Ash.Query


  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    form = resource_form(current_user)
    socket =
      assign(socket, form: form)
      |> allow_upload(:media, accept: ~w(.jpg .jpeg .png .gif), max_entries: 6)

    categories = get_term_taxonomy("countries", current_user)
    industries = get_term_taxonomy("industries", current_user)

    {:ok, socket, temporary_assigns: [categories: categories, industries: industries]}
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
      |>  push_event("validate-and-exec", %{form_name: "form"})
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
            client_name_with_extension = Monorepo.Helper.extract_filename_without_extension(entry.client_name)
            metas =
              [
                %{meta_key: :attached_file, meta_value: filename},
                %{meta_key: :attachment_filesize, meta_value: "#{filesize}"},
                %{meta_key: :attachment_metadata, meta_value: Jason.encode!(meta_data)},
                %{meta_key: :attachment_image_alt, meta_value: client_name_with_extension},
                %{meta_key: :attachment_image_caption, meta_value: client_name_with_extension},
              ]

            attrs = %{
              post_title: client_name_with_extension,
              post_mime_type: mime_type,
              guid: file,
              post_content: "",
              metas: metas
            }
            Monorepo.Contents.create_media(attrs, actor: socket.assigns.current_user)
        end
      end)


    params =
      Enum.with_index(uploaded_files)
      |> Enum.reduce(params, fn {media, i}, params ->
        insert_index = Enum.count(params["post_meta"]) + 1
        post_meta = %{"meta_key" => :attachment_affiliate_media, "meta_value" => media.id}
        params = put_in(params, ["post_meta", "#{insert_index}"], post_meta)
        if i == 0 do
          put_in(params, ["post_meta", "#{insert_index + 1}"], Map.put(post_meta, "meta_key", :attachment_affiliate_media_feature))
        else
          params
        end
      end)


    socket =
      case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
        {:ok, post} ->
          socket
          |> put_flash(:info, "Saved post for #{post.post_title}!")
          |> push_navigate(to: ~p"/admin/posts")
        {:error, form} ->
          IO.inspect(form)
          socket
          |> assign(form: form)
          |> put_flash(:error, "Oops, some thing wrong.")
      end

    {:noreply, socket}
  end

  defp resource_form(id \\ nil, current_user) do
    current_user =
      %{
        current_user |
        roles: [:owner | current_user.roles]
      }

    data =
      if is_nil(id) do
        AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post, [
          forms: [
            auto?: true
          ],
          actor: current_user
        ])
      else
        post =
          Ash.Query.filter(Monorepo.Contents.Post, id == ^id and auth author_id == current_user.id)
          |> Ash.read_first!(actor: current_user)

        AshPhoenix.Form.for_update(post, :update_post, [
          forms: [
            auto?: true
          ],
          data: post,
          actor: current_user
        ])
      end
    to_form(data)
  end

  #terms  slug
  defp get_term_taxonomy(slug, current_user) do
    Ash.Query.filter(Monorepo.Terms.TermTaxonomy, parent.slug == ^slug)
    |> Ash.Query.load([:term])
    |> Ash.read!(actor: current_user)
  end

  def render(assigns) do
  ~H"""
  <div class="xl:w-[1280px] mx-auto">
    <div class="mt-8 mb-12">
      <div class="px-6 py-4  text-4xl">Create Competitive Products</div>
      <.form :let={f} for={@form} class="space-y-2 px-6 my-6" phx-submit="save" phx-change={JS.dispatch("app:validate-and-exec")}>
        <!--Start title-->
        <label class="form-control w-full">
          <div class="label">
            <span class="label-text font-medium">Product or Service Title <span class="text-red-500">*</span></span>
          </div>
          <input
            type="text"
            id={f[:post_title].id}
            name={f[:post_title].name}
            value={f[:post_title].value}
            autocomplete="off"
            class="input input-bordered w-full"
            phx-update="ignore"
            data-input-dispatch={JSON.encode!([
              ["app:input-validate", %{detail: %{validator: "length", params: [10, 255]}}]
            ])}
          />
          <div class="label">
            <span id={"#{f[:post_title].id}-helper"} class="label-text-alt text-gray-500">Product or Service Title must be more than 10 words long.</span>
            <span id={"#{f[:post_title].id}-error"}  class="label-text-alt text-red-500 hidden"></span>
          </div>
        </label>
        <!--End title-->
        <!--Start Commission-->
        <div class="flex items-center gap-2">
          <label class="form-control">
            <div class="label">
              <span class="label-text font-medium">Commission <span class="text-red-500">*</span></span>
            </div>
            <div class="flex gap-1 items-center">
              <input
                type="text"
                id={"#{f[:post_meta].id}_1_meta_value"}
                name={"#{f[:post_meta].name}[1][meta_value]"}
                class="input input-bordered w-full" placeholder="min"
                inputmode="numeric"
                pattern="[0-9]*"
                phx-update="ignore"
                data-input-dispatch={JSON.encode!([
                  ["app:input-validate", %{detail: %{validator: "isNumber", params: []}}]
                ])}

              />
              <input type="text" name={"#{f[:post_meta].name}[1][meta_key]"} value={:commission_min} class="hidden"/>
            </div>
            <div class="label">
              <span id={"#{f[:post_meta].id}_1_meta_value-helper"} class="label-text-alt text-gray-500">Min of commission</span>
              <span id={"#{f[:post_meta].id}_1_meta_value-error"} class="label-text-alt text-red-500 hidden"></span>
            </div>
          </label>

          <label class="form-control">
            <div class="label">
              <span class="label-text font-medium">&nbsp;</span>
            </div>
            <div class="flex gap-1 items-center">
              <input
                id={"#{f[:post_meta].id}_2_meta_value"}
                type="text" name={"#{f[:post_meta].name}[2][meta_value]"}
                class="input input-bordered w-full" placeholder="max"
                phx-update="ignore"
                inputmode="numeric"
                pattern="[0-9]*"
                data-input-dispatch={JSON.encode!([
                  ["app:input-validate", %{detail: %{validator: "isNumber", params: []}}]
                ])}

              />
              <input type="text" name={"#{f[:post_meta].name}[2][meta_key]"} value={:commission_max} class="hidden"/>
            </div>

            <div class="label">
              <span id={"#{f[:post_meta].id}_2_meta_value-helper"} class="label-text-alt text-gray-500">Max of commission</span>
              <span id={"#{f[:post_meta].id}_2_meta_value-error"} class="label-text-alt text-red-500 hidden"></span>
            </div>
          </label>


          <label class="form-control">
            <div class="label">
              <span class="label-text font-medium">&nbsp;</span>
            </div>
            <select
              id={"#{f[:post_meta].id}_3_meta_value"}
              class="select select-bordered"
              name={"#{f[:post_meta].name}[3][meta_value]"}
              phx-update="ignore"
              data-input-dispatch={JSON.encode!([
                  ["app:input-validate", %{detail: %{validator: "inList", params: [Enum.map(get_unit(), &(elem(&1,0)))]}}]
              ])}

            >
              <option value="">Select Unit...</option>
              <option :for={{value, key} <- get_unit()} value={value}>{key}</option>
            </select>
            <input type="text" name={"#{f[:post_meta].name}[3][meta_key]"} value={:commission_unit} class="hidden"/>
            <div class="label">
              <span id={"#{f[:post_meta].id}_3_meta_value-helper"} class="label-text-alt text-gray-500">Unit of commission</span>
              <span id={"#{f[:post_meta].id}_3_meta_value-error"} class="label-text-alt text-red-500 hidden"></span>
            </div>
          </label>

          <label class="form-control">
            <div class="label">
              <span class="label-text font-medium">&nbsp;</span>
            </div>
            <select
              id={"#{f[:post_meta].id}_4_meta_value"}
              class="select select-bordered"
              name={"#{f[:post_meta].name}[4][meta_value]"}
              phx-update="ignore"
              data-input-dispatch={JSON.encode!([
                  ["app:input-validate", %{detail: %{validator: "inList", params: [commission_model()]}}]
              ])}

            >
              <option value="">Select Model...</option>
              <option :for={cm <- commission_model()} value={cm}>{cm}</option>
            </select>
            <input type="text" name={"#{f[:post_meta].name}[4][meta_key]"} value={:commission_model} class="hidden"/>
            <div class="label">
              <span id={"#{f[:post_meta].id}_4_meta_value-helper"} class="label-text-alt text-gray-500">Model of commission</span>
              <span id={"#{f[:post_meta].id}_4_meta_value-error"} class="label-text-alt text-red-500 hidden"></span>
            </div>
          </label>
        </div>
        <!--End Commission-->
        <!--Start Description-->
        <label class="form-control w-full">
            <div class="label">
              <span class="label-text font-medium">Description <span class="text-red-500">*</span></span>
            </div>
            <textarea
              id={f[:post_content].id}
              type="text"
              name={f[:post_content].name}
              placeholder="Description(text or markdown)"
              rows="5"
              class="textarea textarea-bordered resize-none w-full"
              phx-debounce="50"
              phx-update="ignore"
              data-input-dispatch={JSON.encode!([
                ["app:count_word"],
                ["app:fill_text_with_attribute", %{detail: %{to_el: "#count_word_text", from_attr: "data-count-word"}}],
                ["app:input-validate", %{detail: %{validator: "length", params: [20, 3000]}}]
              ])}

            >{f[:title].value}</textarea>
            <div class="label">
              <span class="label-text-alt text-red-500 hidden" id={"#{f[:post_content].id}-error"}></span>
              <span class="label-text-alt text-gray-500" id={"#{f[:post_content].id}-helper"}></span>
              <span class="label-text-alt text-gray-500"><span id="count_word_text" data-count-word="0">0</span>/3000</span>
            </div>
          </label>
        <!--End Description-->
        <!--Start Country-->
        <label class="form-control w-full">
          <div class="label">
            <span class="label-text font-medium">Select a country where your service(product) from? <span class="text-red-500">*</span></span>
          </div>
          <select
            id={"categories_0_term_taxonomy"}
            phx-update="ignore"
            class="select select-bordered"
            name={"#{f[:categories].name}[]"}
          >
            <option :for={category <- @categories} value={category.id}>{category.term.name}</option>
          </select>
          <div class="label">
            <span id={"categories_0_term_taxonomy-helper"} class="label-text-alt text-gray-500"></span>
            <span id={"categories_0_term_taxonomy-error"}  class="label-text-alt text-red-500 hidden"></span>
          </div>
        </label>
        <!--End Country-->
        <!--Start industry-->
        <label class="form-control w-full">
            <div class="label">
              <span class="label-text font-medium">What industry is your service(product) in? <span class="text-red-500">*</span></span>
            </div>
            <select id={"categories_1_term_taxonomy_id"} class="select select-bordered" phx-update="ignore" name={"#{f[:categories].name}[]"}>
              <option :for={industry <- @industries}  value={industry.id}>{industry.term.name}</option>
            </select>
            <div class="label">
              <span id={"categories_1_term_taxonomy_id-error"}  class="label-text-alt text-red-500 hidden"></span>
            </div>
          </label>
        <!--End industry-->
        <!--Start Link-->
        <label>
          <div class="label"><span class="label-text font-medium">What is the link to your service(product)? <span class="text-red-500">*</span></span></div>
            <input
            type="text"
            id={"#{f[:post_meta].id}_5_meta_value"}
            name={"#{f[:post_meta].name}[5][meta_value]"}
            autocomplete="off"
            class="input input-bordered w-full"
            phx-update="ignore"
            data-input-dispatch={JSON.encode!([
              ["app:input-validate", %{detail: %{validator: "isURL", params: []}}]
            ])}

          />
          <input name={"#{f[:post_meta].name}[5][meta_key]"} type="hidden" value={:affiliate_link}/>
          <div class="label">
            <span id={"#{f[:post_meta].id}_5_meta_value-helper"} class="label-text-alt text-gray-500">The link of your service(product).</span>
            <span id={"#{f[:post_meta].id}_5_meta_value-error"}  class="label-text-alt text-red-500 hidden"></span>
          </div>
        </label>
        <!--End Link-->
        <!--Start media-->
        <div>
          <div class="font-medium text-sm mb-2">Upload media <span class="text-red-500 font-normal">*</span></div>
          <div class="grid grid-cols-3 gap-2 border border-dashed border-gray-900/25 p-2 rounded-md">
            <label :if={Enum.count(@uploads.media.entries) < 6} for={@uploads.media.ref} phx-drop-target={@uploads.media.ref} class="flex flex-col cursor-pointer justify-center bg-base-200 aspect-video rounded-md hover:opacity-80">
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
            <div :for={entry <- @uploads.media.entries} class="bg-base-200">
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
        <div class="flex justify-end p-4 border-t !mt-6">
          <button id={@form[:submit].id} type="submit" phx-disable-with="Saving..." class="btn btn-primary w-32  btn-diabled"  disabled>Submit</button>
      </div>
      <input name={f[:post_type].name} type="hidden" value={:affiliate}/>
      <input name={f[:post_date].name} type="hidden" value={DateTime.utc_now()}/>
      </.form>
    </div>
  </div>
  """
  end

  defp get_unit(), do: [
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

  def commission_model(), do: ["CPC", "CPS", "CPL", "CPI", "Recurring"]
end
