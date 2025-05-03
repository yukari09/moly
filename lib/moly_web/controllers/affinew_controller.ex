defmodule MolyWeb.AffinewController do
  use MolyWeb, :controller

  require Ash.Query

  import  MolyWeb.Affinew.QueryEs

  def home(conn, _params) do
    {affiliates, posts} =
      Moly.Utilities.cache_get_or_put(
        "#{__MODULE__}.page.index.cache",
        &index_query/0,
        :timer.hours(6)
      )

    conn = put_layout(conn, false)
    render(conn, :home, affiliates: affiliates, posts: posts, page_title: "Find High Ticket Best Paying affiliate programss for beginners in 2025")
  end


  # def browse(conn, params) do
  #   current_params =
  #     ["page", "sort", "q", "category", "commission", "cookie-duration", "payment-cycle"]
  #     |> Enum.reduce(%{}, fn param, a1 ->
  #       param_value = Map.get(params, param)
  #       if param_value != "" do
  #         Map.put(a1, param, param_value)
  #       else
  #         Map.put(a1, param, nil)
  #       end
  #     end)

  #   industry_options =
  #     Moly.Utilities.cache_get_or_put("MolyWeb.Affinew.ListLive:industries", &industries/0, :timer.hours(1))
  #     |> Enum.map(&{&1.term.slug, &1.term.name})

  #   options =
  #     Enum.reduce(current_params, %{}, fn {option, option_value}, a1 ->
  #       if option_value not in [false, "", nil] do
  #         case option do
  #           "category" ->
  #             value = to_option_value(industry_options, option_value)
  #             Map.put(a1, option, value)

  #           "commission" ->
  #             value = to_option_value(commission_options(), option_value)
  #             Map.put(a1, option, value)

  #           "payment-cycle" ->
  #             value = to_option_value(payment_cycle_options(), option_value)
  #             Map.put(a1, option, value)

  #           "cookie-duration" ->
  #             value = to_option_value(cookie_duration_options(), option_value)
  #             Map.put(a1, option, value)

  #           _ ->
  #             a1
  #         end
  #       else
  #         a1
  #       end
  #     end)

  #   page = (current_params["page"] && String.to_integer(current_params["page"])) || 1
  #   per_page = 6

  #   {count, posts} = list_query(current_params, per_page)
  #   page_meta = Moly.Helper.pagination_meta(count, per_page, page, 5)

  #   category_name = Map.get(options, "category")
  #   category_name = category_name && category_name <> " " || ""
  #   dt = Date.utc_today()
  #   page_title = "#{category_name}High Ticket Best Paying affiliate programs You Must Be Know in #{dt.year}"

  #   conn = if count == 0 do
  #     empty_map_params = %{
  #       "category" => nil,
  #       "commission" => nil,
  #       "cookie-duration" => nil,
  #       "page" => nil,
  #       "payment-cycle" => "novalue",
  #       "q" => nil,
  #       "sort" => nil
  #     }
  #     assign(conn, :canonical, ~p"/browse?#{empty_map_params}")
  #   else
  #     conn
  #   end

  #   conn = put_layout(conn, html: {MolyWeb.Layouts, :affinew})

  #   render(conn, :browse,
  #     posts: posts,
  #     params: current_params,
  #     page_meta: page_meta,
  #     options: options,
  #     industry_options: industry_options,
  #     commission_options: commission_options(),
  #     cookie_duration_options: cookie_duration_options(),
  #     payment_cycle_options: payment_cycle_options(),
  #     sort_options: sort_options(),
  #     page_title: page_title
  #   )
  # end


  # def list_term(conn, %{"slug" => slug} = params) do
  #   page = Map.get(params, "page", "1") |> String.to_integer()
  #   sort = Map.get(params, "sort", "created_at_desc")
  #   per_page = 6

  #   industry_options =
  #     Moly.Utilities.cache_get_or_put("MolyWeb.Affinew.ListLive:industries", &industries/0, :timer.hours(1))
  #     |> Enum.map(&{&1.term.slug, &1.term.name})

  #   {count, posts} = MolyWeb.Affinew.QueryEs.list_query_by_category(slug, sort, page, per_page)
  #   page_meta = Moly.Helper.pagination_meta(count, per_page, page, 5)

  #   current_params = %{"page" => page, "sort" => sort}

  #   term_name = to_option_value(industry_options, slug)

  #   keyword =
  #     (term_name || slug)
  #     |> String.replace("-", " ")
  #     |> String.capitalize()

  #   conn = if count == 0 do
  #     empty_map_params = %{
  #       "category" => nil,
  #       "commission" => nil,
  #       "cookie-duration" => nil,
  #       "page" => nil,
  #       "payment-cycle" => "novalue",
  #       "q" => nil,
  #       "sort" => nil
  #     }
  #     assign(conn, :canonical, ~p"/browse?#{empty_map_params}")
  #   else
  #     conn
  #   end

  #   page_title = "#{keyword} High Ticket best Paying affiliate programs"

  #   conn = put_layout(conn, html: {MolyWeb.Layouts, :affinew})

  #   render(conn, :list_term,
  #     posts: posts,
  #     params: current_params,
  #     page_meta: page_meta,
  #     slug: slug,
  #     keyword: keyword,
  #     industry_options: industry_options,
  #     sort_options: sort_options(),
  #     page_title: page_title
  #   )
  # end


  # def results(conn, %{"q" => q} = params) do
  #   page = Map.get(params, "page", "1") |> String.to_integer()
  #   sort = Map.get(params, "sort", "created_at_desc")
  #   per_page = 6

  #   industry_options =
  #     Moly.Utilities.cache_get_or_put("MolyWeb.Affinew.ListLive:industries", &industries/0, :timer.hours(1))
  #     |> Enum.map(&{&1.term.slug, &1.term.name})

  #   {count, posts} = MolyWeb.Affinew.QueryEs.list_query_by_search(q, sort, page, per_page)
  #   page_meta = Moly.Helper.pagination_meta(count, per_page, page, 5)

  #   current_params = %{"page" => page, "sort" => sort, "q" => q}
  #   page_title = "Search Result #{q} affiliate programss"

  #   conn = put_layout(conn, html: {MolyWeb.Layouts, :affinew})

  #   render(conn, :results,
  #     posts: posts,
  #     params: current_params,
  #     page_meta: page_meta,
  #     q: q,
  #     industry_options: industry_options,
  #     sort_options: sort_options(),
  #     page_title: page_title
  #   )
  # end



  # def post_index(conn, _params) do
  #   render(conn, :index, posts: [])
  # end


  # def post_view(conn, %{"post_name" => post_name}) do

  #   [post, author] =
  #     Moly.Utilities.cache_get_or_put(
  #       "#{__MODULE__}.affiliate.post.index.cache",
  #       fn ->
  #         post = view_query(post_name)
  #         author_id = Moly.Helper.get_in_from_keys(post, [:source, "author_id"])

  #         author =
  #           Moly.Utilities.Account.get_users_by_id([author_id])
  #           |> Map.get(author_id)

  #         [post, author]
  #       end,
  #       :timer.hours(1)
  #     )

  #   conn = put_layout(conn, {MolyWeb.Layouts, :affinew})

  #   render(conn, :post_view, post: post, author: author)
  # end


  # defp view_query(post_name) do
  #   query = %{
  #     query: %{
  #       bool: %{
  #         must: [
  #           %{term: %{"post_name.keyword" => post_name}},
  #           %{term: %{"post_status.keyword" => "publish"}}
  #         ]
  #       }
  #     }
  #   }
  #   Moly.Helper.es_query_result(
  #     Moly.Cluster,
  #     Moly.Contents.Notifiers.Post.index_name(),
  #     query
  #   )
  #   |> case do
  #     nil -> nil
  #     [_, [post | _]] -> post
  #   end
  # end


  # defp to_option_value(options, option_value) do
  #   Enum.find(options, &(elem(&1, 0) == option_value))
  #   |> case do
  #     nil -> nil
  #     {_, label} -> label
  #   end
  # end


end
