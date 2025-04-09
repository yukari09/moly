defmodule MolyWeb.Admin do
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def live_view() do
    quote do
      use MolyWeb, :live_view
      require Ash.Query

      import Ash.Expr
      import Moly.Helper
      import MolyWeb.TailwindUI
    end
  end

  def live_component() do
    quote do
      use MolyWeb, :live_component
      require Ash.Query

      import Ash.Expr
      import Moly.Helper
      import MolyWeb.TailwindUI
    end
  end

  def topic(topic_name) when is_atom(topic_name) do
    topics = [
      post: "channel:admin:post",
      media: "channel:admin:media",
      user: "channel:admin:user",
      comment: "channel:admin:comment",
      page: "channel:admin:page"
    ]



    Keyword.fetch!(topics, topic_name)
  end
end
