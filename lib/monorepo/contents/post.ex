defmodule Monorepo.Contents.Post do
  require Ash.Resource.Change.Builtins
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Contents,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  require Ash.Query

  postgres do
    table "posts"
    repo(Monorepo.Repo)
  end

  rbac do
    role :user do
      fields([:post_title, :post_name, :post_type, :post_content, :post_status, :post_mime_type, :guid, :inserted_at, :updated_at])
      actions([:read])
    end

    role :admin do
      fields([:post_title, :post_name, :post_type, :post_content, :post_status, :post_mime_type, :guid, :inserted_at, :updated_at])
      actions([:read, :create_media, :destroy_media, :update_media, :create_post, :update_post])
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


    create :create_post do
      accept [:post_title, :post_content, :post_type, :post_status, :post_name]

      argument :post_meta, {:array, :map} do
        allow_nil? false
      end

      change relate_actor(:author)
    end

    create :update_post do
      accept [:post_title, :post_content, :post_type, :post_status]

      argument :post_meta, {:array, :map} do
        allow_nil? false
      end
    end


    update :update_media do
      require_atomic? false
      accept [:post_title, :post_content]

      argument :post_meta, {:array, :map} do
        allow_nil? false
      end

      change after_action(&update_media_meta/3)
    end

    create :create_media do
      accept [:post_title, :post_mime_type, :guid, :post_content]

      argument :metas, {:array, :map} do
        allow_nil? false
      end

      change set_attribute(:post_type, :attachment)
      change set_attribute(:post_status, :inherit)
      change set_attribute(:post_date,  DateTime.utc_now())
      change &change_post_name/2
      change relate_actor(:author)

      change after_action(&add_meta/3)
    end

    destroy :destroy_media do
      change before_action(&delete_meta/2)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :post_title, :string do
      allow_nil? false
      public? true
    end

    attribute :post_content, :string do
      allow_nil? true
      public? true
    end

    attribute :post_excerpt, :string do
      allow_nil? true
      length(min: 1, max: 1000)
    end

    attribute :post_status, :atom do
      allow_nil? false
      default :draft
      validations(one_of: [:publish, :future, :draft, :pending, :private, :trash, :auto_draft, :inherit])
    end

    attribute :post_type, :atom do
      allow_nil? false
      default :post
      validations(one_of: [:post, :page, :attachment, :revision, :nav_menu_item, :product, :portfolio, :event])
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

    attribute :guid, :string do
      allow_nil? true
    end

    attribute :menu_order, :integer do
      allow_nil? false
      default 0
    end

    attribute :post_mime_type, :string do
      allow_nil? false
      default "post"
    end

    attribute :post_date,  :utc_datetime do
      description "The date the post was created"
      allow_nil? false
    end

    attribute :comment_count, :integer do
      allow_nil? false
      default 0
    end

    attribute :post_password, :string do
      allow_nil? true
      default nil
    end

    attribute :post_name, :string do
      length(min: 1, max: 255)
    end

    attribute :post_content_filtered, :string do
      allow_nil? true
      default ""
    end

    timestamps()
  end

  relationships do
    belongs_to :author, Monorepo.Accounts.User, allow_nil?: false
    belongs_to :parent, Monorepo.Contents.Post, source_attribute: :post_parent, allow_nil?: true

    has_many :post_meta, Monorepo.Contents.PostMeta
    has_many :posts, Monorepo.Contents.Post, destination_attribute: :post_parent

    many_to_many :term_taxonomy, Monorepo.Terms.TermTaxonomy,
      through: Monorepo.Terms.TermRelationships
  end

  identities do
    identity :unique_post_name, [:post_name]
  end


  defp add_meta(%{arguments: %{metas: metas}} = _changeset, post, context) do
    metas = Enum.map(metas, &(Map.put(&1, :post, post.id)))
    %Ash.BulkResult{status: :success} = Ash.bulk_create!(metas, Monorepo.Contents.PostMeta, :create, actor: context.actor)
    {:ok, post}
  end

  defp delete_meta(changeset, context) do
    post_id = Ash.Changeset.get_attribute(changeset, :id)

    %Ash.BulkResult{status: :success} =
      Monorepo.Contents.PostMeta
      |> Ash.Query.filter(post_id == ^post_id)
      |> Ash.bulk_destroy!(:destroy, %{}, actor: context.actor, strategy: :stream)

    changeset
  end

  defp change_post_name(changeset, _) do
    hash = Monorepo.Helper.generate_random_str()
    Ash.Changeset.force_change_attribute(changeset, :post_name, hash)
  end

  defp update_media_meta(%{arguments: %{post_meta: post_meta}} = _changeset, post, context) when is_list(post_meta) do
    Enum.filter(post_meta, fn
      %{"id" => _id, "meta_value" => _meta_value, "_form_type" => "update"} -> true
      _ -> false
    end)
    |> Enum.map(fn %{"id" => id, "meta_value" => meta_value} ->
      changeset = %Monorepo.Contents.PostMeta{id: id}
      Ash.update!(changeset, %{meta_value: meta_value}, actor: context.actor)
    end)

    {:ok, post}
  end


end
