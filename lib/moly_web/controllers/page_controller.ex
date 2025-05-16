defmodule MolyWeb.PageController do
  use MolyWeb, :controller

  def home(conn, _params) do
    [_count, posts] =
      Moly.Contents.PostEs.query(post_type: "post", post_status: "publish", per_page: 60, sort: "-updated_at")
      |> case do
        nil -> [0, []]
        [count, items] ->
          items = Enum.filter(items, &(Moly.Helper.get_in_from_keys(&1, [:source, "thumbnail_id", "attached_file"])))
          [count, items]
      end
    render(conn, :home, posts: posts)
  end

  def category(conn, %{"category_slug" => category_slug} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    per_page = Map.get(params, "per_page", "10") |> String.to_integer()

    [count, posts] =
      Moly.Contents.PostEs.query(post_type: "post", post_status: "publish", page: page, per_page: per_page, sort: "-updated_at", categories: [category_slug])
      |> case do
        nil -> [0, []]
        [count, items] ->
          [count, items]
      end

    posts_id = Enum.map(posts, &(&1.source["id"]))

    relative =
      Moly.Contents.PostEs.query(post_type: "post", post_status: "publish", page: 1, per_page: 6, sort: "-updated_at", categories: [category_slug], exclude_id: posts_id)
      |> case do
        nil -> []
        [_, items] -> items
      end

    category_name = hd(posts) |> Moly.Helper.get_in_from_keys([:source, "category", 0, "name"])

    page_meta = Moly.Helper.pagination_meta(count, per_page, page, 3)
    page_title = "#{category_name} #{Moly.website_blog_list_title()}"
    page_description = "#{category_name} #{Moly.website_blog_list_description()}"

    render(conn, :category, posts: posts, relative: relative, page_meta: page_meta, category_slug: category_slug, page_title: page_title, page_description: page_description)
  end

  def view(conn, %{"post_name" => post_name}) do
    post =
      Moly.Contents.PostEs.query_document_by_post_name(post_name)
      |> case do
        nil -> nil
        [_, [post | _]] -> post
      end

    relative =
      Moly.Helper.get_in_from_keys(post, [:source, "id"])
      |> Moly.Contents.PostEs.relative_posts(6)
      |> case do
        nil -> []
        [_, posts] -> posts
      end

    page_title = "#{Moly.Helper.get_in_from_keys(post, [:source, "post_title"])}"
    page_description = "#{Moly.Helper.get_in_from_keys(post, [:source, "post_excerpt"])}"
    page_meta = page_meta(post)

    render(conn, :view, post: post, relative: relative, page_title: page_title, page_description: page_description, meta_tags: page_meta)
  end


  defp page_meta(%{source: %{"post_title" => post_title, "post_excerpt" => post_excerpt, "thumbnail_id" => %{"attached_file" => attached_file}}}) do
    media_url = Moly.Helper.image_resize(attached_file, 1200, 630)

    [
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
  end
end
