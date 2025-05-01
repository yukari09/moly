defmodule MolyWeb.Affinew.QueryEs do
  require Ash.Query
  require Logger

  alias Moly.Cluster

  def index_query() do
    query = %{
      query: %{
        bool: %{must: [%{term: %{post_status: "publish"}}, %{term: %{post_type: "affiliate"}}]}
      },
      sort: [%{"updated_at" => %{"order" => "desc"}}],
      size: 36
    }

    case Snap.Search.search(Cluster, Moly.Contents.Notifiers.Post.index_name(), query) do
      {:ok, data} -> data.hits.hits
      _ -> []
    end
  end

  def list_query_by_post_ids(post_ids) when is_list(post_ids) do
    q =
      %{
        query: %{
          bool: %{
            must: [
              %{
                terms: %{"id.keyword": post_ids}
              },
              %{
                terms: %{post_type: "affiliate"}
              }
            ]
          }
        }
      }
      |> query_page(1, Enum.count(post_ids))

    case Snap.Search.search(Cluster, Moly.Contents.Notifiers.Post.index_name(), q) do
      {:ok, %{hits: %{total: %{"value" => _total}, hits: hits}}} -> hits
      _ -> []
    end
  end

  def list_query_by_user_posted(user_id, page, per_page) do
    q =
      %{
        query: %{
          bool: %{
            must: [
              %{
                term: %{"author_id.keyword": user_id}
              },
              %{
                term: %{post_type: "affiliate"}
              }
            ]
          }
        }
      }
      |> query_page(page, per_page)

    case Snap.Search.search(Cluster, Moly.Contents.Notifiers.Post.index_name(), q) do
      {:ok, %{hits: %{total: %{"value" => total}, hits: hits}}} -> {total, hits}
      _ -> {0, []}
    end
  end

  def list_query_by_search(q, sort, page, per_page) do
    q =
      %{
        query: %{
          bool: %{
            must: [
              %{term: %{post_status: "publish"}},
              %{term: %{post_type: "affiliate"}}
            ],
            should: [
              %{
                match: %{
                  "post_title" => q
                }
              },
              %{
                match: %{
                  "post_content" => q
                }
              },
              %{
                term: %{
                  "affiliate_category.slug.keyword" => q
                }
              },
              %{
                term: %{
                  "affiliate_tag.slug.keyword" => q
                }
              }
            ],
            minimum_should_match: 1
          }
        }
      }
      |> query_sort(sort)
      |> query_page(page, per_page)

    Logger.debug(JSON.encode!(q))

    case Snap.Search.search(Cluster, Moly.Contents.Notifiers.Post.index_name(), q) do
      {:ok, %{hits: %{total: %{"value" => total}, hits: hits}}} -> {total, hits}
      _ -> {0, []}
    end
  end

  def list_query_by_category(slug, sort, page, per_page) do
    q =
      %{
        query: %{
          bool: %{
            must: [
              %{term: %{post_status: "publish"}},
              %{term: %{post_type: "affiliate"}}
            ],
            should: [
              %{
                term: %{
                  "affiliate_category.slug.keyword" => slug
                }
              },
              %{
                term: %{
                  "affiliate_tag.slug.keyword" => slug
                }
              }
            ],
            minimum_should_match: 1
          }
        }
      }
      |> query_sort(sort)
      |> query_page(page, per_page)

    Logger.debug(JSON.encode!(q))

    case Snap.Search.search(Cluster, Moly.Contents.Notifiers.Post.index_name(), q) do
      {:ok, %{hits: %{total: %{"value" => total}, hits: hits}}} -> {total, hits}
      _ -> {0, []}
    end
  end

  def list_query(
        %{
          "category" => category,
          "commission" => commission,
          "cookie-duration" => cookie_duration,
          "page" => page,
          "payment-cycle" => payment_cycle,
          "sort" => sort
        },
        per_page
      ) do
    page = (page && String.to_integer(page)) || 1
    query = %{bool: %{}}

    must =
      [%{term: %{post_status: "publish"}}, %{term: %{post_type: "affiliate"}}]
      |> category_query(category)
      |> commission_query(commission)
      |> cookie_duration_query(cookie_duration)
      |> payment_cycle_query(payment_cycle)

    query = if must != [], do: put_in(query, [:bool, :must], must), else: query

    query = %{query: query}
    query = query_page(query, page, per_page) |> query_sort(sort)

    Logger.debug(JSON.encode!(query))

    case Snap.Search.search(Cluster, Moly.Contents.Notifiers.Post.index_name(), query) do
      {:ok, %{hits: %{total: %{"value" => total}, hits: hits}}} -> {total, hits}
      _ -> {0, []}
    end
  end

  def industries, do: get_term_taxonomy("industries")
  def countries, do: get_term_taxonomy("countries")

  defp get_term_taxonomy(slug) do
    Ash.Query.filter(Moly.Terms.TermTaxonomy, parent.slug == ^slug)
    |> Ash.Query.load([:term])
    |> Ash.read!(actor: %{roles: [:user]})
  end

  defp query_page(q, page, per_page) do
    o = (page - 1) * per_page
    Map.merge(q, %{size: per_page, from: o})
  end

  defp commission_query(must, nil), do: must

  defp commission_query(must, commission) do
    [ctype, cmin, cmax] = String.split(commission, "-")
    cmin = String.to_integer(cmin)
    range = %{gte: cmin}

    range =
      if cmax != "" do
        cmax = String.to_integer(cmax)
        Map.put(range, :lte, cmax)
      else
        range
      end

    [
      %{
        nested: %{
          path: "commission",
          query: %{
            bool: %{
              must: [
                %{term: %{"commission.commission_type" => ctype}},
                %{range: %{"commission.commission_amount" => range}}
              ]
            }
          }
        }
      }
      | must
    ]
  end

  defp payment_cycle_query(must, nil), do: must

  defp payment_cycle_query(must, payment_cycle),
    do: [%{term: %{payment_cycle: payment_cycle}} | must]

  defp cookie_duration_query(must, nil), do: must

  defp cookie_duration_query(must, cookie_duration) do
    [cmin, cmax] = String.split(cookie_duration, "-")
    cmin = String.to_integer(cmin)
    range = %{gte: cmin}

    range =
      if cmax != "" do
        cmax = String.to_integer(cmax)
        Map.put(range, :lte, cmax)
      else
        range
      end

    [%{range: %{"cookie_duration" => range}} | must]
  end

  defp category_query(must, nil), do: must

  defp category_query(must, category) do
    [%{match: %{"affiliate_category.slug" => category}} | must]
  end

  def query_sort(query, nil), do: Map.put(query, :sort, [%{"updated_at" => %{"order" => "desc"}}])

  def query_sort(query, sort_str) do
    case sort_str do
      "created_at_desc" ->
        Map.put(query, :sort, ["_score", %{"updated_at" => %{"order" => "desc"}}])

      "created_at_asc" ->
        Map.put(query, :sort, ["_score", %{"updated_at" => %{"order" => "asc"}}])
    end
  end
end
