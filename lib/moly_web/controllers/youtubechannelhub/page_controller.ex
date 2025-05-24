defmodule MolyWeb.YoutubeChannelHub.PageController do
  use MolyWeb, :controller

  def index(conn, _params) do
    conn = put_layout(conn, false)
    render conn, :index, []
  end

end
