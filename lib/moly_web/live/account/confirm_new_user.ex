defmodule MolyWeb.Account.ConfirmNewUser do

  use MolyWeb, :live_view

  require Logger
  alias AshAuthentication.Info
  import AshAuthentication.Phoenix.Components.Helpers, only: [auth_path: 5]
  import Slug

  def mount(%{"confirm" => confirm}, %{"auth_routes_prefix" => auth_routes_prefix}, socket) do
    {:ok, strategy} = Info.strategy(Moly.Accounts.User, :confirm_new_user)
    subject_name = Info.authentication_subject_name!(strategy.resource)

    sitekey = Application.get_env(:moly, :cf_website_secret)

    form =
      strategy.resource
      |> AshPhoenix.Form.for_action(strategy.confirm_action_name,
        as: subject_name |> to_string(),
        tenant: socket.assigns.current_tenant,
        id:
          "#{subject_name}-#{strategy.name}-#{strategy.confirm_action_name}"
          |> slugify(),
        context: %{strategy: strategy, private: %{ash_authentication?: true}}
      )

    socket = assign(socket, form: form, subject_name: subject_name, auth_routes_prefix: auth_routes_prefix, strategy: strategy, confirm: confirm, sitekey: sitekey)

    {:ok, socket}
  end


  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-screen">
      <div class="flex items-end gap-2">
        <a href="/dashboards/ecommerce">
          <img
            class="h-8"
            src="/images/logo.svgz"
          />
        </a>
        <span class="text-2xl/7 font-medium text-base-content/70">Affinew</span>
      </div>
      <.form
        for={@form}
        id={@form.id}
        method="POST"
        phx-change="update"
        action={auth_path(@socket, @subject_name, @auth_routes_prefix, @strategy, :confirm)}
      >
        <input type="hidden" name="confirm" value={@confirm} />
        <button
          id="sign-in-btn"
          class={["btn btn-primary btn-wide mt-4 max-w-full gap-3 md:mt-6"]}
          data-discover="true"
        >
          Confirm your email
        </button>
      </.form>
    </div>
    """
  end




end
