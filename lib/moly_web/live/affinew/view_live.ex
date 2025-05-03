defmodule MolyWeb.Affinew.ViewLive do
  use MolyWeb, :live_view

  require Ash.Query

  alias Moly.Contents.Notifiers.Post

  import MolyWeb.Affinew.Components

  def mount(_params, _session, socket) do
    {:ok, socket, layout: {MolyWeb.Layouts, :affinew}}
  end

  def handle_params(%{"post_name" => post_name}, uri, socket) do
    {:ok, post} =
      Snap.Search.search(Moly.Cluster, Post.index_name(), %{
        query: %{term: %{"post_name.keyword" => post_name}}
      })

    post = Moly.Helper.get_in_from_keys(post, [:hits, :hits, 0])

    socket =
      if is_nil(post) do
        socket
        |> push_navigate(to: ~p"/browse")
      else
        {:ok, posts} =
          Snap.Search.search(Moly.Cluster, Post.index_name(), %{
            query: %{
              bool: %{
                must: [
                  %{term: %{post_status: "publish"}},
                  %{term: %{post_type: "affiliate"}},
                  %{
                    more_like_this: %{
                      fields: [:post_title, :post_content],
                      like: %{
                        _index: Post.index_name(),
                        _id: post.id
                      },
                      min_term_freq: 1,
                      max_query_terms: 12
                    }
                  }
                ]
              }
            },
            size: 11
          })

        socket =
          assign(socket, post: post, posts: posts)
          |> assign_new(:bookmark_event, fn ->
            if socket.assigns.current_user do
              post_id = Moly.Helper.get_in_from_keys(post, [:source, "id"])

              Ash.Query.new(Moly.Accounts.UserPostAction)
              |> Ash.Query.filter(
                post_id == ^post_id and user_id == ^socket.assigns.current_user.id
              )
              |> Ash.exists?(actor: %{roles: [:user]})
              |> if do
                "unbookmark_post"
              else
                "bookmark_post"
              end
            else
              "require_login"
            end
          end)
          |> assign(:current_uri, uri)

        page_meta(socket)
      end

    {:noreply, socket}
  end

  def handle_event("bookmark_post", _params, socket) do
    :timer.sleep(100)
    current_user = socket.assigns.current_user
    post_id = Moly.Helper.get_in_from_keys(socket.assigns.post, [:source, "id"])

    socket =
      if is_nil(current_user) do
        put_flash(socket, :error, "Please login to bookmark this post")
        |> push_navigate(to: ~p"/sign-in")
      else
        input = %{post: post_id, action: :bookmark}
        user = Map.put(current_user, :roles, [:owner])

        case Ash.create(Moly.Accounts.UserPostAction, input, actor: user, action: :create) do
          {:ok, _} ->
            assign(socket, bookmark_event: "unbookmark_post")

          {:error, _} ->
            put_flash(socket, :error, "Failed to bookmark post")
            |> assign(bookmark_event: "bookmark_post")
        end
      end

    {:noreply, socket}
  end

  def handle_event("unbookmark_post", _params, socket) do
    :timer.sleep(100)
    current_user = socket.assigns.current_user
    post_id = Moly.Helper.get_in_from_keys(socket.assigns.post, [:source, "id"])

    socket =
      if is_nil(current_user) do
        put_flash(socket, :error, "Please login to bookmark this post")
        |> push_navigate(to: ~p"/sign-in")
      else
        current_user = Map.put(current_user, :roles, [:owner])

        user_action =
          Ash.Query.new(Moly.Accounts.UserPostAction)
          |> Ash.Query.filter(post_id == ^post_id and user_id == ^current_user.id)
          |> Ash.read_first!(actor: current_user)

        case Ash.destroy(user_action, actor: current_user, action: :destroy) do
          :ok ->
            assign(socket, bookmark_event: "bookmark_post")

          {:error, _} ->
            assign(socket, bookmark_event: "unbookmark_post")
            |> put_flash(:error, "There is a small problem, please try again later.")
        end
      end

    {:noreply, socket}
  end

  def handle_event("require_login", _, socket) do
    socket = put_flash(socket, :error, "Please log in first")
    {:noreply, socket}
  end

  defp page_meta(%{assigns: %{post: post}} = socket) do
    media_url = featrue_image_src(post)
    post_title = Moly.Helper.get_in_from_keys(post, [:source, "post_title"])
    post_excerpt = Moly.Helper.get_in_from_keys(post, [:source, "post_excerpt"])

    meta_tags = [
      %{property: "og:title", content: post_title},
      %{property: "og:description", content: post_excerpt},
      %{property: "og:type", content: "article"},
      %{property: "og:image", content: media_url},
      %{name: "twitter:card", content: "summary_large_image"},
      %{name: "twitter:title", content: post_title},
      %{name: "twitter:description", content: post_excerpt},
      %{name: "twitter:image", content: media_url},
      %{name: "description", content: post_excerpt},
    ]

    assign(socket, :meta_tags, meta_tags)
    |> assign(
      :page_title,
      "#{post_title}"
    )
  end
end
