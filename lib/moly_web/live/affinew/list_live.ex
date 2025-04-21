defmodule MolyWeb.Affinew.ListLive do
  use MolyWeb, :live_view

  import MolyWeb.Affinew.Components
  import MolyWeb.Affinew.QueryEs

  @per_page 18

  def mount(_params, _session, socket) do
    industry_options =
      Moly.Utilities.cache_get_or_put("#{__MODULE__}:industries", &industries/0, :timer.hours(1))
      |> Enum.map(&{&1.term.slug, &1.term.name})

    socket =
      assign(
        socket,
        industry_options: industry_options,
        commission_options: commission_options(),
        cookie_duration_options: cookie_duration_options(),
        payment_cycle_options: payment_cycle_options(),
        sort_options: sort_options()
      )

    {:ok, socket, layout: {MolyWeb.Layouts, :affinew}}
  end

  def handle_params(params, _uri, socket) do
    current_params =
      ["page", "sort", "q", "category", "commission", "cookie-duration", "payment-cycle"]
      |> Enum.reduce(%{}, fn param, a1 ->
        param_value = Map.get(params, param)

        if param_value != "" do
          Map.put(a1, param, param_value)
        else
          Map.put(a1, param, nil)
        end
      end)

    options =
      Enum.reduce(current_params, %{}, fn {option, option_value}, a1 ->
        if option_value not in [false, "", nil] do
          case option do
            "category" ->
              value = to_option_value(socket.assigns.industry_options, option_value)
              Map.put(a1, option, value)

            "commission" ->
              value = to_option_value(socket.assigns.commission_options, option_value)
              Map.put(a1, option, value)

            "payment-cycle" ->
              value = to_option_value(socket.assigns.payment_cycle_options, option_value)
              Map.put(a1, option, value)

            "cookie-duration" ->
              value = to_option_value(socket.assigns.cookie_duration_options, option_value)
              Map.put(a1, option, value)

            _ ->
              a1
          end
        else
          a1
        end
      end)

    page = (current_params["page"] && String.to_integer(current_params["page"])) || 1

    {count, posts} = list_query(current_params, @per_page)
    page_meta = Moly.Helper.pagination_meta(count, @per_page, page, 5)

    socket =
      assign(socket, posts: posts, params: current_params, page_meta: page_meta, options: options)
      |> page_title()

    {:noreply, socket}
  end

  defp page_title(socket) do
    category_name = Map.get(socket.assigns.options, "category")
    category_name = category_name && category_name<>" " || ""
    dt = Date.utc_today()
    assign(socket, :page_title, "#{category_name}High Ticket Best Paying Affiliate Programs You Must Be Know in #{dt.year}")
  end

  defp to_option_value(options, option_value) do
    Enum.find(options, &(elem(&1, 0) == option_value))
    |> case do
      nil -> nil
      {_, label} -> label
    end
  end
end
