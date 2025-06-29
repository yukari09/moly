defmodule Moly.Contents do
  use Ash.Domain, extensions: [AshJsonApi.Domain]

  resources do
    resource Moly.Contents.Post do
      define :create_media, action: :create_media
    end

    resource Moly.Contents.PostMeta do
      define :create_meta, action: :create
    end
  end

  json_api do
    routes do
      # in the domain `base_route` acts like a scope
      base_route "/posts", Moly.Contents.Post do
        get :read
      end
    end
  end
end
