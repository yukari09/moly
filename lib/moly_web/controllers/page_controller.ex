defmodule MolyWeb.PageController do
  use MolyWeb, :controller

  def home(conn, _params) do
    render(conn, :home, [])
  end
end
