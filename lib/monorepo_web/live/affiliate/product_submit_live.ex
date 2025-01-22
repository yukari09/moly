defmodule MonorepoWeb.Affiliate.ProductSubmitLive do
  use MonorepoWeb, :live_view

  require Ash.Query


  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    form = resource_form(current_user)
    socket =
      assign(socket, form: form, step: 1)
      |> allow_upload(:media, accept: ~w(.jpg .jpeg, .png .webp .avif), max_entries: 12)

    categories = get_term_taxonomy("countries", current_user)
    industries = get_term_taxonomy("industries", current_user)

    {:ok, socket, temporary_assigns: [categories: categories, industries: industries], layout: false}
  end

  def handle_event("next-step", _, socket) do
    socket = assign(socket, :step, socket.assigns.step + 1)
    {:noreply, socket}
  end

  def handle_event("partial_update", %{"_target" => ["user_meta", i, _], "user_meta" => user_meta}, socket) do
    updated_user_meta =  user_meta[i]
    meta_key = String.to_atom(updated_user_meta["meta_key"])
    meta_value = updated_user_meta["meta_value"]

    old_meta_value = Monorepo.Accounts.Helper.load_meta_value_by_meta_key(socket.assigns.current_user, meta_key)

    socket =
      if old_meta_value != meta_value do
        new_user_meta_party = [%{meta_key: meta_key, meta_value: meta_value}]
        changeset = Ash.Changeset.new(socket.assigns.current_user)
        result = Ash.update(changeset, %{user_meta: new_user_meta_party}, action: :update_user_meta, context: %{private: %{ash_authentication?: true}})
        case result do
          {:ok, new_current_user} ->
            put_flash(socket, :info, "Your information has been updated.")
            |> assign(:current_user, new_current_user)
          {:error, _} -> put_flash(socket, :error, "Your information update failed, please try again later")
        end
      else
        socket
      end

    {:noreply, socket}
  end

  defp resource_form(id \\ nil, current_user) do
    data =
      if is_nil(id) do
        AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post, [
          forms: [
            auto?: true
          ]
        ])
      else
        post =
          Ash.Query.filter(Monorepo.Contents.Post, id == ^id and auth author_id == current_user.id)
          |> Ash.read_first!(actor: current_user)

        AshPhoenix.Form.for_update(post, :create_post, [
          forms: [
            auto?: true
          ],
          data: post
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
  <button class="btn" phx-click={JS.dispatch("phx:show-modal", detail: %{el: "#submit_modal"})}>open modal</button>

  <dialog id="submit_modal" class="modal">
    <div class="modal-box space-y-2 p-0">
      <.form id="steps-form" :let={f} for={@form} data-current-step="1">
      <ul class="steps text-sm w-full py-6 border-b">
        <li data-step-siginal="1" class="step">Info</li>
        <li data-step-siginal="2" class="step">Category</li>
        <li data-step-siginal="3" class="step">Meida</li>
        <li data-step-siginal="4" class="step">Receive Product</li>
      </ul>
      <div class="pt-4 space-y-2">
        <div id="form-step-1" class="px-6 max-h-[calc(80vh)] overflow-scroll-y" data-step="1">
          <label class="form-control w-full">
            <div class="label">
              <span class="label-text font-medium">Product or Service Title</span>
            </div>
            <input
              type="text"
              id={f[:title].id}
              name={f[:title].name}
              value={f[:title].value}
              phx-change={
                JS.dispatch("app:validate_input")
                |> JS.dispatch("app:enable_btn_from_form_inputs")
              }
              autocomplete="off"
              class="input input-bordered w-full"
              data-validator="length"
              data-validator-params="10,255"
              data-target-btn="#next-btn"
              data-target-els={"##{f[:title].id},##{f[:post_content].id}"}
            />
            <div class="label">
              <span id={"#{f[:title].id}-helper"} class="label-text-alt text-gray-500">Product or Service Title must be more than 10 words long.</span>
              <span id={"#{f[:title].id}-error"}  class="label-text-alt text-red-500 hidden"></span>
            </div>
          </label>
          <label class="form-control w-full">
            <div class="label">
              <span class="label-text font-medium">Description</span>
            </div>
            <textarea
              id={f[:post_content].id}
              type="text"
              name={f[:post_content].name}
              placeholder="Description"
              rows="5"
              class="textarea textarea-bordered resize-none w-full"
              phx-debounce="50"
              phx-change={
                JS.dispatch("app:count_word")
                |> JS.dispatch("app:fill_text_with_attribute", detail: %{to_el: "#count_word_text", from_attr: "data-count-word"})
                |> JS.dispatch("app:validate_input")
                |> JS.dispatch("app:enable_btn_from_form_inputs")
              }
              data-validator="length"
              data-validator-params="20,3000"
              data-target-btn="#next-btn"
              data-target-els={"##{f[:title].id},##{f[:post_content].id}"}
            >{f[:title].value}</textarea>
            <div class="label">
              <span class="label-text-alt text-red-500 hidden" id={"#{f[:post_content].id}-error"}></span>
              <span class="label-text-alt text-gray-500" id={"#{f[:post_content].id}-helper"}></span>
              <span class="label-text-alt text-gray-500"><span id="count_word_text">0</span>/3000</span>
            </div>
          </label>
        </div>
        <!--Start step 2-->
        <div id="form-step-2" class="px-6 max-h-[calc(80vh)] overflow-scroll-y" data-step="2">
          <label class="form-control w-full">
            <div class="label">
              <span class="label-text font-medium">Select a country where your service(product) from?</span>
            </div>
            <select
              id={"#{f[:categories].id}_0_term_taxonomy"}
              class="select select-bordered"
              name={"#{f[:categories].id}[0][term_taxonomy_id]"}
              phx-change={
                JS.dispatch("app:validate_input")
                |> JS.dispatch("app:enable_btn_from_form_inputs")
              }
              autocomplete="off"
              class="input input-bordered w-full"
              data-validator="length"
              data-validator-params="5,255"
              data-target-btn="#next-btn"
              data-target-els={"##{f[:categories].id}_0_term_taxonomy"}
            >
              <option :for={category <- @categories}>{category.term.name}</option>
            </select>
            <div class="label">
              <span id={"#{f[:categories].id}_0_term_taxonomy-helper"} class="label-text-alt text-gray-500"></span>
              <span id={"#{f[:categories].id}_0_term_taxonomy-error"}  class="label-text-alt text-red-500 hidden"></span>
            </div>
          </label>
          <label class="form-control w-full">
            <div class="label">
              <span class="label-text font-medium">What industry is your service(product) in?</span>
            </div>
            <select class="select select-bordered" name={"#{f[:industries].id}[0][term_taxonomy_id]"}>
              <option :for={industry <- @industries}>{industry.term.name}</option>
            </select>
            <div class="label">
              <span id={"#{f[:industries].id}[0][term_taxonomy_id]-error"}  class="label-text-alt text-red-500 hidden"></span>
            </div>
          </label>
          <label>
              <div class="label"><span class="label-text font-medium">What is the link to your service(product)?</span></div>
              <input
              type="text"
              id={"#{f[:post_meta].id}_0_meta_value"}
              name={"#{f[:post_meta].name}[0][meta_value]"}
              phx-change={
                JS.dispatch("app:validate_input")
                |> JS.dispatch("app:enable_btn_from_form_inputs")
              }
              autocomplete="off"
              class="input input-bordered w-full"
              data-validator="isURL"
              data-target-btn="#next-btn"
              data-target-els={"##{f[:post_meta].id}_0_meta_value"}
            />
            <div class="label">
              <span id={"#{f[:post_meta].id}_0_meta_value-helper"} class="label-text-alt text-gray-500">The link of your service(product).</span>
              <span id={"#{f[:post_meta].id}_0_meta_value-error"}  class="label-text-alt text-red-500 hidden"></span>
            </div>
          </label>
        </div>
        <!--End step 2-->
        <!--End step 3-->
        <div class="flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10">
            <div class="text-center">
              <svg class="mx-auto size-12 text-gray-300" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" data-slot="icon">
                <path fill-rule="evenodd" d="M1.5 6a2.25 2.25 0 0 1 2.25-2.25h16.5A2.25 2.25 0 0 1 22.5 6v12a2.25 2.25 0 0 1-2.25 2.25H3.75A2.25 2.25 0 0 1 1.5 18V6ZM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0 0 21 18v-1.94l-2.69-2.689a1.5 1.5 0 0 0-2.12 0l-.88.879.97.97a.75.75 0 1 1-1.06 1.06l-5.16-5.159a1.5 1.5 0 0 0-2.12 0L3 16.061Zm10.125-7.81a1.125 1.125 0 1 1 2.25 0 1.125 1.125 0 0 1-2.25 0Z" clip-rule="evenodd" />
              </svg>
              <div class="mt-4 flex text-sm/6 text-gray-600">
                <label for="file-upload" class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500">
                  <span>Upload a file</span>
                  <input id="file-upload" name="file-upload" type="file" class="sr-only">
                </label>
                <p class="pl-1">or drag and drop</p>
              </div>
              <p class="text-xs/5 text-gray-600">PNG, JPG, GIF up to 10MB</p>
            </div>
          </div>
        <!--End step 3-->
        <div class="border-t flex justify-end px-6 py-4">
          <button id="next-btn" type="button" class="btn btn-sm btn-diabled" phx-click={
            JS.set_attribute({"data-current-step", "2"}, to: "#steps-form")
            |> JS.set_attribute({"disabled", "disabled"})
            |> JS.add_class("btn-disabled")
          } disabled>Next</button>
        </div>
      </div>
      </.form>
    </div>
    <form method="dialog" class="modal-backdrop">
      <button>close</button>
    </form>
  </dialog>
  """
  end
end
