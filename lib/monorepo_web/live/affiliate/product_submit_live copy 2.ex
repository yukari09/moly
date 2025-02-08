defmodule MonorepoWeb.Affiliate.ProductSubmitLive3 do
  use MonorepoWeb, :live_view

  require Ash.Query

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
        current_user
        | roles: [:owner | current_user.roles]
      }

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
    <div class="xl:w-[1280px] mx-auto">
      <div class="mt-8 mb-12">
        <div class="px-6 py-4  text-4xl">Create Competitive Products</div>
        <.form id="service-form" :let={f} for={@form} class="space-y-2 px-6 my-6 space-y-8" phx-submit="save" phx-change={JS.dispatch("app:validate-and-exec")} disabled={!@is_active_user}>
          <!--Start title-->
          <div>
            <label for={f[:post_title].id} class="block text-sm/6 font-medium text-gray-900">Product or Service Title <span class="text-red-500">*</span></label>
            <div class="mt-2 grid grid-cols-1">
              <input
                type="text"
                id={f[:post_title].id}
                name={f[:post_title].name}
                value={f[:post_title].value}
                autocomplete="off"
                class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 text-base outline outline-1 -outline-offset-1 focus:outline focus:outline-2 focus:-outline-offset-2 sm:text-sm/6 px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
                data-error-class="pl-3 pr-10 text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600 sm:pr-9"
                data-normal-class="px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
                phx-update="ignore"
                data-input-dispatch={JSON.encode!([
                  ["app:input-validate", %{detail: %{validator: "length", params: [10, 255]}}]
                ])}
              >
              <.icon name="hero-exclamation-circle-solid" class={["#{f[:post_title].id}-icon", "pointer-events-none col-start-1 row-start-1 mr-3 size-5 self-center justify-self-end text-red-500 sm:size-4 hidden"]}/>
            </div>
            <p class="mt-2 text-sm text-gray-500" id={"#{f[:post_title].id}-helper"}>Product or Service Title must be more than 10 words.</p>
            <p class="mt-2 text-sm text-red-500" id={"#{f[:post_title].id}-error"}></p>
          </div>
          <!--End title-->
          <!--Start Commission-->
          <div class="flex items-center gap-2">




            <div>
              <label for={"#{f[:post_meta].id}_1_meta_value"} class="block text-sm/6 font-medium text-gray-900">Commission <span class="text-red-500">*</span></label>
              <div class="mt-2 grid grid-cols-1">
                <input
                  id={"#{f[:post_meta].id}_1_meta_value"}
                  name={"#{f[:post_meta].name}[1][meta_value]"}
                  placeholder="min"
                  inputmode="numeric"
                  pattern="[0-9]*"
                  phx-update="ignore"
                  data-input-dispatch={JSON.encode!([
                    ["app:input-validate", %{detail: %{validator: "isNumber", params: []}}]
                  ])}
                  class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 text-base outline outline-1 -outline-offset-1 focus:outline focus:outline-2 focus:-outline-offset-2 sm:text-sm/6 px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
                  data-error-class="pl-3 pr-10 text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600 sm:pr-9"
                  data-normal-class="px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
                >
                <.icon name="hero-exclamation-circle-solid" class={["#{f[:post_meta].id}_1_meta_value-icon", "pointer-events-none col-start-1 row-start-1 mr-3 size-5 self-center justify-self-end text-red-500 sm:size-4 hidden"]}/>
              </div>
              <input type="text" name={"#{f[:post_meta].name}[1][meta_key]"} value={:commission_min} class="hidden"/>
              <p class="mt-2 text-sm text-gray-500" id={"#{f[:post_meta].id}_1_meta_value-helper"}>Min of commission</p>
              <p class="mt-2 text-sm text-red-500"  id={"#{f[:post_meta].id}_1_meta_value-error"} ></p>
            </div>


            <div>
              <label for={"#{f[:post_meta].id}_2_meta_value"} class="block text-sm/6 font-medium text-gray-900">&nbsp;</label>
              <div class="mt-2 grid grid-cols-1">
                <input
                  id={"#{f[:post_meta].id}_2_meta_value"}
                  type="text" name={"#{f[:post_meta].name}[2][meta_value]"}
                  placeholder="max"
                  phx-update="ignore"
                  inputmode="numeric"
                  pattern="[0-9]*"
                  data-input-dispatch={JSON.encode!([
                    ["app:input-validate", %{detail: %{validator: "isNumber", params: []}}]
                  ])}
                  class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 text-base outline outline-1 -outline-offset-1 focus:outline focus:outline-2 focus:-outline-offset-2 sm:text-sm/6 px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
                  data-error-class="pl-3 pr-10 text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600 sm:pr-9"
                  data-normal-class="px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
                >
                <.icon name="hero-exclamation-circle-solid" class={["#{f[:post_meta].id}_2_meta_value-icon", "pointer-events-none col-start-1 row-start-1 mr-3 size-5 self-center justify-self-end text-red-500 sm:size-4 hidden"]}/>
              </div>
              <input type="text" name={"#{f[:post_meta].name}[2][meta_key]"} value={:commission_max} class="hidden"/>
              <p class="mt-2 text-sm text-gray-500" id={"#{f[:post_meta].id}_2_meta_value-helper"}>Max of commission</p>
              <p class="mt-2 text-sm text-red-500"  id={"#{f[:post_meta].id}_2_meta_value-error"} ></p>
            </div>


            <div>
              <label for={"#{f[:post_meta].id}_3_meta_value"} class="block text-sm/6 font-medium text-gray-900">&nbsp;</label>
              <div class="mt-2 grid grid-cols-1">
                <select
                  id={"#{f[:post_meta].id}_3_meta_value"}
                  name={"#{f[:post_meta].name}[3][meta_value]"}
                  phx-update="ignore"
                  class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-1.5 pl-3 pr-8 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
                  data-input-dispatch={JSON.encode!([
                    ["app:input-validate", %{detail: %{validator: "inList", params: [Enum.map(get_unit(), &(elem(&1,0)))]}}]
                ])}
                >
                  <option value="">Select Unit...</option>
                  <option :for={{value, key} <- get_unit()} value={value}>{key}</option>
                </select>
                <.icon name="hero-chevron-down" class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end text-gray-500 sm:size-4"/>
              </div>
              <input type="text" name={"#{f[:post_meta].name}[3][meta_key]"} value={:commission_unit} class="hidden"/>
              <p class="mt-2 text-sm text-red-500"  id={"#{f[:post_meta].id}_3_meta_value-error"} ></p>
            </div>


            <div>
              <label for={"#{f[:post_meta].id}_4_meta_value"} class="block text-sm/6 font-medium text-gray-900">&nbsp;</label>
              <div class="mt-2 grid grid-cols-1">
                <select
                  id={"#{f[:post_meta].id}_4_meta_value"}
                  name={"#{f[:post_meta].name}[4][meta_value]"}
                  phx-update="ignore"
                  class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-1.5 pl-3 pr-8 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
                  data-input-dispatch={JSON.encode!([
                    ["app:input-validate", %{detail: %{validator: "inList", params: [commission_model()]}}]
                ])}
                >
                  <option value="">Select Model...</option>
                  <option :for={cm <- commission_model()} value={cm}>{cm}</option>
                </select>
                <.icon name="hero-chevron-down" class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end text-gray-500 sm:size-4"/>
              </div>
              <input type="text" name={"#{f[:post_meta].name}[4][meta_key]"} value={:commission_model} class="hidden"/>
              <p class="mt-2 text-sm text-red-500"  id={"#{f[:post_meta].id}_4_meta_value-error"} ></p>
            </div>
          </div>
          <!--End Commission-->
          <!--Start Description-->
          <div class="col-span-full">
            <label for="about" class="block text-sm/6 font-medium text-gray-900">Description <span class="text-red-500">*</span></label>
            <div class="mt-2">
              <textarea
                id={f[:post_content].id}
                name={f[:post_content].name}
                placeholder="Description(text or markdown)"
                rows="5"
                phx-debounce="50"
                phx-update="ignore"
                data-input-dispatch={JSON.encode!([
                  ["app:count_word"],
                  ["app:fill_text_with_attribute", %{detail: %{to_el: "#count_word_text", from_attr: "data-count-word"}}],
                  ["app:input-validate", %{detail: %{validator: "length", params: [20, 3000]}}]
                ])}
                class="block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
              >{f[:post_content].value}</textarea>
            </div>
            <div class="mt-1 text-sm/6 flex justify-between">
              <p class="text-red-500" id={"#{f[:post_content].id}-error"}>&nbsp;</p>
              <p class="text-gray-500"><span id="count_word_text" data-count-word="0">0</span>/3000</p>
            </div>
          </div>
          <!--End Description-->


          <!--Start Country-->
          <div>
            <label for="categories_0_term_taxonomy" class="block text-sm/6 font-medium text-gray-900">Select a country where your service(product) from? <span class="text-red-500">*</span></label>
            <div class="mt-2 grid grid-cols-1">
              <select
                id={"categories_0_term_taxonomy"}
                name={"#{f[:categories].name}[]"}
                phx-update="ignore"
                class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-1.5 pl-3 pr-8 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
              >
                <option :for={category <- @categories} value={category.id}>{category.term.name}</option>
              </select>
              <.icon name="hero-chevron-down" class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end text-gray-500 sm:size-4"/>
            </div>
            <p class="mt-2 text-sm text-red-500"  id="categories_0_term_taxonomy-error" ></p>
          </div>
          <!--End Country-->

          <!--Start industry-->
          <div>
            <label for="categories_0_term_taxonomy" class="block text-sm/6 font-medium text-gray-900">What industry is your service(product) in? <span class="text-red-500">*</span></label>
            <div class="mt-2 grid grid-cols-1">
              <select
                id={"categories_1_term_taxonomy_id"}
                name={"#{f[:categories].name}[]"}
                phx-update="ignore"
                class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-1.5 pl-3 pr-8 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
              >
                <option :for={industry <- @industries}  value={industry.id}>{industry.term.name}</option>
              </select>
              <.icon name="hero-chevron-down" class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end text-gray-500 sm:size-4"/>
            </div>
            <p class="mt-2 text-sm text-red-500"  id="categories_1_term_taxonomy_id-error" ></p>
          </div>
          <!--End industry-->

          <!--Start Link-->
          <div>
            <label for={"#{f[:post_meta].id}_5_meta_value"} class="block text-sm/6 font-medium text-gray-900">What is the link to your service(product)? <span class="text-red-500">*</span></label>
            <div class="mt-2 grid grid-cols-1">
              <input
                id={"#{f[:post_meta].id}_5_meta_value"}
                type="text"
                name={"#{f[:post_meta].name}[5][meta_value]"}
                phx-update="ignore"
                data-input-dispatch={JSON.encode!([
                  ["app:input-validate", %{detail: %{validator: "isURL", params: []}}]
                ])}
                class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 text-base outline outline-1 -outline-offset-1 focus:outline focus:outline-2 focus:-outline-offset-2 sm:text-sm/6 px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
                data-error-class="pl-3 pr-10 text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600 sm:pr-9"
                data-normal-class="px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
              >
              <.icon name="hero-exclamation-circle-solid" class={["#{f[:post_meta].id}_2_meta_value-icon", "pointer-events-none col-start-1 row-start-1 mr-3 size-5 self-center justify-self-end text-red-500 sm:size-4 hidden"]}/>
            </div>
            <input name={"#{f[:post_meta].name}[5][meta_key]"} type="hidden" value={:affiliate_link}/>
            <p class="mt-2 text-sm text-gray-500" id={"#{f[:post_meta].id}_5_meta_value-helper"}}>The link of your service(product).</p>
            <p class="mt-2 text-sm text-red-500"  id={"#{f[:post_meta].id}_5_meta_value-error"} ></p>
          </div>
          <!--End Link-->
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
          <div class="flex justify-end p-4 border-t !mt-6">
            <button id={@form[:submit].id} type="submit" phx-disable-with="Saving..." class="rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-green-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-green-600"  disabled>Submit</button>
        </div>
        <input name={f[:post_type].name} type="hidden" value={:affiliate}/>
        <input name={f[:post_date].name} type="hidden" value={DateTime.utc_now()}/>
        </.form>
      </div>
    </div>
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

  def commission_model(), do: ["CPC", "CPS", "CPL", "CPI", "Recurring"]
end
