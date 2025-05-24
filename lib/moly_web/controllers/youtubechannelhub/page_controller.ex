defmodule MolyWeb.YoutubeChannelHub.PageController do
  use MolyWeb, :controller

  def index(conn, _params) do
    conn = put_layout(conn, false)
    page_title = "Youtube Thumbnail Viewer And Downloader"
    page_description = "Extract high-quality thumbnails from any YouTube video in seconds. Professional tools for content creators, bloggers, and digital marketers. "
    render conn, :index, [page_title: page_title, page_description: page_description]
  end

end
