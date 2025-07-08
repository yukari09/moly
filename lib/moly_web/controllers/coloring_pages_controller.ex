defmodule MolyWeb.ColoringPagesController do
  use MolyWeb, :controller

  def home(conn, _params) do
    # Fetch the top 18 tags based on post count
    posts_by_tags =
      Moly.Utilities.cache_get_or_put("#{__MODULE__}:home", fn ->
        %{"top_tags" => %{buckets: buckets}} = Moly.Contents.PostEs.query_top_tags(18, 6)

      Enum.reduce(buckets, %{}, fn %{"doc_count" => doc_count, "key" => tag_slug, "top_docs" => %{"hits" => %{"hits" => posts}}}, acc ->
        posts = Enum.map(posts, & %{source: &1["_source"]})
        key =
          hd(posts)
          |> Moly.Helper.get_in_from_keys([:source, "post_tag"])
          |> Enum.filter(fn %{"slug" => slug} -> slug == tag_slug end)
          |> hd()
          |> Map.put("count", doc_count)
        Map.put(acc, key, posts)
      end)
    end, :timer.hours(2))

    assigns = [
      posts_by_tags: posts_by_tags,
      ld_json: home_ld_json(conn) |> JSON.encode!()
    ]

    render(conn, :home, assigns)
  end

  def list(conn, params) do
    try do
      assigns = _list(params)
      render(conn, :category, assigns)
    rescue
      _ ->
        [ref | _] = get_req_header(conn, "referer")

        put_status(conn, 404)
        |> put_layout(false)
        |> put_view(MolyWeb.ErrorHTML)
        |> render("404.html", redirect_to: ref || "/")
        |> halt()
    end
  end


  defp _list(params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    per_page = Map.get(params, "per_page", "12") |> String.to_integer()

    [identity, identity_value] = case params do
      %{"tag_slug" => tag_slug} -> [:tag_slug, tag_slug]
      %{"category_slug" => category_slug} -> [:category_slug, category_slug]
      _ -> [:browse, nil]
    end

    key = "#{__MODULE__}:#{identity}#{identity_value}:#{page}:#{per_page}"

    Moly.Utilities.cache_get_or_put(key, fn ->
      default_opts = [post_type: "post", post_status: "publish", page: page, per_page: per_page, sort: "-updated_at"]
      filter_opts = case identity do
        :tag_slug -> [tags: [identity_value]]
        :category_slug -> [categories: [identity_value]]
        _ -> []
      end
      opts = default_opts ++ filter_opts
      [count, posts] =
        Moly.Contents.PostEs.query(opts)
        |> case do
          nil -> [0, []]
          [count, items] ->
            [count, items]
        end

      posts_id = Enum.map(posts, &(&1.source["id"]))

      relative =
        Moly.Contents.PostEs.query(opts ++ [exclude_id: posts_id])
        |> case do
          nil -> []
          [_, items] -> items
        end

      [category_name, page_title, page_description, category_description] =
        case identity do
          :tag_slug ->
            tag_name =
              hd(posts)
              |> Moly.Helper.get_in_from_keys([:source, "post_tag"])
              |> Enum.filter(fn %{"slug" => slug} -> slug == identity_value end)
              |> hd()
              |> Moly.Helper.get_in_from_keys(["name"])

            page_title = "#{tag_name} #{Moly.website_blog_list_title()}"
            [tag_name, page_title, page_title, page_title]
          :category_slug ->
            belong_post_category =
              hd(posts)
              |> Moly.Helper.get_in_from_keys([:source, "category"])
              |> Enum.filter(fn %{"slug" => slug} ->
                slug == identity_value
              end)
              |> hd()

            category_name = belong_post_category["name"]
            category_description = belong_post_category["description"]
            [category_name, category_name, category_description, category_description]
          :browse ->
            page_title = Moly.website_blog_list_title()
            page_description = Moly.website_blog_list_description()
            [page_title, page_title, page_description, page_description]
        end

      page_meta = Moly.Helper.pagination_meta(count, per_page, page, 5)
      [posts: posts, relative: relative, page_meta: page_meta, page_title: page_title, category_description: category_description, category_name: category_name, page_description: page_description]
    end, :timer.hours(2))
  end

  def view(conn, %{"post_name" => post_name}) do
    key  = "#{__MODULE__}:#{post_name}"
    assigns = Moly.Utilities.cache_get_or_put(key, fn ->
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
      page_meta = page_meta(post)

      ld_json = view_ld_json(conn, post) |> JSON.encode!()
      [
        post: post,
        relative: relative,
        page_title: page_title,
        meta_tags: page_meta,
        ld_json: ld_json
      ]
    end, :timer.hours(24))

    render(conn, :view, assigns)
  end

  def fixed_slug(conn, %{"fixed_slug" => fixed_slug}) do
    redirect(conn, to: "/@#{fixed_slug}")
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

  defp home_ld_json(_conn) do
    %{
      "@context": "https://schema.org",
      "@type": "WebSite",
      name: "Kid Coloring Page",
      description: "Free printable coloring pages for kids",
      url: "https://kidcoloringpage.com"
    }
  end


  defp view_ld_json(conn, post) do
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
