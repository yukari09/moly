defmodule MolyWeb.PageController do
  use MolyWeb, :controller

  require Ash.Query

  def home(conn, _params) do
    posts =
      Moly.Utilities.cache_get_or_put(
        "#{__MODULE__}.page.index.cache",
        &MolyWeb.Affinew.QueryEs.index_query/0,
        :timer.hours(6)
      )

    conn = put_layout(conn, false)
    render(conn, :home, posts: posts, page_title: "Find High Ticket Best Paying affiliate programss in 2025")
  end

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

  def sitemaps(conn, %{"site_map_file" => site_map_file}) do
    path =  ["sitemaps", site_map_file] |> Path.join()

    case Moly.Helper.get_object(path) do
      {:ok, body} ->
        conn
        |> put_resp_content_type("application/xml")
        |> put_resp_header("content-encoding", "gzip")
        |> send_resp(200, body)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Sitemap not found")
        |> redirect(to: "/")
        |> halt()
    end
  end
end
