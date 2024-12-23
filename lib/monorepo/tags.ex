defmodule Monorepo.Tags do
  use Ash.Domain

  resources do
    resource Monorepo.Tags.Tag
  end
end
