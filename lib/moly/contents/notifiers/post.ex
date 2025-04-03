defmodule Moly.Contents.Notifiers.Post do
  use Ash.Notifier

  require Ash.Query
  require Logger

  @actor %{roles: [:user]}

  def notify(%Ash.Notifier.Notification{
        resource: _resource,
        action: %{type: :create},
        data: data,
        actor: _actor
      }) do
    id = data.id
    document = create_post_document(id)
    Snap.Document.index(Moly.Cluster, index_name(), document, id)
  end

  def notify(%Ash.Notifier.Notification{
        resource: _resource,
        action: %{type: :update},
        data: data,
        actor: _actor
      }) do
    id = data.id
    document = create_post_document(id)
    Snap.Document.index(Moly.Cluster, index_name(), document, id)
  end

  def notify(%Ash.Notifier.Notification{
        resource: _resource,
        action: %{type: :destroy},
        data: data,
        actor: _actor
      }) do
    id = data.id
    Snap.Document.delete(Moly.Cluster, index_name(), id)
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
        fn %{term: %{name: name, slug: slug}} -> %{name: name, slug: slug} end
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

  defp convert_meta_value(:commission_amount, value) when is_binary(value) and value != "" do
    Float.parse(value)
    |> case do
      :error -> 0
      {float_part, _} -> float_part
    end
  end

  defp convert_meta_value(key, value)
       when key in [:cookie_duration, :duration_months, :min_payout_threshold, :commission_amount] and
              is_binary(value) and value != "" do
    Integer.parse(value)
    |> case do
      :error -> 0
      {int_part, _} -> int_part
    end
  end

  defp convert_meta_value(key, value)
       when key in [:payment_method, :region] and is_binary(value) and value != "" do
    String.split(value, ",")
  end

  defp convert_meta_value(key, value)
       when key in [:attachment_affiliate_media_feature] and is_binary(value) and value != "" do
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
       when key in [:attachment_affiliate_media] and is_binary(value) and value != "" do
    media_ids = String.split(value, ",")

    if Enum.count(media_ids) > 0 do
      Ash.Query.new(Moly.Contents.PostMeta)
      |> Ash.Query.filter(post_id in ^media_ids)
      |> Ash.read!(actor: @actor)
      |> Enum.group_by(fn %{post_id: post_id} -> post_id end)
      |> Enum.map(fn {_, items} ->
        Enum.reduce(items, %{}, fn %{meta_key: meta_key, meta_value: meta_value}, acc ->
          key = String.to_atom(meta_key)
          value = convert_meta_value(key, meta_value)
          Map.put(acc, key, value)
        end)
      end)
    else
      []
    end
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

  def index_name() do
    name = "post"
    prefix = Moly.Cluster.config() |> Keyword.get(:prefix)
    idx_name = (prefix && "#{prefix}_#{name}") || name

    key = "elasticsearch:index#{idx_name}"
    cached_index_record = Cachex.get!(:cache, key)

    if cached_index_record do
      idx_name
    else
      Snap.Indexes.get_mapping(Moly.Cluster, idx_name)
      |> elem(0)
      |> case do
        :error ->
          im = index_mapping()
          Snap.Indexes.create(Moly.Cluster, idx_name, im)
          Cachex.put(:cache, key, true, expire: :timer.minutes(10))
          idx_name

        :ok ->
          Cachex.put(:cache, key, true, expire: :timer.minutes(10))
          idx_name
      end
    end
  end

  defp index_mapping() do
    """
    {"mappings":{"properties":{"affiliate_category":{"properties":{"name":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"slug":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}}}},"affiliate_program_link":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"affiliate_signup_requirements":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"affiliate_tag":{"properties":{"name":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"slug":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}}}},"attached_file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_affiliate_media":{"properties":{"attached_file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_filesize":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_image_alt":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_image_caption":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_metadata":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"filename":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"filesize":{"type":"long"},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"sizes":{"properties":{"full":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"large":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"medium":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"thumbnail":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"xlarge":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"xxlarge":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}}}},"type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}}}},"attachment_affiliate_media_feature":{"properties":{"attached_file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_filesize":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_image_alt":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_image_caption":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_metadata":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"filename":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"filesize":{"type":"long"},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"sizes":{"properties":{"full":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"large":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"medium":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"thumbnail":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"xlarge":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"xxlarge":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}}}},"type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}}}},"attachment_filesize":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_image_alt":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_image_caption":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"attachment_metadata":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"filename":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"filesize":{"type":"long"},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"sizes":{"properties":{"full":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"large":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"medium":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"thumbnail":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"xlarge":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"xxlarge":{"properties":{"file":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"height":{"type":"long"},"mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}}}},"type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"width":{"type":"long"}}},"author_id":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"comment_count":{"type":"long"},"comment_status":{"type":"boolean"},"commission":{"type":"nested","properties":{"commission_amount":{"type":"float"},"commission_notes":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"commission_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"commission_unit":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}}}},"cookie_duration":{"type":"long"},"currency":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"duration_months":{"type":"long"},"guid":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"id":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"inserted_at":{"type":"date"},"menu_order":{"type":"long"},"min_payout_threshold":{"type":"long"},"payment_cycle":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"payment_method":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"ping_status":{"type":"boolean"},"post_content":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"post_date":{"type":"date"},"post_excerpt":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"post_mime_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"post_name":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"post_status":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"post_title":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"post_type":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"region":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"updated_at":{"type":"date"}}}}
    """
  end
end
