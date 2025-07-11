defmodule MolyWeb.AdminPostLive.NewOrEdit do
  use MolyWeb.Admin, :live_view

  require Logger

  @impl true
  def mount(params, _session, socket) do
    temporary_assigns = [
      post_slug: generate_random_str(),
      create_category_modal_id: generate_random_id()
    ]

    {:ok, init_socket(socket, params), layout: false, temporary_assigns: temporary_assigns}
  end

  defp init_socket(socket, params) do
    post =
      if Map.get(params, "id") do
        Ash.get!(Moly.Contents.Post, params["id"], actor: socket.assigns.current_user)
        |> Ash.load!([:post_meta, :post_categories, :post_tags],
          actor: socket.assigns.current_user
        )
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
    params =
      case Map.get(params, "tags") do
        nil ->
          params

        tags ->
          new_tags =
            Enum.uniq_by(tags, fn {_k, %{"name" => name}} -> name end)
            |> Enum.with_index()
            |> Enum.reduce(%{}, fn {{_k, v}, index}, acc ->
              slug = Slug.slugify(v["name"])
              Map.put(acc, index, Map.put(v, "slug", slug))
            end)
          Map.put(params, "tags", new_tags)
      end
    socket =
      case AshPhoenix.Form.submit(socket.assigns.form,
             params: params,
             action_opts: [actor: socket.assigns.current_user]
           ) do
        {:ok, post} ->
          socket
          |> put_flash(:info, "Saved post for #{post.post_title}!")
          |> push_navigate(to: ~p"/admin/posts")

        {:error, form} ->
          socket
          |> assign(form: form)
          |> put_flash(:error, "Oops, some thing wrong: #{JSON.encode!(form.errors)}")
      end

    {:noreply, socket}
  end

  # def handle_event("validate", %{"form" => params}, socket) do
  #   form = AshPhoenix.Form.validate(socket.assigns.form, params: params, action_opts: [actor: socket.assigns.current_user])
  #   {:noreply, assign(socket, :form, form)}
  # end

  def handle_event("delete", %{"id" => id}, socket) do
    Ash.get!(Moly.Contents.Post, id, actor: socket.assigns.current_user)
    |> Ash.destroy!(action: :destroy_post, actor: socket.assigns.current_user)

    socket = push_navigate(socket, to: ~p"/admin/posts")
    {:noreply, socket}
  end

  defp resource_to_form(socket, nil) do
    form =
      AshPhoenix.Form.for_create(Moly.Contents.Post, :create_post,
        forms: [
          auto?: true
        ],
        actor: socket.assigns.current_user
      )
      |> to_form()

    assign(socket, form: form)
  end

  defp resource_to_form(socket, post) do
    form =
      AshPhoenix.Form.for_update(post, :update_post,
        forms: [
          auto?: true
        ],
        data: post,
        actor: socket.assigns.current_user
      )
      |> to_form()

    assign(socket, form: form)
  end
end
