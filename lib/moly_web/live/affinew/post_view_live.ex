defmodule MolyWeb.Affinew.PostViewLive do
  use MolyWeb, :live_view

  import MolyWeb.Affinew.Components

  def mount(%{"post_name" => post_name}, _session, socket) do
    [post, author, related_posts] =
      Moly.Utilities.cache_get_or_put(
        "#{__MODULE__}.affiliate.post.index.cache.#{post_name}",
        fn ->
          post = view_query(post_name)
          author_id = Moly.Helper.get_in_from_keys(post, [:source, "author_id"])

          author =
            Moly.Utilities.Account.get_users_by_id([author_id])
            |> Map.get(author_id)

          [_, relative] = if rp = relative_posts(post, 6), do: rp, else: [nil, []]

          [post, author, relative || []]
        end,
        :timer.hours(1)
      )
    socket =
      assign(socket, post: post, author: author, related_posts: related_posts)
      |> page_meta()

    {:ok, socket, layout: {MolyWeb.Layouts, :affinew}}
  end

  defp view_query(post_name) do
    query = %{
      query: %{
        bool: %{
          must: [
            %{term: %{"post_name.keyword" => post_name}},
            %{term: %{"post_status.keyword" => "publish"}}
          ]
        }
      }
    }
    Moly.Helper.es_query_result(
      Moly.Cluster,
      Moly.Contents.Notifiers.Post.index_name(),
      query
    )
    |> case do
      nil -> nil
      [_, [post | _]] -> post
    end
  end

  defp relative_posts(post, size) do
    query = %{
      query: %{
        bool: %{
          must: [
            %{term: %{post_status: "publish"}},
            %{term: %{post_type: "post"}},
            %{
              more_like_this: %{
                fields: [:post_title, :post_content],
                like: %{
                  _index: Moly.Contents.Notifiers.Post.index_name(),
                  _id: post.id
                },
                min_term_freq: 1,
                max_query_terms: 12
              }
            }
          ]
        }
      },
      size: size
    }
    Moly.Helper.es_query_result(Moly.Cluster, Moly.Contents.Notifiers.Post.index_name(), query)
  end


  defp page_meta(%{assigns: %{post: post}} = socket) do
    media_url = post_featrue_image_src(post)
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
