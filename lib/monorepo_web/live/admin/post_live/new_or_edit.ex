defmodule MonorepoWeb.AdminPostLive.NewOrEdit do
  use MonorepoWeb.Admin, :live_view

  @impl true
  def mount(params, _session, socket) do
    temporary_assigns = [
      post_slug: generate_random_str(),
      create_category_modal_id: generate_random_id(),
    ]

    {:ok, init_socket(socket, params), layout: false, temporary_assigns: temporary_assigns}
  end

  defp init_socket(socket, params) do
    post =
      if Map.get(params, "id") do
        Ash.get!(Monorepo.Contents.Post, params["id"], actor: socket.assigns.current_user)
        |> Ash.load!([:term_taxonomy_categories, :term_taxonomy_tags], actor: socket.assigns.current_user)
      else
        nil
      end
    resource_to_form(socket, post)
  end

  @impl true
  def handle_params(_, uri, socket) do
    %{scheme: scheme, authority: authority} = URI.parse(uri)
    socket = assign(socket, host: "#{scheme}://#{authority}/p/")
    {:noreply, socket}
  end


  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    socket =
      case AshPhoenix.Form.submit(socket.assigns.form, params: params, action_opts: [actor: socket.assigns.current_user]) do
        {:ok, post} ->
          socket
          |> put_flash(:info, "Saved post for #{post.post_title}!")
          |> push_navigate(to: ~p"/admin/posts")
        {:error, form} ->
          socket
          |> assign(form: form)
          |> put_flash(:error, "Oops, some thing wrong.")
      end

    {:noreply, socket}
  end


  defp resource_to_form(socket, nil) do
    form = AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post, [
      forms: [
        auto?: true
      ],
      actor: socket.assigns.current_user
    ])
    |> to_form()
    assign(socket, form: form)
  end

  defp resource_to_form(socket, post) do
    form = AshPhoenix.Form.for_update(post, :update_post, [
      forms: [
        auto?: true
      ],
      data: post,
      actor: socket.assigns.current_user
    ])
    |> to_form()
    assign(socket, form: form)
  end


end
