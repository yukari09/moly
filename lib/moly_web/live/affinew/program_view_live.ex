defmodule MolyWeb.Affinew.ProgramViewLive do
  use MolyWeb, :live_view

  require Ash.Query

  import MolyWeb.Affinew.Components

  def mount(_params, _session, socket) do
    {:ok, socket, layout: {MolyWeb.Layouts, :affinew}}
  end
end
