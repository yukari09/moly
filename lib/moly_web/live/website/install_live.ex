defmodule MolyWeb.Website.RegisterInitialUser do
alias Hex.API.User
  use MolyWeb, :live_view

  require Logger
  require Ash.Query
  alias Moly.Terms.Term
  alias Moly.Accounts.User

  @actor  %{roles: [:admin]}
  @context %{private: %{ash_authentication?: true}}

  def mount(_params, _url, socket) do

    [has_user, web_status] = [has_user?(), Moly.website_status]

    socket =
      if web_status != "pending" || has_user do
        push_navigate(socket, to: ~p"/")
      else
        socket
      end

    socket = prepate_intiation(socket)
    {:ok, socket, layout: false, temporary_assigns: [scripts: [~p"/assets/live.js"]]}
  end

  def handle_event("save", %{"form" => form_params}, socket) do
    socket =
      case AshPhoenix.Form.submit(socket.assigns.form, params: form_params, action_opts: [context: @context]) do
        {:error, form} ->
          put_flash(socket, :error, JSON.encode!(form.errors))
        {:ok, _} ->
          push_navigate(socket, to: ~p"/sign-in")
      end
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <MolyWeb.MolyComponents.flash_group flash={@flash} id="website-create-initial-user"  />
    <div class="flex flex-col justify-center min-h-[100vh] shadow">
      <div class="min-w-sm mx-auto bg-white px-10 pt-12 pb-16">
        <div><img class="h-8 w-auto mx-auto" src={Moly.website_logo} /></div>
        <h1 class="font-semibold text-xl pb-4 border-b border-gray-200 mt-8 text-center">Create a admin user</h1>
        <div class="mt-4 space-y-8 divide-y divide-gray-100">
        <.form :let={f} for={@form} class="space-y-4" phx-submit="save">
          <fieldset class="fieldset">
            <legend class="fieldset-legend">Email</legend>
            <input type="email" class="input" name={f[:email].name} value={f[:email].value} placeholder="Email" />
          </fieldset>
          <fieldset class="fieldset">
            <legend class="fieldset-legend">Email</legend>
            <input type="password" class="input" name={f[:password].name} value={f[:password].value} placeholder="Password" />
          </fieldset>
          <input name={f[:status].name} value={:active} class="hidden" />
          <input name={f[:confirmed_at].name} value={DateTime.utc_now()} class="hidden" />
          <input name={f[:roles].name<>"[0]"} value={:admin} class="hidden" />
          <div class="flex items-center justify-items-center flex-col">
            <button class="w-full mt-4 btn btn-primary">Create</button>
          </div>
        </.form>
        </div>
      </div>
    </div>
    """
  end

  defp prepate_intiation(socket) do
    initiation_data = Moly.default_config_term_data() ++ Moly.default_website_term_data()
    slugs = Enum.map(initiation_data, &(&1.slug))
    existed_data = existed_terms_data_by_slug(slugs)
    total_data = Enum.count(initiation_data)
    total_existed_data = Enum.count(existed_data)

    if total_data != total_existed_data do
      Logger.info("Re-install initiation data.")
      term_upsert(initiation_data)
    end

    form = AshPhoenix.Form.for_create(User, :create_manually, form: [auto?: true])

    assign(socket, :form, form)
  end

  defp has_user?() do
    count = Ash.Query.new(User) |> Ash.count!()
    count > 0
  end

  defp existed_terms_data_by_slug(slugs) when is_list(slugs) do
    Ash.Query.new(Term)
    |> Ash.Query.filter(slug in ^slugs)
    |> Ash.Query.load([:term_taxonomy, :term_meta])
    |> Ash.read!(actor: @actor)
  end

  defp term_upsert(inputs) when is_list(inputs) do
    Enum.map(inputs, &term_upsert(&1))
  end

  defp term_upsert(%{name: name, slug: slug} = input) when is_map(input) do
    has_one? = Ash.Query.filter(Term, slug == ^ slug) |> Ash.exists?(actor: @actor)
    if has_one? do
      Logger.warning("The record of slug about \"#{slug}\", is exitsed.")
    else
      Logger.info("Insert to Table<terms>: name \"#{name}\", slug: \"#{slug}\".")
      Ash.create(Term, input, actor: @actor, action: :create, identity: :unique_slug)
    end
  end
end
