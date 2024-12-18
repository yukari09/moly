defmodule Monorepo.Blog do
  use Ash.Domain

  resources do
    resource(Monorepo.Blog.Category)
    resource(Monorepo.Blog.Post)
  end

  # admin do
  #   show? true
  # end
end
