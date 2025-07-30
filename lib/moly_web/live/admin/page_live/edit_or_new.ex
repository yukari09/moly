defmodule MolyWeb.AdminPageLive.EditOrNew do
  use MolyWeb.Admin, :live_view

  @impl true
  def mount(_params, _session, socket) do
    dom_ids = %{
      editor_id: Moly.Helper.generate_random_id(),
      preview_id: Moly.Helper.generate_random_id(),
      textarea_id: Moly.Helper.generate_random_id(),
      modal_id: Moly.Helper.generate_random_id()
    }
    {:ok, assign(socket, dom_ids), layout: false}
  end


  def handle_params(%{"id" => id }, _uri, socket) do
    {:noreply, load_or_create_form(socket, id)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, load_or_create_form(socket)}
  end

  @impl true
  def handle_event("submit", %{"form" => %{"post_title" => post_title, "post_content" => post_content, "post_excerpt" => post_excerpt}}, socket) do
    assign_form = socket.assigns.form

    form_data = %{
      post_title: post_title,
      post_content: post_content,
      post_type: :page,
      post_status: :draft,
      post_name: Slug.slugify(post_title),
      post_excerpt: post_excerpt,
      guid: assign_form[:guid].value || ~p"/page/#{Moly.Helper.generate_random_str()}",
      post_date: DateTime.utc_now()
    }

    socket =
      case AshPhoenix.Form.submit(assign_form, params: form_data) do
        {:ok, _} ->
          push_navigate(socket, to: ~p"/admin/pages")
        {:error, form} ->
          assign(socket, :form, form)
          |> put_flash(:error, "Oops, some thing wrong: #{JSON.encode!(form.errors)}")
      end

    {:noreply, socket}
  end

  def handle_event("ace"<>_event, _params, socket) do
    {:noreply, socket}
  end

  defp load_or_create_form(socket, id \\ nil) do
    form =  if id do
      Ash.get!(Moly.Contents.Post, id,
        actor: socket.assigns.current_user
      )
      |> AshPhoenix.Form.for_update(:update_post, forms: [auto?: true], actor: socket.assigns.current_user)
      |> to_form()
    else
      AshPhoenix.Form.for_create(Moly.Contents.Post, :create_post, forms: [auto?: true], actor: socket.assigns.current_user) |> to_form()
    end

    assign(socket, form: form)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} id="admin-flash" />
    <div  phx-mounted={JS.push("initiate_editor")}>
      <.form for={@form} phx-submit="submit">
        <div>
          <div class="flex justify-between items-center py-2 px-4 w-full box-border border-b border-gray-200">
            <div>
              <.link navigate={~p"/admin/pages"}>
                <img src={Moly.website_logo} class="size-6" />
              </.link>
            </div>
            <div class="flex-1 px-4">
              <input
                id="page_title"
                placeholder="Page title..."
                autocomplete="off"
                class="border-0 outline-none w-full bg-inherit font-semibold"
                name={@form[:post_title].name}
                value={@form[:post_title].value}
              />
            </div>
            <div class="flex items-center gap-2">
              <.button
                size="xs"
                type="submit"
                phx-disable-with="Saving..."
              >
                Save
              </.button>
            </div>
          </div>
          <div class="flex h-[calc(100vh_-_45px)]">
            <div class="w-3/4">
              <div
                id={@editor_id}
                phx-hook="AceEditor"
                data-theme="ace/theme/github"
                data-mode="ace/mode/html"
                data-font-size="14"
                data-initial-value={@form[:post_content].value}
                data-debounce="300"
                data-name={@form[:post_content].name}
                class="h-full overflow-y-scroll"
              ></div>
            </div>
            <div class="bg-gray-50 w-1/4">
              <.textarea field={@form[:post_excerpt]} label="Page Description" container_class="p-4"/>
            </div>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
