defmodule MolyWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """
  use MolyWeb, :verified_routes

  import Phoenix.Component
  import Phoenix.LiveView, only: [redirect: 2]

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, redirect(socket, to: ~p"/")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_admin_required, _params, _session, socket), do: check_roles(socket)


  defp check_roles(%{assigns: %{current_user: %{roles: roles, status: :active}}} = socket) do
    if Enum.member?(roles, :admin) do
      {:cont, assign(socket, :asset_name, :admin)}
    else
      socket = redirect(socket, to: ~p"/sign-in")
      {:halt, socket}
    end
  end

  defp check_roles(socket), do: {:halt, redirect(socket, to: ~p"/sign-in")}
end
