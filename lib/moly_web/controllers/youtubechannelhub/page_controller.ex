defmodule MolyWeb.YoutubeChannelHub.PageController do
  use MolyWeb, :controller

  def index(conn, _params) do
    conn = put_layout(conn, false)
    page_title = "Youtube Thumbnail Viewer And Downloader"
    page_description = "Find youtube thumbnail high-quality thumbnails from any YouTube video in seconds. Professional tools for content creators, bloggers, and digital marketers #{DateTime.utc_now() |> Map.get(:year)}. "
    render conn, :index, [page_title: page_title, page_description: page_description]
  end


  def calculator(conn, _params) do
    conn = put_layout(conn, false)
    page_title = "Youtube Income Estimator PRO"
    page_description = "Youtube Income Estimator PRO, Professional Youtube Money Calculator for content creators, bloggers, and digital marketers #{DateTime.utc_now() |> Map.get(:year)}. "
    render conn, :calculator, [page_title: page_title, page_description: page_description]
  end
end
