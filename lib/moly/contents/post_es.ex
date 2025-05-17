defmodule Moly.Contents.PostEs do
  use Moly.EsIndex,
    name: "post",
    mapping_file: "priv/mapping/post.json"

  require Ash.Query
  require Logger

  @actor %{roles: [:user]}

  @doc """
  Query data from elasticsearch

  opts:
  - post_type
  - post_status
  - page
  - per_page
  - sort
    - "-<filed>" filed: :desc
    - "<field>" field: :asc
  - updated_at: range data [begain_date, end_date],[nil, end_date],[begain_date, nil],[]
  - categories: list of slug.
  - tags: list of slug
  - exclude_id: list
  """
  def query(opts \\ []) do
    bool = %{}
    must = []
    should = []
    must_not = []

    must = if opts[:post_type], do: [%{term: %{"post_type.keyword" => opts[:post_type]}} | must]
    must = if opts[:post_status], do: [%{term: %{"post_status.keyword" => opts[:post_status]}} | must]

    must =
      if opts[:categories] != nil and opts[:categories] not in [nil, "", []] do
        categories = if is_binary(opts[:categories]), do: String.split(opts[:categories],","), else: opts[:categories]
        [%{terms: %{"category.slug.keyword" => categories}} | must]
      else
        must
      end

    must =
      if opts[:tags] != nil and opts[:tags] not in [nil, "", []] do
        tags = if is_binary(opts[:tags]), do: String.split(opts[:tags],","), else: opts[:tags]
        [%{terms: %{"post_tag.slug.keyword" => tags}} | must]
      else
        must
      end

    range =
      if opts[:updated_at] not in [[], "", false, nil] do
        [begain_date, end_date] = opts[:updated_at]
        updated_at_range = %{}
        updated_at_range =
          if begain_date do
            Map.put(updated_at_range, :gte, begain_date)
          else
            updated_at_range
          end
        updated_at_range =
          if end_date do
            Map.put(updated_at_range, :lte, end_date)
          else
            updated_at_range
          end
        %{updated_at: updated_at_range}
      else
        nil
      end

    must_not =
      if opts[:exclude_id] && opts[:exclude_id] != [] do
        [%{terms: %{"id.keyword" => opts[:exclude_id]}}]
      else
        must_not
      end

    bool = Enum.reduce([must: must, should: should, must_not: must_not], bool, fn {k, v}, acc ->
      v in [nil, [], false] && acc || Map.put(acc, k, v)
    end)

    query = if bool != %{}, do: %{query: %{bool: bool}}, else: %{query: %{match_all: %{}}}

    query =
      if range do
        Map.put(query, :range, range)
      else
        query
      end

    query =
      if opts[:sort] do
        case opts[:sort] do
          "-" <> field ->
            sort_map = Map.new([{String.to_atom(field), %{order: "desc"}}])
            Map.put(query, :sort, [sort_map])
          field ->
            sort_map = Map.new([{String.to_atom(field), %{order: "asc"}}])
            Map.put(query, :sort, [sort_map])
        end
      else
        query
      end

    per_page = opts[:per_page] && opts[:per_page] || 12
    page =     opts[:page] && opts[:page] || 1

    from = (page - 1) * per_page

    query =
      Map.put(query, :from, from)
      |> Map.put(:size, per_page)

    Logger.debug("#{__MODULE__} query: #{JSON.encode!(query)}")

    es_query_result(query)
  end

  def query_document_by_post_name(post_name) do
    query = %{query: %{term: %{"post_name.keyword" => post_name}}}

    Logger.debug("#{__MODULE__} query: #{JSON.encode!(query)}")

    es_query_result(query)
  end

  def relative_posts(post_id, size) do
    query = %{
      query: %{
        bool: %{
          must: [
            %{term: %{post_status: "publish"}},
            %{term: %{post_type: "post"}},
            %{
              more_like_this: %{
                fields: [:post_title, :post_content],
                like: %{
                  _index: index_name(),
                  _id: post_id
                },
                min_term_freq: 1,
                max_query_terms: 12
              }
            }
          ]
        }
      },
      size: size
    }
    es_query_result(query)
  end


  def build_document_index_by_id(post_id) do
      create_post_document(post_id)
      |> document_index(post_id)
  end

  def create_post_document(post_id) do
    post =
      Ash.get!(Moly.Contents.Post, post_id, actor: @actor)
      |> Ash.load!([:post_meta, term_taxonomy: :term], actor: @actor)

    attrs = attributes(Moly.Contents.Post)

    post_meta = handle_post_meta(post.post_meta)

    taxonomy =
      Enum.group_by(
        post.term_taxonomy,
        fn %{taxonomy: taxonomy} -> taxonomy end,
        fn %{term: %{name: name, slug: slug}, description: description} -> %{name: name, slug: slug, description: description} end
      )
      |> Enum.reduce(%{}, fn {key, value}, a1 ->
        key = String.to_atom(key)
        Map.put(a1, key, value)
      end)

    Map.take(post, attrs)
    |> Map.merge(post_meta)
    |> Map.merge(taxonomy)
  end

  defp handle_post_meta(post_meta) do
    Enum.group_by(post_meta, fn %{meta_key: k} ->
      splited = String.split(k, "_")

      if Regex.match?(~r/\d+/, Enum.at(splited, -1)) do
        Enum.at(splited, 0)
      else
        k
      end
    end)
    |> Enum.reduce(%{}, fn {k, items}, a1 ->
      if Enum.count(items) == 1 do
        item = List.first(items)
        key = String.to_atom(item.meta_key)
        value = convert_meta_value(key, item.meta_value)
        Map.put(a1, key, value)
      else
        k = String.to_atom(k)

        v =
          Enum.group_by(items, fn %{meta_key: meta_key} ->
            String.split(meta_key, "_") |> Enum.at(-1)
          end)
          |> Enum.reduce([], fn {_, child_items}, a2 ->
            new_item =
              Enum.reduce(child_items, %{}, fn %{meta_key: meta_key, meta_value: meta_value},
                                               a3 ->
                key =
                  String.split(meta_key, "_")
                  |> Enum.slice(0..-2//1)
                  |> Enum.join("_")
                  |> String.to_atom()

                value = convert_meta_value(key, meta_value)
                Map.put(a3, key, value)
              end)

            [new_item | a2]
          end)

        Map.put(a1, k, v)
      end
    end)
  end

  defp convert_meta_value(key, value)
       when key in [:thumbnail_id] and is_binary(value) and value != "" do
    Ash.Query.new(Moly.Contents.PostMeta)
    |> Ash.Query.filter(post_id == ^value)
    |> Ash.read!(actor: @actor)
    |> Enum.reduce(%{}, fn %{meta_key: meta_key, meta_value: meta_value}, acc ->
      key = String.to_atom(meta_key)
      value = convert_meta_value(key, meta_value)
      Map.put(acc, key, value)
    end)
  end

  defp convert_meta_value(key, value)
       when key in [:attachment_metadata] and is_binary(value) and value != "" do
    case JSON.decode(value) do
      {:ok, decoded} -> decoded
      {:error, _} -> %{}
    end
  end

  defp convert_meta_value(_, value), do: value

  defp attributes(resource) do
    Ash.Resource.Info.attributes(resource)
    |> Enum.map(& &1.name)
  end
end
