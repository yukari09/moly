defmodule Monorepo.Contents do
  use Ash.Domain

  resources do
    resource Monorepo.Contents.Post do
      define :create_media, action: :create_media
    end

    resource Monorepo.Contents.PostMeta do
      define :create_meta, action: :create
    end
  end
end
