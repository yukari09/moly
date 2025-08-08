defmodule Moly.Contents do
  use Ash.Domain,
    extensions: [
      AshGraphql.Domain
    ]

  resources do
    resource Moly.Contents.Post do
      define :create_media, action: :create_media
    end

    resource Moly.Contents.PostMeta do
      define :create_meta, action: :create
    end
  end

  graphql do
    # queries do
    #   list Moly.Contents.Post, :list_posts, :read
    # end
    mutations do
      create Moly.Contents.Post, :create_post, :create_post
    end
  end
end
