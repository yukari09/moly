defmodule MolyWeb.Affinew.IndexLive do
  use MolyWeb, :live_view

  import MolyWeb.Affinew.Components
  alias MolyWeb.Affinew.Links

  def mount(_params, _session, socket) do
    %{results: posts} =
      Moly.Utilities.cache_get_or_put("#{__MODULE__}.page.index.cache", &MolyWeb.Affinew.Query.index_query/0, :timer.hours(24))

    socket = assign(socket, :posts, posts)

    {:ok, socket, layout: false}
  end

  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  defp nav_categories() do
    [
      {"Browse", Links.programs()},
      {"Categories", Links.under_construction()},
      {"News", Links.under_construction()},
      {"Resources", Links.under_construction()},
    ]
  end
end
