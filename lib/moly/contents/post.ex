defmodule Moly.Contents.Post do
  use Ash.Resource,
    otp_app: :moly,
    domain: Moly.Contents,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer,
    notifiers: [Moly.Contents.Notifiers.Post]

  require Ash.Query

  postgres do
    table "posts"
    repo(Moly.Repo)

    custom_indexes do
      index [:post_status], name: "post_status_idx"
    end

    custom_statements do
      statement :pgweb_idx do
        up(
          "CREATE INDEX pgweb_idx ON posts USING GIN (to_tsvector('english', post_title || ' ' || post_content));"
        )

        down("DROP INDEX pgweb_idx;")
      end
    end
  end

  rbac do
    role :user do
      fields([
        :post_title,
        :post_name,
        :post_type,
        :post_content,
        :post_status,
        :post_mime_type,
        :guid,
        :inserted_at,
        :updated_at
      ])

      actions([:read, :complex_search])
    end

    role :admin do
      fields([
        :post_title,
        :post_name,
        :post_type,
        :post_content,
        :post_status,
        :post_mime_type,
        :guid,
        :inserted_at,
        :updated_at
      ])

      actions([
        :read,
        :create_media,
        :destroy_media,
        :update_media,
        :update_post_status,
        :create_post,
        :update_post,
        :destroy_post,
        :complex_search
      ])
    end

    role :owner do
      fields([
        :post_title,
        :post_name,
        :post_type,
        :post_content,
        :post_status,
        :post_mime_type,
        :guid,
        :inserted_at,
        :updated_at
      ])

      actions([
        :read,
        :create_media,
        :destroy_media,
        :update_media,
        :create_post,
        :update_post_status,
        :update_post,
        :destroy_post
      ])
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
      accept [
        :post_title,
        :post_content,
        :post_type,
        :post_status,
        :post_name,
        :post_excerpt,
        :guid,
        :post_date
      ]

      argument :post_meta, {:array, :map}
      argument :categories, {:array, :uuid}
      argument :tags, {:array, :map}

      change manage_relationship(:post_meta, :post_meta, type: :create)
      change relate_actor(:author)

      change after_action(&Moly.Contents.Changes.PostCategoryTag.term_relationships/3)
    end

    update :update_post do
      require_atomic? false

      accept [
        :post_title,
        :post_content,
        :post_type,
        :post_status,
        :post_name,
        :post_excerpt,
        :guid,
        :post_date
      ]

      argument :post_meta, {:array, :map}
      argument :categories, {:array, :uuid}
      argument :tags, {:array, :map}

      change manage_relationship(:post_meta, :post_meta,
               on_no_match: :create,
               on_match: :update,
               on_lookup: :relate,
               on_missing: :destroy
             )

      change relate_actor(:author)

      change after_action(&Moly.Contents.Changes.PostCategoryTag.term_relationships/3)
    end

    update :update_media do
      require_atomic? false
      accept [:post_title, :post_content]

      argument :post_meta, {:array, :map} do
        allow_nil? false
      end

      change after_action(&update_media_meta/3)
    end

    update :update_post_status do
      require_atomic? false
      accept [:post_status]
    end

    create :create_media do
      accept [:post_title, :post_mime_type, :guid, :post_content]

      argument :metas, {:array, :map} do
        allow_nil? false
      end

      change set_attribute(:post_type, :attachment)
      change set_attribute(:post_status, :inherit)
      change set_attribute(:post_date, DateTime.utc_now())
      change &change_post_name/2
      change relate_actor(:author)

      change after_action(&add_meta/3)
    end

    destroy :destroy_post do
      soft? true
      change atomic_update(:post_status, :trash)
    end

    destroy :destroy_media do
      require_atomic? false
      change before_action(&delete_meta/2)
    end

    read :complex_search do
      argument :search_text, :string
      modify_query {Moly.Contents.Post.SearchMod, :modify, []}

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

      validations(
        one_of: [:publish, :future, :draft, :pending, :private, :trash, :auto_draft, :inherit]
      )
    end

    attribute :post_type, :atom do
      allow_nil? false
      default :post

      validations(
        one_of: [
          :post,
          :affiliate,
          :page,
          :attachment,
          :revision,
          :nav_menu_item,
          :product,
          :portfolio,
          :event
        ]
      )
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

    attribute :post_date, :utc_datetime do
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
    belongs_to :author, Moly.Accounts.User,
      allow_nil?: false,
      source_attribute: :author_id,
      relationship_context: %{private: %{ash_authentication?: true}}

    belongs_to :parent, Moly.Contents.Post, source_attribute: :post_parent, allow_nil?: true

    has_many :post_meta, Moly.Contents.PostMeta
    has_many :posts, Moly.Contents.Post, destination_attribute: :post_parent

    many_to_many :term_taxonomy, Moly.Terms.TermTaxonomy, through: Moly.Terms.TermRelationships

    has_many :post_actions, Moly.Accounts.UserPostAction

    has_many :post_categories, Moly.Terms.Term do
      manual Moly.Contents.Relations.PostCategories
      filter expr(term_taxonomy.taxonomy == "category")
    end

    has_many :post_tags, Moly.Terms.Term do
      manual Moly.Contents.Relations.PostTags
      filter expr(term_taxonomy.taxonomy == "post_tag")
    end

    # only for affiliate
    has_many :affiliate_categories, Moly.Terms.Term do
      manual Moly.Contents.Relations.PostCategories
      filter expr(term_taxonomy.taxonomy == "affiliate_category")
    end

    # only for affiliate
    has_many :affiliate_tags, Moly.Terms.Term do
      manual Moly.Contents.Relations.PostTags
      filter expr(term_taxonomy.taxonomy == "affiliate_tag")
    end
  end

  calculations do
    # calculate :commission_min,
    #           :integer,
    #           expr(
    #             first(:post_meta,
    #               field: :meta_value,
    #               query: [filter: expr(meta_key == :commission_min)]
    #             )
    #           )

    # calculate :commission_max,
    #           :integer,
    #           expr(
    #             first(:post_meta,
    #               field: :meta_value,
    #               query: [filter: expr(meta_key == :commission_max)]
    #             )
    #           )

    # calculate :commission_avg, :integer, expr((commission_min + commission_max) / 2)
  end

  identities do
    identity :unique_post_name, [:post_name]
  end

  defp add_meta(%{arguments: %{metas: metas}} = _changeset, post, context) do
    metas = Enum.map(metas, &Map.put(&1, :post, post.id))

    %Ash.BulkResult{status: :success} =
      Ash.bulk_create!(metas, Moly.Contents.PostMeta, :create, actor: context.actor)

    {:ok, post}
  end

  defp delete_meta(changeset, context) do
    post_id = Ash.Changeset.get_attribute(changeset, :id)

    %Ash.BulkResult{status: :success} =
      Moly.Contents.PostMeta
      |> Ash.Query.filter(post_id == ^post_id)
      |> Ash.bulk_destroy!(:destroy, %{}, actor: context.actor, strategy: :stream)

    changeset
  end

  defp change_post_name(changeset, _) do
    hash = Moly.Helper.generate_random_str()
    Ash.Changeset.force_change_attribute(changeset, :post_name, hash)
  end

  defp update_media_meta(%{arguments: %{post_meta: post_meta}} = _changeset, post, context)
       when is_list(post_meta) do
    Enum.filter(post_meta, fn
      %{"id" => _id, "meta_value" => _meta_value, "_form_type" => "update"} -> true
      _ -> false
    end)
    |> Enum.map(fn %{"id" => id, "meta_value" => meta_value} ->
      changeset = %Moly.Contents.PostMeta{id: id}
      Ash.update!(changeset, %{meta_value: meta_value}, actor: context.actor)
    end)

    {:ok, post}
  end
end

defmodule Moly.Contents.Post.SearchMod do
  require Ecto.Query

  def modify(ash_query, data_layer_query) do
    {:ok,
     Ecto.Query.where(
       data_layer_query,
       [p],
       fragment(
         "? @@ plainto_tsquery('english', ?)",
         fragment("to_tsvector('english', ? || ' ' || ?)", p.post_title, p.post_content),
         ^ash_query.arguments.search_text
       )
     )}
  end
end
