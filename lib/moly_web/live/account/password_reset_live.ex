defmodule MolyWeb.Account.PasswordResetLive do
  use MolyWeb, :live_view

  require Logger

  import AshAuthentication.Phoenix.Components.Helpers, only: [auth_path: 5]

  def mount(%{"token" => token}, _session, socket) do
    {:ok, strategy} = AshAuthentication.Info.strategy(Moly.Accounts.User, :password)
    action = auth_path(socket, :password_reset_with_password, "/auth", strategy, :reset)
    sitekey = Application.get_env(:moly, :cf_website_secret)
    form = generate_form(token)
    {:ok, assign(socket, form: form,action: action, trigger_submit: false, sitekey: sitekey, scripts: [~p"/assets/live.js"])}
  end

  def handle_event("save", %{"user" => params, "cf-turnstile-response"=>cf_turnstile_response}, socket) when cf_turnstile_response not in [nil, "", false] do
    socket =
      if Moly.Helper.validate_cf(cf_turnstile_response) === :ok do
        form = AshPhoenix.Form.validate(socket.assigns.form, params)
        assign(socket, form: form, trigger_submit: form.valid?)
      else
        socket
      end
    {:noreply, socket}
  end

  def generate_form(token) do
    context = %{private: %{ash_authentication?: true}}
    AshPhoenix.Form.for_action(
      Moly.Accounts.User,
      :password_reset_with_password,
      forms: [auto?: true],
      as: "user",
      context: context,
      prepare_source: fn changeset ->
        Ash.Changeset.set_arguments(changeset, %{
          reset_token: token
        })
      end,
      context: context
    )
  end
end
