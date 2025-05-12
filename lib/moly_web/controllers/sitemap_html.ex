defmodule MolyWeb.SitemapHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use MolyWeb, :html

  embed_templates("sitemap_html/*")
end
