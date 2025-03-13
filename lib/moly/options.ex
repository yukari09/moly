defmodule Moly.Options do
  use Ash.Domain

  resources do
    resource Moly.Options.Option
  end
end
