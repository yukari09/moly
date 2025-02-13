defmodule Monorepo.Contents.Relations.PostMetaChildren do
  use Ash.Resource.ManualRelationship
  require Ash.Query


  @meta_key  [:attachment_affiliate_media_feature, :attachment_affiliate_media]

  def load(records, _opts, %{query: _query} = context) do
    post_ids = Enum.filter(records, & &1.meta_key in @meta_key) |> Enum.map(& &1.meta_value)

    opts = Ash.Context.to_opts(context)

    result =
      Monorepo.Contents.PostMeta
      |> Ash.Query.filter(post_id in ^post_ids)
      |> Ash.read!(opts)

      return_result =
        Enum.reduce(records, %{}, fn record, acc ->
          record_id = record.id
          record_meta_value = record.meta_value
          child = Enum.filter(result, & &1.post_id == record_meta_value)
          Map.put(acc, record_id, child)
        end)

    {:ok, return_result}
  end
end
