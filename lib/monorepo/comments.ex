defmodule Monorepo.Comments do
  use Ash.Domain

  resources do
    resource Monorepo.Comments.Comment
    resource Monorepo.Comments.CommentMeta
  end
end
