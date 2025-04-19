defmodule MolyWeb.Account.ConfirmNewUser do
alias Ash.Resource.Validation.Confirm
  use MolyWeb, :live_view

  require Logger
  alias AshAuthentication.Info
  import AshAuthentication.Phoenix.Components.Helpers, only: [auth_path: 5, auth_path: 6]

  def mount(%{"confirm" => confirm}, %{"auth_routes_prefix" => auth_routes_prefix}, socket) do
    {:ok, strategy} = Info.strategy(Moly.Accounts.User, :password)
    subject_name = Info.authentication_subject_name!(strategy.resource)
    action = auth_path(socket, subject_name, auth_routes_prefix, strategy, :sign_in)
    trigger_action = false
    confirm = confirm
    form = generate_form(strategy, subject_name)
    socket =
      assign(socket, form: form, strategy: strategy, subject_name: subject_name, action: action, auth_routes_prefix: auth_routes_prefix, trigger_action: trigger_action, confirm: confirm)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-screen">
      <div class="flex items-end gap-2">
        <a href="/dashboards/ecommerce">
          <img
            class="h-8"
            src="/images/logo.svg"
          />
        </a>
        <span class="text-2xl/7 font-medium text-base-content/70">Affinew</span>
      </div>
      <.form
        for={@form}
        id="confirm-form"
        method="post"
        phx-submit="confirm"
      >
        <input type="hidden" name="" value="" />
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


  def generate_form(strategy, subject_name) do
    context = %{strategy: strategy, private: %{ash_authentication?: true}, token_type: :sign_in}
    AshPhoenix.Form.for_action(strategy.resource, strategy.sign_in_action_name, as: to_string(subject_name), context: context)
  end
end
