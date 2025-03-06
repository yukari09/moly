defmodule MonorepoWeb.AdminWebsiteLive.Index do
  use MonorepoWeb.Admin, :live_view

  @per_page 20

  def mount(_params, _session, socket) do
    modal_id = Monorepo.Helper.generate_random_id()
    {:ok, socket, temporary_assigns: [modal_id: modal_id]}
  end

  def handle_params(params, _uri, socket) do
    page = params["page"] && String.to_integer(params["page"]) || 1
    q = params["q"]

    socket =
      assign(socket, page: page, q: q)
      |> assign(:item, nil)
      |> get_website_term()

    {:noreply, socket}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    item =
      Ash.get!(Monorepo.Terms.Term, id, actor: %{roles: [:admin]})
      |> Ash.load!([:term_meta, :term_taxonomy], actor: %{roles: [:admin]})
    socket =
      socket
      |> assign(:live_action, :edit)
      |> assign(:item, item)
    {:noreply, socket}
  end

  def handle_event("create", _params, socket) do
    {:noreply, assign(socket, :live_action, :create)}
  end

  def handle_event("index", _params, socket) do
    {:noreply, assign(socket, :live_action, :index)}
  end

  def handle_event("search", %{"q" => q}, socket) do
    socket =
      socket
      |> assign(:q, q)
      |> get_website_term()
    {:noreply, socket}
  end

  def get_website_term(socket) do
    page = socket.assigns.page
    q = socket.assigns.q
    offset = (page - 1) * @per_page

    opts = [
      actor: socket.assigns.current_user,
      page: [limit:  @per_page, offset: offset, count: true]
    ]

    query =
      Ash.Query.new(Monorepo.Terms.Term)
      |> Ash.Query.filter(term_taxonomy.taxonomy == "website")
      |> Ash.Query.load([:term_taxonomy, :term_meta])

    query = if q not in [nil, "", false], do: Ash.Query.filter(query, expr(contains(name, ^q))), else: query

    result =
      query
      |> Ash.read!(opts)

    socket
    |> assign(:page_meta, pagination_meta(result.count, @per_page, page, 9))
    |> assign(:result, result)
    |> assign(:params, %{page: page, q: q})
  end

  defp live_url(params) do
    ~p"/admin/website?#{params}"
  end

end
