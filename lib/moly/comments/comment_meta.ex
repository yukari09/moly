defmodule Moly.Comments.CommentMeta do
  use Ash.Resource,
    otp_app: :moly,
    domain: Moly.Comments,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "comment_meta"
    repo(Moly.Repo)
  end

  actions do
    read :read do
      primary? true
      prepare build(sort: [inserted_at: :desc])
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :meta_key, :string do
      allow_nil? true
    end

    attribute :meta_value, :string do
      allow_nil? true
    end

    timestamps(public?: true)
  end

  relationships do
    belongs_to :comment, Moly.Comments.Comment
  end

  identities do
    identity :meta_key_with_comment_id, [:meta_key, :comment_id]
  end
end
