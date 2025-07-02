defmodule Moly.GraphqlSchema do
  use Absinthe.Schema

  import_types Absinthe.Plug.Types

  # Add your domains here
  use AshGraphql,
    domains: [Moly.Contents, Moly.Accounts]

  query do
    # Custom absinthe queries can be placed here
    @desc "Remove me once you have a query of your own!"
    field :remove_me, :string do
      resolve fn _, _, _ ->
        {:ok, "Remove me!"}
      end
    end
  end

  mutation do
    field :upload_media, :post do
      arg :file, non_null(:upload)

      resolve fn args, context ->
        %{context: %{actor: actor}} = context
        Moly.Helper.plug_upload_to_phoenix_liveview_upload_entry(args.file)
        |> Moly.Helper.create_media_post_by_entry(args.file.path, actor)
        |> case do
          :error -> {:error, "Failed to create media post"}
          {:ok, _, post} ->
            {:ok, post}
        end
      end
    end
  end
end
