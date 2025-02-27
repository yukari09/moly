defmodule MonorepoWeb.PageController do
  use MonorepoWeb, :controller

  require Ash.Query

  def page(conn, %{"post_name" => post_name}) do
    post =
      Ash.Query.filter(Monorepo.Contents.Post, post_name == ^ post_name and post_status == :publish and post_type == :page)
      |> Ash.Query.load([:post_meta])
      |> Ash.read_first!(actor: %{roles: [:user]})

    layout_value = Monorepo.Utilities.Post.post_meta_value(post, :page_layout)

    conn =
      case layout_value do
        v when v in ["1", "true", nil] -> put_layout(conn, html: {MonorepoWeb.Layouts, :app})
        _ -> put_layout(conn, false)
      end

    render(conn, :page, post: post, noappcss: 1, noappscript: 1)
  end
end
