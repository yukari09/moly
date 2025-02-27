defmodule Monorepo.Utilities.Page do
  use MonorepoWeb, :html

  require Ash.Query

  alias Monorepo.Contents.Post


  def page_layout(%Post{id: id, post_meta: post_meta} = post) when is_binary(id) and is_list(post_meta) do

  end


end
