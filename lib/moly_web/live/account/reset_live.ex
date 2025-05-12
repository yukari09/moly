defmodule MolyWeb.Account.ResetLive do
  use MolyWeb, :live_view

  require Logger

  def mount(_params, _session, socket) do
    form = generate_form()
    sitekey = Application.get_env(:moly, :cf_website_secret)
    {:ok, assign(socket, form: form, sitekey: sitekey, scripts: [~p"/assets/live.js"])}
  end

  def handle_event("reset", %{"form" => params, "cf-turnstile-response"=>cf_turnstile_response}, socket) when cf_turnstile_response not in [nil, "", false] do
    socket =
      if Moly.Helper.validate_cf(cf_turnstile_response) === :ok do
        AshPhoenix.Form.submit(socket.assigns.form, params: params)
        socket |> put_flash(:info, "Password reset request sent, if you have an account with us, please check your email.")
      else
        socket
      end
    socket = push_navigate(socket, to: ~p"/reset")
    {:noreply, socket}
  end


  def generate_form() do
    context = %{private: %{ash_authentication?: true}}
    AshPhoenix.Form.for_action(Moly.Accounts.User, :request_password_reset_with_password, forms: [auto?: true], context: context)
  end
end
