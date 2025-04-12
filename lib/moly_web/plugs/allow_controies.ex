defmodule MolyWeb.Plugs.AllowControies do
  import Plug.Conn

  require Logger

  def init(default), do: default

  def call(conn, _default) do

    deny_country = []

    country_code =
      Plug.Conn.get_req_header(conn,"cf-ipcountry")
      |> List.first()
      |> case do
        nil -> nil
        c -> String.upcase(c)
      end
    Logger.info("Contry code #{country_code}.\n")
    if country_code in deny_country do
      body = "Oops not found, try later."
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(404, body)
      |> halt
    else
      conn
    end

  end
end
