defmodule Moly.Comments do
  use Ash.Domain

  resources do
    resource Moly.Comments.Comment
    resource Moly.Comments.CommentMeta
  end
end
