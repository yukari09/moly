defmodule MolyWeb.Affinew.IndexLive do
  use MolyWeb, :live_view

  import MolyWeb.Affinew.Components
  alias MolyWeb.Affinew.Links

  def mount(_params, _session, socket) do
    posts =
      Moly.Utilities.cache_get_or_put(
        "#{__MODULE__}.page.index.cache",
        &MolyWeb.Affinew.QueryEs.index_query/0,
        :timer.hours(12)
      )

    socket =
      assign(socket,
        posts: posts,
        page_title: "Find High Ticket Best Paying Affiliate Marketing Programs in 2025"
      )

    {:ok, socket, layout: false}
  end

  def handle_params(_, _, socket) do
    {:noreply, socket}
  end
end
