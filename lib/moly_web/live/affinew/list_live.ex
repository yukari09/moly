defmodule MolyWeb.Affinew.ListLive do
  use MolyWeb, :live_view

  import MolyWeb.Affinew.Components
  import MolyWeb.Affinew.Query

  @per_page 12

  def mount(_params, _session, socket) do
    industries =
      Moly.Utilities.cache_get_or_put("#{__MODULE__}:industries", &industries/0, :timer.hours(1))
      |> Enum.map(&({&1.term.slug, &1.term.name}))

    socket = assign(socket, :industries, industries)
    {:ok, socket, layout: {MolyWeb.Layouts, :affinew}}
  end


  def handle_params(params, _uri, socket) do
    current_params =
      ["page", "sort", "q", "category", "commission", "cookie_duration"]
      |> Enum.reduce(%{}, &(Map.put(&2, &1, Map.get(params, &1))))

    opts =
      opts()
      |> list_pagination(Map.get(params, "page"), @per_page)

    %{results: posts} =
      base()
      |> list_search(current_params["q"])
      |> filter_by_slug(current_params["category"])
      |> read!(opts)

    socket = assign(socket, posts: posts, params: current_params)

    {:noreply, socket}
  end

  def page_title, do: nil

end
