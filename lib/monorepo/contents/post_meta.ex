defmodule Monorepo.Contents.PostMeta do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Contents,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer

  import Monorepo.Helper, only: [remove_object: 1]

  postgres do
    table "post_meta"
    repo(Monorepo.Repo)
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

    update :update do
      primary? true
      accept [:meta_key, :meta_value]
    end

    destroy :destroy do
      change after_action(&remove_attachment/3)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :meta_key, :atom do
      length(min: 1, max: 255)
      allow_nil? false
    end

    attribute :meta_value, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :post, Monorepo.Contents.Post, allow_nil?: false
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end

  defp remove_attachment(_changeset, postmeta, _context) do
    meta_key = postmeta.meta_key
    if meta_key == :attached_file do
      remove_object(postmeta.meta_value)
      {:ok, postmeta}
    else
      {:ok, postmeta}
    end
  end
end
