defmodule MonorepoWeb.AdminUserLive.Index do
  use MonorepoWeb, :live_view

  require Ash.Query

  import Ash.Expr
  import Monorepo.Helper
  import MonorepoWeb.TailwindUI
  import Monorepo.Accounts.Helper

  @per_page "10"
  @context  %{private: %{ash_authentication?: true}}

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: %{role: :admin, status: :active}}} = socket) do
    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/sign-in")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, get_list_by_params(socket, params)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, get_list_by_params(socket, params)}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, get_list_by_params(socket, %{"q" => q})}
  end


  defp get_list_by_params(socket, params) do
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
      actor: %{roles: [socket.assigns.current_user.role]},
      page: [limit: limit, offset: offset, count: true]
    ]

    data = Monorepo.Accounts.User
    data = if is_nil(q) do
      data
    else
      data
      |> Ash.Query.filter(expr(contains(email, ^q)))
    end

    data =
      data
      |> Ash.read!(opts)
      |> Ash.load!([:profile])

    socket =
      socket
      |> assign(:users, data)
      |> assign(:pagination_meta, pagination_meta(data.count, per_page, page, 9))
      |> assign(:params, %{page: page, per_page: per_page, q: q})

    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.header title="Users" description="A list of all the users in your account including their name, title, email and role.">
        <.button class="flex items-center gap-2">
          <.icon name="hero-plus" class="size-4" />
          Add user
        </.button>
      </.header>

      <.form class="mt-8" phx-change="search" phx-submit="search" phx-debounce="300">
        <div class="flex items-center rounded-md bg-white pl-3 outline outline-1 -outline-offset-1 outline-gray-300 has-[input:focus-within]:outline has-[input:focus-within]:outline-2 has-[input:focus-within]:-outline-offset-2 has-[input:focus-within]:outline-gray-600">
          <Lucideicons.search class="size-4 text-gray-400" />
          <input type="text" name="q" id="search-input" class="block min-w-0 grow py-1.5 pl-1 pr-3 text-base text-gray-900 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" placeholder="Search">
        </div>
      </.form>
      <div class="mt-8 flow-root" :if={@users.results != []}>
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
          <.table
            rows={@users.results}
            class="divide-y divide-gray-300"
          >
            <:col :let={row} label="Name">
              <div class="flex items-center">
                <div class="size-11 shrink-0">
                  <.avatar class="!size-11">
                    <.avatar_image src={current_user_avatar(row)} alt={current_user_name(row)} />
                    <.avatar_fallback initials={current_user_short_name(row)} />
                  </.avatar>
                </div>
                <div class="ml-4">
                  <div class="font-medium text-gray-900"><%= current_user_name(row) %></div>
                  <div class="mt-1 text-gray-500"><%= row.email %></div>
                </div>
              </div>
            </:col>

            <:col :let={row} label="Status">
              <.badge variant={%{active: "success", inactive: "danger", pending: "warning", deleted: "error"}[row.status]} label={row.status}>
                {row.status}
              </.badge>
            </:col>

            <:col :let={row} label="Role">
              <%= row.role %>
            </:col>

            <:col :let={row} label="Created At">
              <%= row.inserted_at |> Timex.format!("{Mfull} {D}, {YYYY} {h24}:{m}") %>
            </:col>

            <:col :let={row} label="Actions">
              <div class="flex gap-2 max-w-[60px]">
              <.tooltip text="Activate" size="xs">
                <a href="#" class="group" role="menuitem" tabindex="-1" id="menu-item-0">
                  <.icon name="hero-key" class="size-5 text-gray-500 group-hover:text-gray-700" />
                </a>
                </.tooltip>
                <.tooltip text="Delete" size="xs">
                  <a href="#" class="group" role="menuitem" tabindex="-1" id="menu-item-2">
                    <.icon name="hero-trash" class="size-5 text-gray-500 group-hover:text-gray-700" />
                  </a>
                </.tooltip>
              </div>
            </:col>
          </.table>
          </div>
        </div>
      </div>
    </div>

    <.modal>
      <div>
        <div class="mx-auto flex size-12 items-center justify-center rounded-full bg-green-100">
          <svg class="size-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" data-slot="icon">
            <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
          </svg>
        </div>
        <div class="mt-3 text-center sm:mt-5">
          <h3 class="text-base font-semibold text-gray-900" id="modal-title">Payment successful</h3>
          <div class="mt-2">
            <p class="text-sm text-gray-500">Lorem ipsum dolor sit amet consectetur adipisicing elit. Consequatur amet labore.</p>
          </div>
        </div>
      </div>
      <div class="mt-5 sm:mt-6">
        <button type="button" class="inline-flex w-full justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-indigo-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">Go back to dashboard</button>
      </div>
    </.modal>
    """
  end
end
