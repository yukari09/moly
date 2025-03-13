defmodule MolyWeb.PageController do
  use MolyWeb, :controller

  require Ash.Query

  def page(conn, %{"post_name" => post_name}) do
    post =
      Ash.Query.filter(
        Moly.Contents.Post,
        post_name == ^post_name and post_status == :publish and post_type == :page
      )
      |> Ash.Query.load([:post_meta])
      |> Ash.read_first!(actor: %{roles: [:user]})

    layout_value = Moly.Utilities.Post.post_meta_value(post, :page_layout)

    conn =
      case layout_value do
        v when v in ["1", "true", nil] -> put_layout(conn, html: {MolyWeb.Layouts, :app})
        _ -> put_layout(conn, false)
      end

    render(conn, :page, post: post, noappcss: 1, noappscript: 1)
  end
end
