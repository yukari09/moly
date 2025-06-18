defmodule Moly.EsIndex do

  defmacro __using__(opts) do
    quote do
      @name  unquote(Keyword.fetch!(opts, :name))
      @mapping_file  unquote(Keyword.fetch!(opts, :mapping_file))
      def index_name do
        [Moly.Cluster.config() |> Keyword.get(:prefix), @name]
        |> Enum.join("-")
      end
      def create do
        mapping_json =
          Application.app_dir(:moly)
          |> Path.join(@mapping_file)
          |> File.read!()
          |> JSON.decode!()
        Moly.Cluster |> Snap.Indexes.create(index_name(), mapping_json)
      end
      def delete_index, do: Moly.Cluster |> Snap.Indexes.delete(index_name())
      def get_mapping, do: Moly.Cluster |> Snap.Indexes.get_mapping(index_name())
      def update_mapping(new_mapping), do: Moly.Cluster |> Snap.Indexes.create(index_name(), new_mapping)
      def refresh, do: Moly.Cluster |> Snap.Indexes.refresh(index_name())

      def document_index(document, id), do: Snap.Document.index(Moly.Cluster, index_name(), document, id)

      def delete_document(id) do
        Snap.Document.delete(Moly.Cluster, index_name(), id)
      end

      def get_document(id) do
        Snap.Document.get(Moly.Cluster, index_name(), id)
      end

      def es_query_result(query) do
        case Snap.Search.search(Moly.Cluster, index_name(), query) do
          {:ok, %{hits: %{total: %{"value" => total}, hits: hits}}} ->
            case hits do
              [] -> nil
              result -> [total, result]
            end
          _ ->
            nil
        end
      end

      def es_query_aggregation(query) do
        case Snap.Search.search(Moly.Cluster, index_name(), query) do
          {:ok, %{aggregations: aggregations}} ->
            aggregations
          _ ->
            nil
        end
      end
    end
  end
end
