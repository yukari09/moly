defmodule MolyWeb.Affinew.ViewLive do
  use MolyWeb, :live_view

  require Ash.Query

  alias Moly.Contents.Notifiers.Post

  import MolyWeb.Affinew.Components

  def mount(_params, _session, socket) do
    {:ok, socket, layout: {MolyWeb.Layouts, :affinew}}
  end

  def handle_params(%{"post_name" => post_name}, _uri, socket) do
    {:ok, post} =
      Snap.Search.search(Moly.Cluster, Post.index_name(), %{
        query: %{term: %{"post_name.keyword" => post_name}}
      })

    post = Moly.Helper.get_in_from_keys(post, [:hits, :hits, 0])

    {:ok, posts} =
      Snap.Search.search(Moly.Cluster, Post.index_name(), %{
        query: %{
          more_like_this: %{
            fields: [:post_title, :post_content],
            like: %{
              _index: Post.index_name(),
              _id: post.id
            },
            min_term_freq: 1,
            max_query_terms: 12
          }
        },
        size: 12
      })

    socket = assign(socket, post: post, posts: posts)
    {:noreply, socket}
  end
end
