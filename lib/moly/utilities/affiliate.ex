defmodule Moly.Utilities.Affiliate do
  use MolyWeb, :html

  require Ash.Query

  alias Moly.Contents.Post
  alias Moly.Terms.Term

  # @default_image_size ["xxlarge", "xlarge", "large", "medium", "thumbnail"]

  def link_view(post), do: ~p"/affiliate/#{post.post_name}"

  def link_industry(post) do
    slug = affiliate_industry_slug(post) || ""
    ~p"/affiliates/#{slug}"
  end

  def link_term(%Term{name: _name, slug: slug}), do: ~p"/affiliates/#{slug}"

  def cookie_duration(%Post{id: id} = post) when is_binary(id),
    do: load_meta_value_by_meta_key(post, :cookie_duration)

  def affiliate_link(%Post{id: id} = post) when is_binary(id),
    do: load_meta_value_by_meta_key(post, :affiliate_link)

  def commission_model(%Post{id: id} = post) when is_binary(id),
    do: load_meta_value_by_meta_key(post, :commission_model)

  def commission_unit(%Post{id: id} = post) when is_binary(id),
    do: load_meta_value_by_meta_key(post, :commission_unit)

  def commission_max(%Post{id: id} = post) when is_binary(id),
    do: load_meta_value_by_meta_key(post, :commission_max)

  def commission_min(%Post{id: id} = post) when is_binary(id),
    do: load_meta_value_by_meta_key(post, :commission_min)

  def affiliate_tags(%Post{id: _id} = post),
    do: load_affiliate_tags(post) |> Map.get(:affiliate_tags)

  def affiliate_industries() do
    Ash.Query.new(Moly.Terms.Term)
    |> Ash.Query.filter(
      term_taxonomy.taxonomy == "affiliate_category" and term_taxonomy.parent.slug == "industries"
    )
    |> Ash.Query.load([:term_meta, :term_taxonomy])
    |> Ash.read!(actor: %{roles: [:user]})
  end

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
      nil -> ""
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
      nil ->
        nil

      parent_id ->
        Enum.find(post.affiliate_categories, fn term ->
          List.first(term.term_taxonomy)
          |> case do
            %{parent_id: term_taxonomy_parent_id} when term_taxonomy_parent_id == parent_id ->
              true

            _ ->
              false
          end
        end)
    end
  end

  def affiliate_media_feature_src_with_specific_sizes(%Post{id: id} = post, sizes \\ [])
      when is_binary(id) do
    affiliate_media_feature_with_specific_sizes(post, sizes)
    |> case do
      %{"file" => file} -> file
      _ -> nil
    end
  end

  def affiliate_media_feature_with_specific_sizes(%Post{id: id} = post, sizes \\ [])
      when is_binary(id) do
    load_affiliate_media_attachment_metadata(
      post,
      :attachment_affiliate_media_feature,
      sizes,
      false
    )
    |> List.first()
  end

  def load_affiliate_media_attachment_metadata(
        %Post{id: id} = post,
        meta_key,
        sizes \\ [],
        return_all_sizes \\ false
      )
      when is_binary(id) and is_atom(meta_key) do
    post = load_post_meta_with_post_meta_children(post)

    filter_by_meta_key(post, meta_key)
    |> Enum.reduce([], fn
      %{children: children}, acc ->
        filter_by_meta_key(%{post_meta: children}, :attachment_metadata)
        |> case do
          post_meta when is_list(post_meta) ->
            new_slice =
              Enum.map(post_meta, fn i ->
                get_post_image_by_sizes(i, sizes, return_all_sizes)
              end)

            acc = acc ++ new_slice
            List.flatten(acc)

          _ ->
            []
        end
    end)
  end

  def get_post_image_by_sizes(
        %{meta_key: :attachment_metadata, meta_value: meta_value},
        sizes,
        return_all_sizes \\ false
      ) do
    meta_value_decoded = JSON.decode!(meta_value)

    result =
      if return_all_sizes do
        Enum.reduce(sizes, [], fn size, acc ->
          image_media = Moly.Helper.get_in_from_keys(meta_value_decoded, ["sizes", size])
          (image_media && [image_media | acc]) || acc
        end)
      else
        Enum.reduce_while(sizes, meta_value_decoded, fn size, acc ->
          image_media = Moly.Helper.get_in_from_keys(acc, ["sizes", size])
          if image_media, do: {:halt, image_media}, else: {:cont, acc}
        end)
      end

    result
  end

  attr(:post, Moly.Contents.Post, required: true)

  def article_html(%{post: post} = assigns) do
    article_cache_function = fn ->
      %{
        feature_image_src:
          affiliate_media_feature_src_with_specific_sizes(post, ["medium", "thumbnail"]),
        username: Moly.Utilities.Account.user_username(post.author),
        affiliate_industry_name: affiliate_industry_name(post),
        link_industry: link_industry(post)
      }
    end

    cached_data =
      Moly.Utilities.cache_get_or_put(
        "affiliate.#{post.post_name}",
        article_cache_function,
        :timer.hours(12)
      )

    assigns = assign(assigns, :cache, cached_data)

    ~H"""
    <article class="flex flex-col items-start justify-between">
      <div class="relative w-full">
        <img
          src={@cache.feature_image_src}
          alt={@post.post_title}
          class="aspect-video w-full rounded-2xl bg-gray-100 object-cover sm:aspect-[2/1] lg:aspect-[3/2]"
        />
        <.link
          class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-900/10"
          navigate={link_view(@post)}
        >
          &nbsp;
        </.link>
      </div>
      <div class="max-w-xl">
        <div class="mt-4 flex items-top gap-x-2 text-xs">
          <.link class="size-8" patch={~p"/user/@#{@cache.username}"}>
            <Moly.Utilities.Account.avatar_html user={@post.author} size={32} />
          </.link>
          <div class="flex-1">
            <h3 class="text-base/6 font-semibold text-gray-900 group-hover:text-gray-600 line-clamp-2">
              <.link navigate={link_view(@post)}>
                {@post.post_title}
              </.link>
            </h3>
            <div><.commission_label post={@post} /></div>
            <div class="space-x-1 mt-2">
              <time
                datetime={@post.inserted_at |> Timex.format!("{YYYY}-{D}-{0M}")}
                class="text-gray-500"
              >
                {@post.inserted_at |> Timex.format!("{Mshort} {D}, {YYYY}")}
              </time>
              <.link
                navigate={@cache.link_industry}
                class="relative rounded-full bg-gray-50 px-3 py-1.5 font-medium text-gray-600 hover:bg-gray-100"
              >
                {@cache.affiliate_industry_name}
              </.link>
            </div>
          </div>
        </div>
      </div>
    </article>
    """
  end

  attr(:post, Moly.Contents.Post, required: true)

  def commission_label(assigns) do
    min = commission_min(assigns.post)
    max = commission_max(assigns.post)
    unit = commission_unit(assigns.post)
    assigns = assigns |> Map.put(:min, min)
    assigns = assigns |> Map.put(:max, max)
    assigns = assigns |> Map.put(:unit, unit)

    ~H"""
    <div :if={commission_unit(@post) == "%"}>
      <span class="text-green-500 font-ligh">{(@min == @max && "Up to") || "From"}</span>
      <span class="font-bold text-green-500 text-lg">
        {@min}
      </span>
      <span class="text-green-500 font-light">
        {@unit}
      </span>
      <%= if @min != @max do %>
        <span class="text-green-500 font-ligh">to</span>
        <span class="font-bold text-green-500 text-lg">
          {@max}
        </span>
        <span class="text-green-500 font-light">
          {@unit}
        </span>
      <% end %>
    </div>

    <div :if={commission_unit(@post) !== "%"}>
      <span class="text-green-500 font-ligh">From</span>
      <span class="font-bold text-green-500 text-lg">
        {@unit}
      </span>
      <span class="font-bold text-green-500 text-lg">
        {@min}
      </span>
      <span class="text-green-500 font-ligh">to</span>
      <span class="font-bold text-green-500 text-lg">
        {@max}
      </span>
    </div>
    """
  end

  attr(:post, Moly.Contents.Post, required: true)

  def commission_label2(assigns) do
    min = commission_min(assigns.post)
    max = commission_max(assigns.post)
    unit = commission_unit(assigns.post)
    assigns = assigns |> Map.put(:min, min)
    assigns = assigns |> Map.put(:max, max)
    assigns = assigns |> Map.put(:unit, unit)

    ~H"""
    <div :if={commission_unit(@post) == "%"}>
      <span class="text-green-500 font-ligh">{(@min == @max && "Up to") || "From"}</span>
      <span class="font-bold text-green-500 text-lg">
        {@min}
      </span>
      <span class="text-green-500 font-light">
        {@unit}
      </span>
      <%= if @min != @max do %>
        <span class="text-green-500 font-ligh">to</span>
        <span class="font-bold text-green-500 text-lg">
          {@max}
        </span>
        <span class="text-green-500 font-light">
          {@unit}
        </span>
      <% end %>
    </div>

    <div :if={commission_unit(@post) !== "%"}>
      <span class="text-green-500 font-ligh">From</span>
      <span class="font-bold text-green-500 text-lg">
        {@unit}
      </span>
      <span class="font-bold text-green-500 text-lg">
        {@min}
      </span>
      <span class="text-green-500 font-ligh">to</span>
      <span class="font-bold text-green-500 text-lg">
        {@max}
      </span>
    </div>
    """
  end

  defp load_meta_value_by_meta_key(post, meta_key) do
    post = load_post_meta(post)

    filter_by_meta_key(post, meta_key)
    |> List.first()
    |> case do
      nil -> nil
      %{meta_value: meta_value} -> meta_value
    end
  end

  defp load_post_meta(%Post{id: _id} = post), do: load_relation(post, :post_meta)
  defp load_affiliate_tags(%Post{id: _id} = post), do: load_relation(post, :affiliate_tags)

  defp load_post_affiliate_categories(%Post{id: _id} = post),
    do: load_relation(post, :affiliate_categories)

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
    Ash.Query.filter(
      Moly.Terms.TermTaxonomy,
      term.slug == ^slug and taxonomy == "affiliate_category"
    )
    |> Ash.Query.load([:term])
    |> Ash.read_first!(actor: %{roles: [:user]})
  end

  defp filter_by_meta_key(%{post_meta: post_meta}, meta_key)
       when is_list(post_meta) and is_atom(meta_key) do
    Enum.filter(post_meta, &(&1.meta_key == meta_key))
  end

  defp filter_by_meta_key(_, _), do: []
end
