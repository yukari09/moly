defmodule Moly.Comments.Comment do
  use Ash.Resource,
    otp_app: :moly,
    domain: Moly.Comments,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "comments"
    repo(Moly.Repo)
  end

  rbac do
    role :user do
      fields([:comment_content, :inserted_at, :updated_at])
      actions([:read])
    end

    role :admin do
      fields([
        :comment_content,
        :inserted_at,
        :updated_at,
        :comment_author_email,
        :comment_author_url,
        :comment_author_ip,
        :comment_type,
        :comment_approved,
        :inserted_at,
        :updated_at
      ])

      actions([:read, :update, :create, :destroy])
    end
  end

  actions do
    read :read do
      primary? true
      prepare build(sort: [inserted_at: :desc])

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :comment_content, :string do
      allow_nil? false
      public? true
    end

    attribute :comment_author_email, :string do
      allow_nil? false
      length(min: 1, max: 100)
    end

    attribute :comment_author_url, :string do
      allow_nil? false
      length(min: 1, max: 100)
    end

    attribute :comment_author_ip, :string do
      allow_nil? false
      length(min: 1, max: 100)
    end

    attribute :comment_type, :atom do
      allow_nil? false
      default :comment
      validations(one_of: [:comment, :pingback, :trackback])
    end

    attribute :comment_approved, :boolean do
      allow_nil? false
      default false
    end

    timestamps(public?: true)
  end

  relationships do
    belongs_to :comment_author, Moly.Accounts.User
    has_many :comment_meta, Moly.Comments.CommentMeta
    belongs_to :comment_post, Moly.Contents.Post
    belongs_to :comment_parent, Moly.Comments.Comment
  end
end
