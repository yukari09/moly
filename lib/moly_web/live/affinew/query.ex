defmodule MolyWeb.Affinew.Query do
  require Ash.Query

  def opts, do: [
    action: :read,
    actor: %{roles: [:user]},
    page: [limit: 12, offset: 0, count: true]
  ]

  def base() do
    Ash.Query.new(Moly.Contents.Post)
      |> Ash.Query.filter(post_type == :affiliate and post_status in [:publish])
      |> Ash.Query.load([
        :affiliate_tags,
        :affiliate_categories,
        author: :user_meta,
        post_meta: :children
      ])
  end

  def read!(query, opts), do: Ash.read!(query, opts)

  def index_query() do
    base_query = base()
    base_query
    |> Ash.Query.sort(inserted_at: :desc)
    |> read!(opts())
  end

  def list_pagination(opts, page, per_page) when is_binary(page) do
    page = String.to_integer(page)
    list_pagination(opts, page, per_page)
  end
  def list_pagination(opts, page, per_page) when is_integer(page) do
    put_in(opts, [:page, :offset], (page - 1) * per_page)
    |> put_in([:page, :limit], per_page)
  end
  def list_pagination(opts, nil, per_page) do
    put_in(opts, [:page, :offset], 0)
    |> put_in([:page, :limit], per_page)
  end


  def list_search(query, ""), do: query
  def list_search(query, nil), do: query
  def list_search(query, q), do: Ash.Query.set_argument(query, :search_text, q)

  def list_sort(query, "-"<>field) do
    sort = Keyword.put([], String.to_atom(field), :desc)
    Ash.Query.sort(query, sort)
  end
  def list_sort(query, field) do
    sort = Keyword.put([], String.to_atom(field), :asc)
    Ash.Query.sort(query, sort)
  end

  def filter_by_slug(query, ""), do: query
  def filter_by_slug(query, nil), do: query
  def filter_by_slug(query, slug) do
    Ash.Query.filter(query, term_taxonomy.term.slug == ^slug)
  end

  # def filter_by_meta(query, key, value) when is_binary(key) and is_binary(value) do
  #   Ash.Query.filter(query, post_meta.meta_value == ^value and contains(post_meta.meta_key, ^key))
  # end
  # def filter_by_meta(query, _, _), do: query

  def industries, do: get_term_taxonomy("industries")
  def countries, do: get_term_taxonomy("countries")

  defp get_term_taxonomy(slug) do
    Ash.Query.filter(Moly.Terms.TermTaxonomy, parent.slug == ^slug)
    |> Ash.Query.load([:term])
    |> Ash.read!(actor: %{roles: [:user]})
  end
end
