defmodule Monorepo.Contents.Post do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Contents,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "posts"
    repo(Monorepo.Repo)
  end

  # rbac do
  #   role :user do
  #     fields([:tag_name, :inserted_at, :updated_at])
  #     actions([:read])
  #   end

  #   role :admin do
  #     fields([:tag_name, :inserted_at, :updated_at, :is_deleted])
  #     actions([:read, :create])
  #   end
  # end

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

    attribute :post_title, :string do
      allow_nil? false
      public? true
    end

    attribute :post_content, :string do
      allow_nil? false
      public? true
    end

    attribute :post_excerpt, :string do
      allow_nil? false
      length(min: 1, max: 1000)
    end

    attribute :post_status, :atom do
      allow_nil? false
      default :draft
      validations(one_of: [:draft, :published, :archived])
    end

    attribute :post_type, :atom do
      allow_nil? false
      default :post
      validations(one_of: [:post, :page, :nav_menu_item])
    end

    attribute :comment_status, :boolean do
      allow_nil? false
      default false
    end

    attribute :ping_status, :boolean do
      allow_nil? false
      default false
    end

    attribute :to_ping, {:array, :string} do
      allow_nil? false
      default []
    end

    attribute :pinged, {:array, :string} do
      allow_nil? false
      default []
    end

    attribute :post_parent, :uuid do
      allow_nil? false
      default nil
    end

    attribute :menu_order, :integer do
      allow_nil? false
      default 0
    end

    attribute :post_mime_type, :string do
      allow_nil? false
      default "post"
    end

    attribute :comment_count, :integer do
      allow_nil? false
      default 0
    end

    attribute :post_password, :string do
      allow_nil? false
      default ""
    end

    attribute :post_name, :string do
      allow_nil? false
      length(min: 1, max: 200)
      default ""
    end

    attribute :post_content_filtered, :string do
      allow_nil? false
      default ""
    end

    timestamps()
  end

  relationships do
    belongs_to :author, Monorepo.Accounts.User
    has_many :post_meta, Monorepo.Contents.PostMeta

    many_to_many :term_taxonomy, Monorepo.Terms.TermTaxonomy,
      through: Monorepo.Terms.TermRelationships
  end

  identities do
    identity :unique_title, [:post_name]
  end
end
