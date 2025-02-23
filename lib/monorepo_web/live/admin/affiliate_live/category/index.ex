defmodule MonorepoWeb.AdminAffiliateLive.Categories.Index do
  use MonorepoWeb.Admin, :live_view

  @per_page "10"
  @model Monorepo.Terms.Term

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [modal_id: generate_random_id()]}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket = assign(socket, :form, nil) |> get_list_by_params(params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"q" => q} = _params, socket) do
    socket = socket |> push_patch(to: live_url(%{page: 1, q: q}))
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    get_category_by_id(id, socket.assigns.current_user)
    |> Ash.destroy!(actor: socket.assigns.current_user)

    {:noreply, push_patch(socket, to: live_url(socket.assigns.params))}
  end

  def handle_event("create", _, socket) do
    socket = socket |> assign(:form, category_to_form(nil, nil))
    {:noreply, socket}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    form = category_to_form(id, socket.assigns.current_user)
    socket = socket |> assign(:form, form)
    {:noreply, socket}
  end

  defp get_list_by_params(socket, params) do
    current_user = socket.assigns.current_user

    page =
      Map.get(params, "page", "1")
      |> String.to_integer()

    per_page =
      Map.get(params, "per_page", @per_page)
      |> String.to_integer()

    q =
      Map.get(params, "q", "")
      |> case do
        "" -> nil
        q -> q
      end

    limit = per_page
    offset = (page - 1) * per_page

    opts = [
      actor: current_user,
      page: [limit: limit, offset: offset, count: true]
    ]

    query =
      @model
      |> Ash.Query.filter(term_taxonomy.taxonomy == "affiliate_category")
      |> Ash.Query.load(term_taxonomy: :parent)

    query =
      if is_nil(q) do
        query
      else
        query
        |> Ash.Query.filter(expr(contains(name, ^q)))
      end

    data = Ash.read!(query, opts)

    socket =
      socket
      |> assign(:categories, data)
      |> assign(:page_meta, pagination_meta(data.count, per_page, page, 9))
      |> assign(:params, %{page: page, per_page: per_page, q: q})

    socket
  end

  defp live_url(query_params) when is_map(query_params) do
    ~p"/admin/affiliate/categories?#{query_params}"
  end

  def get_category_by_id(id, current_user) do
    Ash.get!(Monorepo.Terms.Term, id, actor: current_user)
    |> Ash.load!([:term_taxonomy], actor: current_user)
  end

  defp category_to_form(nil, _) do
    AshPhoenix.Form.for_create(Monorepo.Terms.Term, :create,
      forms: [
        term_taxonomy: [
          type: :list,
          data: [%Monorepo.Terms.TermTaxonomy{taxonomy: "category"}],
          resource: Monorepo.Terms.TermTaxonomy,
          update_action: :create
        ]
      ]
    )
    |> to_form()
  end

  defp category_to_form(categoires_id, current_user) do
    term = get_category_by_id(categoires_id, current_user)

    AshPhoenix.Form.for_update(term, :update,
      forms: [
        term_taxonomy: [
          type: :list,
          data: term.term_taxonomy,
          resource: Monorepo.Terms.TermTaxonomy,
          update_action: :update
        ]
      ]
    )
    |> to_form()
  end
end
