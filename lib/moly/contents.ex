defmodule Moly.Contents do
  use Ash.Domain

  resources do
    resource Moly.Contents.Post do
      define :create_media, action: :create_media
    end

    resource Moly.Contents.PostMeta do
      define :create_meta, action: :create
    end
  end
end
