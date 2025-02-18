defmodule MonorepoWeb.Affiliate.ProductViewLive do
  use MonorepoWeb, :live_view
  require Ash.Query

  def mount(_params, _session, socket) do
    country_category = Monorepo.Terms.read_by_term_slug!("countries", actor: %{roles: [:user]}) |> List.first()
    industry_category = Monorepo.Terms.read_by_term_slug!("industries", actor: %{roles: [:user]}) |> List.first()

    socket =
      socket
      |> assign(country_category: country_category, industry_category: industry_category)
    {:ok, socket}
  end

  def handle_params(%{"post_name" => post_name}, _uri, socket) do
    opts = [
      actor: %{roles: [:user]},
      context: %{private: %{ash_authentication?: true}}
    ]

    post =
      Ash.Query.for_read(Monorepo.Contents.Post, :read)
      |> Ash.Query.filter(post_name == ^post_name)
      |> Ash.Query.load([:post_categories, :post_tags, author: :user_meta, post_meta: :children])
      |> Ash.read!(opts)
      |> List.first()

    socket = assign(socket, :post, post)
    {:noreply, socket}
  end

end
