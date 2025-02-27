defmodule Monorepo.Utilities.Affiliate do
  use MonorepoWeb, :html

  require Ash.Query

  alias Monorepo.Contents.Post
  alias Monorepo.Terms.Term

  @default_image_size ["xxlarge", "xlarge", "large", "medium", "thumbnail"]

  def link_view(post), do: ~p"/affiliate/#{post.post_name}"
  def link_industry(post) do
    slug = affiliate_industry_slug(post) || ""
    ~p"/affiliates/#{slug}"
  end
  def link_term(%Term{name: _name, slug: slug}), do: ~p"/affiliates/#{slug}"

  def cookie_duration(%Post{id: id} = post) when is_binary(id), do: load_meta_value_by_meta_key(post, :cookie_duration)
  def affiliate_link(%Post{id: id} = post) when is_binary(id), do: load_meta_value_by_meta_key(post, :affiliate_link)
  def commission_model(%Post{id: id} = post) when is_binary(id), do: load_meta_value_by_meta_key(post, :commission_model)
  def commission_unit(%Post{id: id} = post) when is_binary(id), do: load_meta_value_by_meta_key(post, :commission_unit)
  def commission_max(%Post{id: id} = post) when is_binary(id), do: load_meta_value_by_meta_key(post, :commission_max)
  def commission_min(%Post{id: id} = post) when is_binary(id), do: load_meta_value_by_meta_key(post, :commission_min)

  def affiliate_tags(%Post{id: _id} = post), do: (load_post_tags(post) |> Map.get(:post_tags))

  def affiliate_industry(%Post{id: _id} = post) do
    get_affiliate_categories_by_parent_slug(post, "industries")
  end

  def affiliate_industry_name(%Post{id: _id} = post) do
    affiliate_industry(post)
    |> case do
      nil -> nil
      %{name: name} -> name
    end
  end

  def affiliate_industry_slug(%Post{id: _id} = post) do
    affiliate_industry(post)
    |> case do
      nil -> nil
      %{slug: slug} -> slug
    end
  end

  def affiliate_country(%Post{id: _id} = post) do
    get_affiliate_categories_by_parent_slug(post, "countries")
  end

  def get_affiliate_categories_by_parent_slug(%Post{id: _id} = post, slug) do
    post = load_post_affiliate_categories(post)
    get_term_taxonomy(slug)
    |> Map.get(:term_id)
    |> case do
      nil -> nil
      parent_id ->
        Enum.find(post.affiliate_categories, fn term ->
          List.first(term.term_taxonomy)
          |> case do
            %{parent_id: term_taxonomy_parent_id} when term_taxonomy_parent_id ==  parent_id -> true
            _ -> false
          end
        end)
    end
  end

  def affiliate_media_feature_src_with_specific_sizes(%Post{id: id} = post, sizes \\ []) when is_binary(id) do
    affiliate_media_feature_with_specific_sizes(post, sizes)
    |> case do
      %{"file" => file} -> file
      _ -> nil
    end
  end

  def affiliate_media_feature_with_specific_sizes(%Post{id: id} = post, sizes \\ [])  when is_binary(id) do
    load_affiliate_media_attachment_metadata(post, :attachment_affiliate_media_feature, sizes, false)
    |> List.first()
  end

  def load_affiliate_media_attachment_metadata(%Post{id: id} = post, meta_key, sizes \\ [], return_all_sizes \\ false) when is_binary(id) and is_atom(meta_key) do
    post = load_post_meta_with_post_meta_children(post)
    filter_by_meta_key(post, meta_key)
    |> Enum.reduce([], fn
      %{children: children}, acc ->
        filter_by_meta_key(%{post_meta: children}, :attachment_metadata)
        |> case do
          post_meta when is_list(post_meta) ->
            acc = (acc ++ Enum.map(post_meta, &(get_post_image_by_sizes(&1, sizes, return_all_sizes))))
            List.flatten(acc)
          _ -> []
        end
    end)
  end

  def get_post_image_by_sizes(%{meta_key: :attachment_metadata, meta_value: meta_value}, sizes, return_all_sizes \\ false) do
    meta_value_decoded =  JSON.decode!(meta_value)
    result =
      if return_all_sizes do
        Enum.reduce(sizes, [], fn size, acc ->
          image_media = Monorepo.Helper.get_in_from_keys(meta_value_decoded, ["sizes", size])
          image_media && [image_media | acc] || acc
        end)
      else
        Enum.reduce_while(sizes, nil, fn size, _ ->
          image_media = Monorepo.Helper.get_in_from_keys(meta_value_decoded, ["sizes", size])
          if image_media, do: {:halt, image_media}, else: [:cont, nil]
        end)
      end
    result
  end

  defp load_meta_value_by_meta_key(post, meta_key) do
    post = load_post_meta(post)
    filter_by_meta_key(post, meta_key)
    |> List.first()
  end

  defp load_post_meta(%Post{id: _id} = post), do: load_relation(post, :post_meta)
  defp load_post_tags(%Post{id: _id} = post), do: load_relation(post, :post_tags)
  defp load_post_affiliate_categories(%Post{id: _id} = post), do: load_relation(post, :affiliate_categories)

  defp load_relation(%Post{id: _id} = post, relation_name) when is_atom(relation_name) do
    relation_result = Map.get(post, relation_name)
    if is_list(relation_result) and Enum.count(relation_result) > 0 do
      post
    else
      Ash.load!(post, [relation_name], actor: %{roles: [:user]})
    end
  end

  defp load_post_meta_with_post_meta_children(%Post{id: _id} = post) do
    if is_list(post.post_meta) && Enum.count(post.post_meta) > 0 do
      post_meta_first = post.post_meta |> List.first()
      if is_list(post_meta_first.children) && Enum.count(post_meta_first.children) > 0 do
        post
      else
        Ash.load!(post, [post_meta: :children], actor: %{roles: [:user]})
      end
    else
      Ash.load!(post, [post_meta: :children], actor: %{roles: [:user]})
    end
  end

  defp get_term_taxonomy(slug) do
    Ash.Query.filter(Monorepo.Terms.TermTaxonomy, term.slug == ^slug and taxonomy == "affiliate_category")
    |> Ash.Query.load([:term])
    |> Ash.read_first!(actor: %{roles: [:user]})
  end

  defp filter_by_meta_key(%{post_meta: post_meta}, meta_key) when is_list(post_meta) and is_atom(meta_key) do
    Enum.filter(post_meta, &(&1.meta_key == meta_key))
  end
  defp filter_by_meta_key(_, _), do: []
end
