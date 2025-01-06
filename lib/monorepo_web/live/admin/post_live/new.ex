defmodule MonorepoWeb.AdminPostLive.New do
  use MonorepoWeb.Admin, :live_view

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Monorepo.PubSub, "admin:media")

    form = resource_to_form(socket)

    term_taxonomy_categories =
      Monorepo.Terms.read_term_taxonomy!("category", nil, actor: socket.assigns.current_user)
      |> Ash.load!([:term], actor: socket.assigns.current_user)
      |> Enum.map(&%{id: &1.id, name: &1.term.name})

    socket =
      socket
      |> assign(
        selected_image: nil,
        featured_image: nil,
        selected_categories: [],
        form: form,
        term_taxonomy_categories: term_taxonomy_categories
      )

    {:ok,
      socket,
      layout: false,
      temporary_assigns: [
        selected_image_modal_id: generate_random_id(),
        create_category_modal_id: generate_random_id(),
      ]
    }
  end

  @impl true
  def handle_params(_unsigned_params, uri, socket) do
    %{scheme: scheme, authority: authority} = URI.parse(uri)
    {:noreply, assign(socket, host: "#{scheme}://#{authority}/p")}
  end

  @impl true
  def handle_info({:broadcast_selected, id}, socket) do
    socket =
      socket
      |> assign(:selected_image, id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("featured_image", %{"media-id" => id}, socket) do
    socket =
      case id do
        "" -> assign(socket, :featured_image, nil)
        nil -> assign(socket, :featured_image, nil)
        id ->
          media =
            Ash.get!(Monorepo.Contents.Post, id, actor: socket.assigns.current_user)
            |> Ash.load!([:post_meta])

          assign(socket, :featured_image, media)
      end
    {:noreply, socket}
  end


  def handle_event("reset_selected_image", _, socket) do
    {:noreply, assign(socket, :selected_image, nil)}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    selected_categories =
      Map.get(params, "term_taxonomy", [])
      |> Enum.filter(fn {_, v} -> v["taxonomy_id"] == "on" end)
      |> Enum.map(fn {id, _} -> id end)

    socket =
      socket
      |> assign(form: AshPhoenix.Form.validate(socket.assigns.form, params))
      |> assign(:selected_categories, selected_categories)

    {:noreply, socket}
  end

  defp resource_to_form(socket) do
    AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post, [
      forms: [
        post_meta: [
          type: :list,
          resource: Monorepo.Contents.PostMeta,
          update_action: :update,
          create_action: :create
        ],
        term_taxonomy_categories: [
          type: :list,
          data: [],
          resource: Monorepo.Terms.TermTaxonomy,
          update_action: :update,
          create_action: :create,
          read_action: :read
        ],
        term_taxonomy_tags: [
          type: :list,
          data: [],
          resource: Monorepo.Terms.TermTaxonomy,
          update_action: :update,
          create_action: :create
        ]
      ]
    ])
    |> AshPhoenix.Form.add_form([:term_taxonomy_categories])
    |> AshPhoenix.Form.add_form([:term_taxonomy_tags])
    |> to_form()
  end


end
