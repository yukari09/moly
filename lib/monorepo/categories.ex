defmodule Monorepo.Categories do
  use Ash.Domain

  resources do
    resource Monorepo.Categories.Category
  end
end
