defmodule MolyWeb.SitemapController do
  use MolyWeb, :controller

  require Ash.Query

  def show(conn, %{"site_map_file" => site_map_file}) do
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
