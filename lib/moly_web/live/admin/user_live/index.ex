defmodule MolyWeb.AdminUserLive.Index do
  use MolyWeb.Admin, :live_view

  import Moly.Utilities.Account

  @per_page "10"
  @model Moly.Accounts.User
  @context %{private: %{ash_authentication?: true}}

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, get_list_by_params(socket, params)}
  end

  @impl true
  def handle_event(event_name, params, socket) do
    live_action = String.to_atom(event_name)

    socket =
      socket
      |> assign(:live_action, live_action)
      |> handle_action(live_action, params)

    {:noreply, socket}
  end

  defp handle_action(socket, :search, %{"q" => q}), do: get_list_by_params(socket, %{"q" => q})

  defp handle_action(socket, :new, _) do
    form =
      @model
      |> AshPhoenix.Form.for_create(:create_manually, forms: [auto?: true])
      |> to_form()

    socket
    |> assign(:page_title, "Create User")
    |> assign(:form, form)
  end

  defp handle_action(socket, :validate, %{"form" => params}) do
    socket
    |> assign(form: AshPhoenix.Form.validate(socket.assigns.form, params))
  end

  defp handle_action(socket, :save, %{"form" => params}) do
    :timer.sleep(250)
    # old_live_action = socket.assigns.live_action

    case AshPhoenix.Form.submit(
           socket.assigns.form,
           params: params,
           action_opts: [context: @context]
         ) do
      {:ok, user} ->
        socket
        |> put_flash(:info, "Saved user for #{user.email}!")
        |> push_patch(to: generate_live_url(%{socket.assigns.params | page: 1}), replace: true)
        |> assign(:live_action, :index)

      {:error, form} ->
        socket
        |> assign(form: form)
        |> assign(:live_action, :edit)
    end
  end

  defp handle_action(socket, :activate, %{"id" => id}) do
    Ash.get!(@model, id, context: @context)
    |> Ash.update!(%{status: :active}, action: :update_user_status, context: @context)

    socket
    |> push_navigate(to: generate_live_url(socket.assigns.params))
  end

  defp handle_action(socket, :inactivate, %{"id" => id}) do
    Ash.get!(@model, id, context: @context)
    |> Ash.update!(%{status: :inactive}, action: :update_user_status, context: @context)

    socket
    |> push_navigate(to: generate_live_url(socket.assigns.params))
  end

  defp handle_action(socket, :delete, %{"id" => id}) do
    Ash.get!(@model, id, context: @context)
    |> Ash.update!(%{status: :deleted}, action: :update_user_status, context: @context)

    socket
    |> push_navigate(to: generate_live_url(socket.assigns.params))
  end

  defp get_list_by_params(socket, params) do
    current_user = socket.assigns.current_user

    page =
      Map.get(params, "page", "1")
      |> String.to_integer()

    per_page =
      Map.get(params, "per_page", @per_page)
      |> String.to_integer()

    q =
      Map.get(params, "q", "")
      |> case do
        "" -> nil
        q -> q
      end

    limit = per_page
    offset = (page - 1) * per_page

    opts = [
      context: @context,
      actor: current_user,
      page: [limit: limit, offset: offset, count: true]
    ]

    data =
      if is_nil(q) do
        @model
      else
        @model
        |> Ash.Query.filter(expr(contains(email, ^q)))
      end

    data =
      data
      |> Ash.read!(opts)
      |> Ash.load!([:user_meta])

    socket =
      socket
      |> assign(:users, data)
      |> assign(:page_meta, pagination_meta(data.count, per_page, page, 9))
      |> assign(:params, %{page: page, per_page: per_page, q: q})

    socket
  end

  defp generate_live_url(query_params) when is_map(query_params) do
    ~p"/admin/users?#{query_params}"
  end
end
