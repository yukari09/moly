defmodule MolyWeb.Account.SignInLive do
  use MolyWeb, :live_view

  require Logger
  alias AshAuthentication.Info
  import AshAuthentication.Phoenix.Components.Helpers, only: [auth_path: 5, auth_path: 6]

  def mount(params, %{"auth_routes_prefix" => auth_routes_prefix}, socket) do
    {:ok, strategy} = Info.strategy(Moly.Accounts.User, :password)
    subject_name = Info.authentication_subject_name!(strategy.resource)
    form = generate_form(strategy, subject_name)
    action = auth_path(socket, subject_name, auth_routes_prefix, strategy, :sign_in)
    trigger_action = false
    dev_mod = Map.get(params, "dev_mod", false)
    sitekey = dev_mod && "1x00000000000000000000AA" || Application.get_env(:moly, :cf_website_secret)
    socket =
      assign(socket,
      form: form,
      strategy: strategy,
      subject_name: subject_name,
      action: action,
      auth_routes_prefix: auth_routes_prefix,
      trigger_action: trigger_action,
      sitekey: sitekey, dev_mod: dev_mod,
      scripts: [~p"/assets/live.js"]
    )
    {:ok, socket}
  end

  def handle_event("sign-in", %{"cf-turnstile-response"=>cf_turnstile_response} = params, socket) when cf_turnstile_response not in [nil, "", false] do
    login_params = Map.get(params, to_string(socket.assigns.subject_name))
    request_cf = Moly.Helper.validate_cf(cf_turnstile_response, socket.assigns.dev_mod)
    socket =
      if request_cf === :ok do
        submit_form = AshPhoenix.Form.submit(socket.assigns.form, params: login_params, read_one?: true)
        case submit_form do
          {:ok, user} ->
            validate_sign_in_token_path = auth_path(
              socket,
              :sign_in,
              socket.assigns.auth_routes_prefix,
              socket.assigns.strategy,
              :sign_in_with_token,
              token: user.__metadata__.token
            )
            redirect(socket, to: validate_sign_in_token_path)
          {:error, form} ->
            socket
            |> put_flash(:error, "Invalid credentials")
            |> assign(:form, form)
        end
      else
        socket
      end

    {:noreply, socket}
  end

  def generate_form(strategy, subject_name) do
    context = %{strategy: strategy, private: %{ash_authentication?: true}, token_type: :sign_in}
    AshPhoenix.Form.for_action(strategy.resource, strategy.sign_in_action_name, as: to_string(subject_name), context: context)
  end
end
