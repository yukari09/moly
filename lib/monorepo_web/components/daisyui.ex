defmodule MonorepoWeb.DaisyUi do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import MonorepoWeb.Gettext
  # import Monorepo.Helper, only: [generate_random_id: 1]
  # import MonorepoWeb.CoreComponents, only: [translate_error: 1]
  import MonorepoWeb.CoreComponents, only: [icon: 1]

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end


  attr(:id, :string, doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      class={[
        "alert flex items-center",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}
      {@rest}
    >
     <span class="text-white">{msg}</span>
     <button phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")} type="button" class="group text-white" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="size-5 opacity-80 group-hover:opacity-100 leading-6" />
      </button>
    </div>
    """
  end


  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id} class="relate">
      <div class="toast toast-center">
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      </div>
    </div>
    """
  end
end
