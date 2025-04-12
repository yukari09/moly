defmodule MolyWeb.Plugs.GeoBlocking do
  import Plug.Conn

  require Logger

  def init(default), do: default

  def call(conn, default) do
    deny_countries = Keyword.get(default, :deny_countries, [])
    country_code = get_country_code(conn)
    ip = get_ip(conn)
    Logger.info("IP: #{ip}, Country code: #{country_code}.\n")
    if country_code in deny_countries do
      Logger.info("Deny country #{country_code}.\n")
      body = "Oops not found, try later."
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(404, body)
      |> halt()
    else
      conn
    end
  end

  defp get_country_code(conn) do
    conn
    |> Plug.Conn.get_req_header("cf-ipcountry")
    |> List.first()
    |> case do
      nil -> nil
      c -> String.upcase(c)
    end
  end

  def get_ip(conn) do
    get_req_header(conn, "x-forwarded-for")
    |> List.first()
    |> case do
      nil -> nil
      ip ->
        String.split(ip, ",")
        |> List.first()
        |> String.trim()
      end
  end
end
