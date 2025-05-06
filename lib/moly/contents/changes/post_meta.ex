defmodule Moly.Contents.Changes.PostMeta do
  require Ash.Query

  def add_meta(%{arguments: %{metas: metas}} = _changeset, post, context) do
    metas = Enum.map(metas, &Map.put(&1, :post, post.id))

    %Ash.BulkResult{status: :success} =
      Ash.bulk_create!(metas, Moly.Contents.PostMeta, :create, actor: context.actor)

    {:ok, post}
  end

  def delete_meta(changeset, context) do
    post_id = Ash.Changeset.get_attribute(changeset, :id)

    %Ash.BulkResult{status: :success} =
      Moly.Contents.PostMeta
      |> Ash.Query.filter(post_id == ^post_id)
      |> Ash.bulk_destroy!(:destroy, %{}, actor: context.actor, strategy: :stream)

    changeset
  end

  def change_post_name(changeset, _) do
    hash = Moly.Helper.generate_random_str()
    Ash.Changeset.force_change_attribute(changeset, :post_name, hash)
  end

  def update_media_meta(%{arguments: %{post_meta: post_meta}} = _changeset, post, context)
       when is_list(post_meta) do
    Enum.filter(post_meta, fn
      %{"id" => _id, "meta_value" => _meta_value, "_form_type" => "update"} -> true
      _ -> false
    end)
    |> Enum.map(fn %{"id" => id, "meta_value" => meta_value} ->
      changeset = %Moly.Contents.PostMeta{id: id}
      Ash.update!(changeset, %{meta_value: meta_value}, actor: context.actor)
    end)

    {:ok, post}
  end
end
