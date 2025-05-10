defmodule MolyWeb.Plugs.WebsiteStatus do
  import Plug.Conn

  require Logger

  def init(default), do: default

  def call(conn, _default) do
    conn
  end
end
