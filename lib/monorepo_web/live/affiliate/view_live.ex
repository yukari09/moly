defmodule MonorepoWeb.Affiliate.ViewLive do
  use MonorepoWeb, :live_view
  require Ash.Query

  def mount(_params, _session, socket) do
    country_category =
      Monorepo.Utilities.cache_get_or_put(:viewliview_countries, fn ->
        Monorepo.Terms.read_by_term_slug!("countries", actor: %{roles: [:user]}) |> List.first()
      end, :timer.hours(2))

    industry_category =
      Monorepo.Utilities.cache_get_or_put(:viewliview_industries, fn ->
        Monorepo.Terms.read_by_term_slug!("industries", actor: %{roles: [:user]}) |> List.first()
      end, :timer.hours(2))

    socket =
      socket
      |> assign(country_category: country_category, industry_category: industry_category)

    {:ok, socket}
  end

  def handle_params(%{"post_name" => post_name}, _uri, socket) do
    opts = [
      actor: %{roles: [:user]},
      context: %{private: %{ash_authentication?: true}}
    ]


    post =
      Monorepo.Utilities.cache_get_or_put(":liveview_post", fn ->
        Ash.Query.for_read(Monorepo.Contents.Post, :read)
        |> Ash.Query.filter(post_name == ^post_name)
        |> Ash.Query.load([:affiliate_categories, :affiliate_tags, :post_categories, :post_tags, author: :user_meta, post_meta: :children])
        |> Ash.read!(opts)
        |> List.first()
      end, :timer.hours(2))

    current_user_bookmark =

        if socket.assigns.current_user do
          Ash.Query.for_read(Monorepo.Accounts.UserPostAction, :read)
          |> Ash.Query.filter(user_id == ^socket.assigns.current_user.id and post_id == ^post.id and action == :bookmark)
          |> Ash.read_first(opts)
          |> case do
            {:error, _} -> nil
            {:ok, result} -> result
          end
        else
          nil
        end


    socket = assign(
      socket,
      post: post,
      page_title: post.post_title,
      current_user_bookmark: current_user_bookmark
    )
    socket = html_mata(socket)
    {:noreply, socket}
  end

  def handle_event("bookmark_post", %{"post_id" => post_id}, socket) do
    :timer.sleep(500)
    current_user = socket.assigns.current_user
    socket =
      if is_nil(current_user) do
        put_flash(socket, :error, "Please login to bookmark this post")
        |> push_navigate(to: ~p"/sign-in")
      else
        input = %{post: post_id, action: :bookmark}
        user = Map.put(current_user, :roles, [:owner])
        case Ash.create(Monorepo.Accounts.UserPostAction, input, actor: user, action: :create) do
          {:ok, r} ->
            assign(socket, current_user_bookmark: r)
          {:error, _} ->
            put_flash(socket, :error, "Failed to bookmark post")
            |> assign(current_user_bookmark: nil)
        end
      end

    {:noreply, socket}
  end

  def handle_event("unbookmark_post", %{"post_id" => _post_id}, socket) do
    :timer.sleep(500)
    current_user = socket.assigns.current_user
    socket =
      if is_nil(current_user) do
        put_flash(socket, :error, "Please login to bookmark this post")
        |> push_navigate(to: ~p"/sign-in")
      else
        current_user = Map.put(current_user, :roles, [:owner])
        Ash.destroy(socket.assigns.current_user_bookmark, actor: current_user, action: :destroy)
        assign(socket, current_user_bookmark: nil)
      end

    {:noreply, socket}
  end


  defp html_mata(%{assigns: %{post: post}} = socket) do
    media_url = Monorepo.Utilities.Affiliate.affiliate_media_feature_src_with_specific_sizes(post, ["xlarge", "large", "medium"])

    meta_tags = [
      %{property: "og:title", content: post.post_title},
      %{property: "og:description", content: post.post_excerpt},
      %{property: "og:type", content: "article"},
      %{property: "og:image", content: media_url},
      %{name: "twitter:card", content: "summary_large_image"},
      %{name: "twitter:title", content: post.post_title},
      %{name: "twitter:description", content: post.post_excerpt},
      %{name: "twitter:image", content: media_url}
    ]

    assign(socket, :meta_tags, meta_tags)
  end
end
