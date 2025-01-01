defmodule MonorepoWeb.Admin do
  defmacro __using__(_opts) do
    quote do
      use MonorepoWeb, :live_view

      require Ash.Query

      import Ash.Expr
      import Monorepo.Helper
      import MonorepoWeb.TailwindUI

    end
  end
end
