defmodule MonorepoWeb.AdminPostLive.FormField.PostCategories do
  use MonorepoWeb.Admin, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{current_user: current_user, form: form, id: id}, socket) do
    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:form, form)

    term_taxonomy_categories =
      Monorepo.Terms.read_term_taxonomy!("category", nil, actor: current_user)
      |> Ash.load!([:term], actor: current_user)

    socket =
      socket
      |> assign(:term_taxonomy_categories, term_taxonomy_categories)
      |> assign(:id, id)
      |> assign(:selected_categories, [])

    {:ok, socket}
  end

  def update(_, %{assigns: %{current_user: current_user}} = socket) do
    term_taxonomy_categories =
      Monorepo.Terms.read_term_taxonomy!("category", nil, actor: current_user)
      |> Ash.load!([:term], actor: current_user)
    socket =
      socket
      |> assign(:term_taxonomy_categories, term_taxonomy_categories)

    {:ok, socket}
  end

  @impl true
  def handle_event("add-or-remove-category", %{"id" => id}, socket) do
    selected_categories = socket.assigns.selected_categories

    selected_categories =
      if Enum.member?(selected_categories, id) do
        Enum.reject(selected_categories, & &1 == id)
      else
        [id | selected_categories]
      end

    socket =
      socket
      |> assign(selected_categories: selected_categories)

    {:noreply, socket}
  end



  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <button
        type="button"
        class="hover:bg-gray-50 border flex items-center justify-between w-full text-left rounded-md p-2 gap-x-3 text-sm/6 font-semibold text-gray-700 rounded-bl-none rounded-br-none" aria-controls="sub-menu-1"  aria-expanded="false"
        phx-click={MonorepoWeb.AdminPostLive.SideBar.accordion("#sub-menu-2-icon", "#sub-menu-2")}
      >
        Categories
        <Lucideicons.chevron_up id="sub-menu-2-icon" class="w-4 h-4" />
      </button>
      <div class="space-y-2" id="sub-menu-2">
          <div id="term-taxonomy-category" class="space-y-1 max-h-[180px] overflow-y-scroll border  px-4 py-2.5 rounded-sm border-t-0 rounded-br-md rounded-bl-md">
            <div><.link class="text-gray-500 hover:underline text-sm flex items-center gap-1" phx-click={show_modal("create_category_modal_id")}><Lucideicons.plus class="size-4"/>Add New Category</.link></div>
            <%= for {term_taxonomy, i} <- Enum.with_index(@term_taxonomy_categories) do %>
              <.checkbox
                id={"term-taxonomy-category-#{i}"}
                name={"#{@form[:categories].name}[]"}
                value={term_taxonomy.id}
                label={term_taxonomy.term.name}
                phx-click="add-or-remove-category"
                phx-value-id={term_taxonomy.id}
                phx-target={@myself}
                checked={Enum.member?(@selected_categories, term_taxonomy.id)}
              />
            <% end %>
          </div>
      </div>
    </div>
    """
  end
end
