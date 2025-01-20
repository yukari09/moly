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
      actions([:read, :create_media, :destroy_media, :update_media, :create_post, :update_post, :destroy_post])
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
      accept [:post_title, :post_content, :post_type, :post_status, :post_name, :post_excerpt, :guid, :post_date]

      argument :post_meta, {:array, :map}
      argument :categories, {:array, :uuid}
      argument :tags, {:array, :map}

      change manage_relationship(:post_meta, :post_meta, type: :create)
      change relate_actor(:author)

      change after_action(&create_or_update_term_relationships/3)
    end

    update :update_post do
      require_atomic? false
      accept [:post_title, :post_content, :post_type, :post_status, :post_name, :post_excerpt, :guid, :post_date]

      argument :post_meta, {:array, :map}
      argument :categories, {:array, :uuid}
      argument :tags, {:array, :map}

      change manage_relationship(:post_meta, :post_meta, type: :direct_control)
      change relate_actor(:author)

      change after_action(&create_or_update_term_relationships/3)
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

    destroy :destroy_post do
      soft? true
      change atomic_update(:post_status, :trash)
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

    has_many :post_categories, Monorepo.Terms.Term do
      manual Monorepo.Contents.Relations.PostCategories
    end

    has_many :post_tags, Monorepo.Terms.Term do
      manual Monorepo.Contents.Relations.PostTags
    end
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

  defp create_or_update_term_relationships(%{arguments: arguments}, post, context) do
    categories = Map.get(arguments, :categories, [])
    tags = Map.get(arguments, :tags, [])

    term_names = Enum.map(tags, & &1["name"])

    old_term_relationships =
      Monorepo.Terms.TermRelationships
      |> Ash.Query.filter(post_id == ^post.id)
      |> Ash.read!(actor: context.actor)

    Ash.bulk_destroy!(old_term_relationships, :destroy, %{}, actor: context.actor)

    term_taxonomy_ids = Enum.map(old_term_relationships, & &1.term_taxonomy_id)

    {:ok, term_taxonomy} =
      Monorepo.Terms.TermTaxonomy
      |> Ash.Query.filter(id in ^term_taxonomy_ids)
      |> Ash.Query.data_layer_query()

    Monorepo.Repo.update_all(term_taxonomy, [inc: [count: -1]])

    categories_term_relation_ships = Enum.map(categories, &(%{term_taxonomy_id: &1, post_id: post.id}))

    existed_tags =
      Monorepo.Terms.TermTaxonomy
      |> Ash.Query.filter(term.name in ^term_names and taxonomy == "post_tag")
      |> Ash.read!(actor: context.actor)
      |> Ash.load!([:term], actor: context.actor)

    existed_tag_names = Enum.map(existed_tags, & &1.term.name)
    rest_not_exist_tags = Enum.filter(tags, & &1["name"] not in existed_tag_names)

    rest_tags_term_relation_ships =
      if rest_not_exist_tags == [] do
        []
      else
        %Ash.BulkResult{status: :success, records: records} =
          Ash.bulk_create!(rest_not_exist_tags, Monorepo.Terms.Term, :create, actor: context.actor, return_records?: true)

        Enum.map(records, fn record ->
          term_taxonomy = record.term_taxonomy |> List.first()
          %{term_taxonomy_id: term_taxonomy.id, post_id: post.id}
        end)
      end

    tags_term_relation_ships = Enum.map(existed_tags, & %{term_taxonomy_id: &1.id, post_id: post.id})
    term_relation_ships = categories_term_relation_ships ++ tags_term_relation_ships ++ rest_tags_term_relation_ships

    %Ash.BulkResult{status: :success} =
      Ash.bulk_create!(term_relation_ships, Monorepo.Terms.TermRelationships, :create_term_relationships_by_relation_id, actor: context.actor, return_records?: true)

    term_taxonomy_ids = Enum.map(term_relation_ships, & &1.term_taxonomy_id)

    {:ok, term_taxonomy} =
      Monorepo.Terms.TermTaxonomy
      |> Ash.Query.filter(id in ^term_taxonomy_ids)
      |> Ash.Query.data_layer_query()

    Monorepo.Repo.update_all(term_taxonomy, [inc: [count: 1]])

    {:ok, post}
  end


end
