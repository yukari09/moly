defmodule MonorepoWeb.AdminUserLive do
  use MonorepoWeb, :live_view

  alias Monorepo.Accounts.User

  @impl true
  def handle_params(params, _, socket) do
    case User.list_users(params) do
      {:ok, {users, meta}} ->
        {:noreply, assign(socket, %{users: users, meta: meta})}
      {:error, _meta} ->
        # This will reset invalid parameters. Alternatively, you can assign
        # only the meta and render the errors, or assign the validated params,
        # or you can ignore the error case entirely.
        {:noreply, push_navigate(socket, to: ~p"/admin/users")}
    end
  end

  def render(assigns) do
    ~H"""
    <.table>
    <.table_caption>Your task list.</.table_caption>
    <.table_header>
    <.table_row>
      <.table_head class="w-[100px]">id</.table_head>
      <.table_head>Title</.table_head>
      <.table_head>Status</.table_head>
      <.table_head class="text-right">Action</.table_head>
    </.table_row>
    </.table_header>
    <.table_body>
    <.table_row >
      <.table_cell class="font-medium">1</.table_cell>
      <.table_cell>Buy veg Pizzas</.table_cell>
      <.table_cell>Green meal</.table_cell>
      <.table_cell class="text-right">
        <.link
          navigate={"/content/post"}
          class="btn-action"
        >
            Edit
        </.link>

        <.link
          phx-click={JS.push("delete", value: %{id: 1})}
          data-confirm="Are you sure?"
          class="btn-action"
        >
            Delete
        </.link>
      </.table_cell>
    </.table_row>
    <.table_row >
      <.table_cell class="font-medium">1</.table_cell>
      <.table_cell>Buy 3 apples</.table_cell>
      <.table_cell>Green meal</.table_cell>
      <.table_cell class="text-right">
        <.link
          navigate={"/content/post"}
          class="btn-action"
        >
            Edit
        </.link>

        <.link
          phx-click={JS.push("delete", value: %{id: 2})}
          data-confirm="Are you sure?"
          class="btn-action"
        >
            Delete
        </.link>
      </.table_cell>
    </.table_row>
    </.table_body>
    </.table>

    """
  end


  defp list_users(params, opts \\ []) do
    AshPagify.validate_and_run(User, params, opts)
  end
end
