defmodule Monorepo.Contents do
  use Ash.Domain

  resources do
    resource Monorepo.Contents.Post
    resource Monorepo.Contents.PostTag
    resource Monorepo.Contents.PostMeta
  end
end
