defmodule Moly.Contents.PostMeta do
  use Ash.Resource,
    otp_app: :moly,
    domain: Moly.Contents,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer

  import Moly.Helper, only: [remove_object: 1]

  postgres do
    table "post_meta"
    repo(Moly.Repo)

    custom_statements do
      statement :meta_value_idx do
        up("CREATE INDEX meta_value_idx ON post_meta (substring(meta_value FROM 1 FOR 16));")

        down("DROP INDEX meta_value_idx;")
      end
    end
  end

  actions do
    read :read do
      primary? true
      pagination offset?: true, keyset?: true, required?: false
    end

    create :create do
      accept [:meta_key, :meta_value]
      argument :post, :uuid, allow_nil?: false
      change manage_relationship(:post, :post, type: :append_and_remove)
    end

    create :create_post_meta do
      primary? true
      accept [:meta_key, :meta_value]
    end

    update :update do
      primary? true
      accept [:meta_key, :meta_value]
    end

    destroy :destroy do
      primary? true
      change after_action(&remove_attachment/3)
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :meta_key, :string do
      allow_nil? false
    end

    attribute :meta_value, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :post, Moly.Contents.Post, allow_nil?: false

    has_many :children, Moly.Contents.PostMeta do
      manual Moly.Contents.Relations.PostMetaChildren
    end
  end

  identities do
  end

  defp remove_attachment(_changeset, postmeta, _context) do
    meta_key = to_string(postmeta.meta_key)

    if meta_key == "attached_file" do
      remove_object(postmeta.meta_value)
      {:ok, postmeta}
    else
      {:ok, postmeta}
    end
  end
end
