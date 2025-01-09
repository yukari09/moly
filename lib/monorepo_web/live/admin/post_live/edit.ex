defmodule MonorepoWeb.AdminPostLive.Edit do
  use MonorepoWeb.Admin, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    term_taxonomy_categories =
      Monorepo.Terms.read_term_taxonomy!("category", nil, actor: socket.assigns.current_user)
      |> Ash.load!([:term], actor: socket.assigns.current_user)

    post =
      Ash.get!(Monorepo.Contents.Post, id, actor: socket.assigns.current_user)
      |> Ash.load!([:post_meta], actor: socket.assigns.current_user)

    form = resource_to_form(socket.assigns.current_user)

    socket =
      socket
      |> assign(
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
        slug_dropdown_id: generate_random_id(),
        post_slug: "/#{generate_random_str(8)}"
      ]
    }
  end

  @impl true
  def handle_params(_unsigned_params, uri, socket) do
    %{scheme: scheme, authority: authority} = URI.parse(uri)
    {:noreply, assign(socket, host: "#{scheme}://#{authority}/p")}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    socket =
      case AshPhoenix.Form.submit(socket.assigns.form, params: params, action_opts: [actor: socket.assigns.current_user]) do
        {:ok, post} ->
          socket
          |> put_flash(:info, "Saved post for #{post.post_title}!")
          |> push_patch(to: ~p"/admin/posts")
        {:error, form} ->
          socket
          |> assign(form: form)
      end

    {:noreply, socket}
  end

  defp resource_to_form(actor) do
    AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post, [
      forms: [
        auto?: true
      ],
      actor: actor
    ])
    |> to_form()
  end


end
