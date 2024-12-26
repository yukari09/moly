defmodule Monorepo.Options do
  use Ash.Domain

  resources do
    resource Monorepo.Options.Option
  end
end
