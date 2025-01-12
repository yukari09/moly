defmodule MonorepoWeb.Admin do
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def live_view() do
    quote do
      use MonorepoWeb, :live_view
      require Ash.Query

      import Ash.Expr
      import Monorepo.Helper
      import MonorepoWeb.TailwindUI
    end
  end

  def live_component() do
    quote do
      use MonorepoWeb, :live_component
      require Ash.Query

      import Ash.Expr
      import Monorepo.Helper
      import MonorepoWeb.TailwindUI
    end
  end

  def topic(topic_name) when is_atom(topic_name) do
    topics = [
      post:  "channel:admin:post",
      media: "channel:admin:media",
      user:  "channel:admin:user",
      comment:  "channel:admin:comment",
    ]
    Keyword.fetch!(topics, topic_name)
  end
end
