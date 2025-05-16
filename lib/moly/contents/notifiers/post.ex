defmodule Moly.Contents.Notifiers.Post do
  use Ash.Notifier

  require Ash.Query
  require Logger

  def notify(%Ash.Notifier.Notification{action: %{type: type}, data: data}) when type in [:create, :update] do
    Moly.Contents.PostEs.build_document_index_by_id(data.id)
  end

  def notify(%Ash.Notifier.Notification{action: %{type: :destroy}, data: data}) do
    Moly.Contents.PostEs.delete_document(data.id)
  end


end
