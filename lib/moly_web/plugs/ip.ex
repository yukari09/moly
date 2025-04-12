defmodule MolyWeb.Plugs.Ip do
  import Plug.Conn

  require Logger

  def init(default), do: default

  def call(conn, _params) do
    user_ip = get_req_header(conn, "x-forwarded-for")
    |> List.first()
    |> String.split(",")
    |> List.first()
    |> String.trim()
    Logger.info("User IP: #{user_ip}")
    conn
  end
end
