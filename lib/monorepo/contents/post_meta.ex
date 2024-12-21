defmodule Monorepo.Contents.PostMeta do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Contents,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "post_metas"
    repo(Monorepo.Repo)
  end

  attributes do
    uuid_primary_key :id

    attribute :meta_key, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :post, Monorepo.Contents.Post
  end
end
