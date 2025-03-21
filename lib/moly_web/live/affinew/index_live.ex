defmodule MolyWeb.Affinew.IndexLive do
  use MolyWeb, :live_view

  require Ash.Query

  def mount(_params, _session, socket) do
    opts = [
      action: :read,
      actor: %{roles: [:user]},
      page: [limit: 12, offset: 0, count: true]
    ]

    cache_function = fn ->
      Ash.Query.new(Moly.Contents.Post)
      |> Ash.Query.filter(post_type == :affiliate and post_status in [:publish])
      |> Ash.Query.load([
        :affiliate_tags,
        :affiliate_categories,
        author: :user_meta,
        post_meta: :children
      ])
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.read!(opts)
    end

    %{results: posts} =
      Moly.Utilities.cache_get_or_put("page.index.cache", cache_function, :timer.hours(2))

    # {MolyWeb.Layouts, :affinew}
    {:ok, socket, temporary_assigns: [posts: posts], layout: false}
  end
end
