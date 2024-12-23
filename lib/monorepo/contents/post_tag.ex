defmodule Monorepo.Contents.PostTag do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Contents,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "posts_tags"
    repo(Monorepo.Repo)
  end

  actions do
    defaults [:read]
  end

  attributes do
    uuid_primary_key :id
    timestamps()
  end

  relationships do
    belongs_to :post, Monorepo.Contents.Post
    belongs_to :tag, Monorepo.Tags.Tag
  end
end
