defmodule Moly.Contents.Relations.PostMetaChildren do
  use Ash.Resource.ManualRelationship
  require Ash.Query

  def load(records, _opts, %{query: _query} = context) do
    post_ids =
      Enum.filter(records, fn
        %{meta_value: meta_value} ->
          case Ecto.UUID.dump(meta_value)  do
            {:ok, _} -> true
            _ -> false
          end
      end)
      |> Enum.reduce([], &(&2 ++ String.split(&1.meta_value, ",")))

    opts = Ash.Context.to_opts(context)

    result =
      Moly.Contents.PostMeta
      |> Ash.Query.filter(post_id in ^post_ids)
      |> Ash.read!(opts)

    return_result =
      Enum.reduce(records, %{}, fn record, acc ->
        record_id = record.id
        record_meta_value = String.split(record.meta_value, ",")
        child = Enum.filter(result, &(&1.post_id in record_meta_value))
        Map.put(acc, record_id, child)
      end)

    {:ok, return_result}
  end
end
