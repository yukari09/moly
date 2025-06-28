defmodule MolyWeb.ColoringPagesController do
  use MolyWeb, :controller

  def home(conn, _params) do
    [_, posts] = Moly.Contents.PostEs.query(post_type: "post", post_status: "publish", per_page: 500, sort: "-updated_at")


    Enum.reduce(posts, [], fn post, acc ->
      [Moly.Helper.get_in_from_keys(post, [:source, "post_tag"]) | acc]
    end)
    |> List.flatten()

    # posts_by_tags =
    #   Enum.group_by(posts, fn post ->
    #     [
    #       Moly.Helper.get_in_from_keys(post, [:source, "post_tag", 0, "slug"]),
    #       Moly.Helper.get_in_from_keys(post, [:source, "post_tag", 0, "name"]),
    #       Moly.Helper.get_in_from_keys(post, [:source, "post_tag", 0, "count"]),
    #     ]
    #   end)
    #   |> Enum.filter(fn {_, posts} -> posts |> Enum.count() > 6 end)
    #   |> Enum.take(20)

    posts_by_tags =
      Enum.group_by(posts, fn post ->
        Moly.Helper.get_in_from_keys(post, [:source, "post_tag"])
      end)
      |> Enum.filter(fn {_, posts} -> Enum.count(posts) >= 6 end)

    render(conn, :home, posts_by_tags: posts_by_tags)
  end

  def tag(conn, %{"tag_slug" => tag_slug} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    per_page = Map.get(params, "per_page", "12") |> String.to_integer()

    [count, posts] =
      Moly.Contents.PostEs.query(post_type: "post", post_status: "publish", page: page, per_page: per_page, sort: "-updated_at", tags: [tag_slug])
      |> case do
        nil -> [0, []]
        [count, items] ->
          [count, items]
      end

    posts_id = Enum.map(posts, &(&1.source["id"]))

    relative =
      Moly.Contents.PostEs.query(post_type: "post", post_status: "publish", page: 1, per_page: 6, sort: "-updated_at", tags: [tag_slug], exclude_id: posts_id)
      |> case do
        nil -> []
        [_, items] -> items
      end


    tag_name =
      hd(posts)
      |> Moly.Helper.get_in_from_keys([:source, "post_tag"])
      |> Enum.filter(fn %{"slug" => slug} -> slug == tag_slug end)
      |> hd()
      |> Moly.Helper.get_in_from_keys(["name"])

    page_meta = Moly.Helper.pagination_meta(count, per_page, page, 5)
    page_title = tag_description = "#{tag_name} #{Moly.website_blog_list_title()}"

    render(conn, :category, posts: posts, relative: relative, page_meta: page_meta, tag_slug: tag_slug, page_title: page_title, page_description: tag_description, category_description: tag_description, category_name: tag_name)
  end

  def browse(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    per_page = Map.get(params, "per_page", "12") |> String.to_integer()

    [count, posts] =
      Moly.Contents.PostEs.query(post_type: "post", post_status: "publish", page: page, per_page: per_page, sort: "-updated_at")
      |> case do
        nil -> [0, []]
        [count, items] ->
          [count, items]
      end

    posts_id = Enum.map(posts, &(&1.source["id"]))

    relative =
      Moly.Contents.PostEs.query(post_type: "post", post_status: "publish", page: 1, per_page: 6, sort: "-updated_at", exclude_id: posts_id)
      |> case do
        nil -> []
        [_, items] -> items
      end

    page_meta = Moly.Helper.pagination_meta(count, per_page, page, 5)
    page_title = Moly.website_blog_list_title()
    page_description = Moly.website_blog_list_description()

    render(conn, :category, posts: posts, relative: relative, page_meta: page_meta, category_name: page_title, page_title: page_title, page_description: page_description)
  end

  def category(conn, %{"category_slug" => category_slug} = params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    per_page = Map.get(params, "per_page", "12") |> String.to_integer()

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

    belong_post_category =
      hd(posts)
      |> Moly.Helper.get_in_from_keys([:source, "category"])
      |> Enum.filter(fn %{"slug" => slug} ->
        slug == category_slug
      end)
      |> hd()

    category_name = belong_post_category["name"]
    category_description = belong_post_category["description"]

    page_meta = Moly.Helper.pagination_meta(count, per_page, page, 5)

    render(conn, :category, posts: posts, relative: relative, page_meta: page_meta, category_slug: category_slug, category_name: category_name, page_title: category_name, page_description: category_description)
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

    ld_json = ld_json(conn, post) |> JSON.encode!()

    render(conn, :view,
      post: post,
      relative: relative,
      page_title: page_title,
      page_description: page_description,
      meta_tags: page_meta,
      ld_json: ld_json
    )
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

  defp ld_json(conn, post) do
    %{
      "@context": "https://schema.org",
      "@type": "BlogPosting",
      "mainEntityOfPage": %{
        "@type": "WebPage",
        "@id": current_url(conn)
      },
      headline: Moly.Helper.get_in_from_keys(post, [:source, "post_title"]),
      image: [
        Moly.Helper.get_in_from_keys(post, [:source, "thumbnail_id", "attachment_metadata", "file"])
      ],
      datePublished: Moly.Helper.get_in_from_keys(post, [:source, "inserted_at"]),
      dateModified: Moly.Helper.get_in_from_keys(post, [:source, "updated_at"]),
      author: %{
        "@type": "Person",
        name: "Coloring Pages for Kids"
      },
      publisher: %{
        "@type": "Organization",
        name: "Coloring Pages for Kids",
        logo: %{
          "@type": "ImageObject",
          url: url(~p"/images/logo.webp"),
          width: 850,
          height: 200
        }
      },
      description: Moly.Helper.get_in_from_keys(post, [:source, "post_excerpt"])
    }
  end
end
