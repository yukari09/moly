defmodule MonorepoWeb.Plugs.UserMeta do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    if user = conn.assigns[:current_user] do
      user = Monorepo.Accounts.Helper.load_user_meta(user)
      conn
      |> assign(:current_user, user)
    else
      conn
    end
  end
end
