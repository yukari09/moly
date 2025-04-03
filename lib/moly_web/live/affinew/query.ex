defmodule MolyWeb.Affinew.Query do
  require Ash.Query

  def opts,
    do: [
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
    page = (page == "" && 1) || String.to_integer(page)
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

  def list_sort(query, "-" <> field) do
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

  def filter_by_commission(filters, ""), do: filters
  def filter_by_commission(filters, nil), do: filters

  def filter_by_commission(filters, commission_value) when is_binary(commission_value) do
    [commission_type, min_value, max_value] = String.split(commission_value, "-")

    if commission_type != "" && min_value != "" do
      min_value = String.to_integer(min_value)
      max_value = (max_value == "" && min_value + 500) || String.to_integer(max_value)

      Enum.reduce((min_value * 10)..(max_value * 10)//1, filters, fn i, acc ->
        acc = ["#{commission_type}-#{i / 10}" | acc]

        if rem(i, 10) == 0 do
          ["#{commission_type}-#{trunc(i / 10)}" | acc]
        else
          acc
        end
      end)
    else
      filters
    end
  end

  def filter_by_cookie_duration(filters, ""), do: filters
  def filter_by_cookie_duration(filters, nil), do: filters

  def filter_by_cookie_duration(filters, cookie_duration_value) do
    [min_value, max_value] = String.split(cookie_duration_value, "-")

    if min_value != "" do
      min_value = String.to_integer(min_value)
      max_value = (max_value == "" && min_value + 60) || String.to_integer(max_value)
      Enum.map(min_value..max_value, & &1) ++ filters
    else
      filters
    end
  end

  def filter_by_payment_cycle(filters, ""), do: filters
  def filter_by_payment_cycle(filters, nil), do: filters
  def filter_by_payment_cycle(filters, payment_cycle_value), do: [payment_cycle_value | filters]

  def apply_filters(query, []), do: query

  def apply_filters(query, filters),
    do: Ash.Query.filter(query, post_meta.meta_value in ^Enum.uniq(filters))

  def industries, do: get_term_taxonomy("industries")
  def countries, do: get_term_taxonomy("countries")

  defp get_term_taxonomy(slug) do
    Ash.Query.filter(Moly.Terms.TermTaxonomy, parent.slug == ^slug)
    |> Ash.Query.load([:term])
    |> Ash.read!(actor: %{roles: [:user]})
  end
end
