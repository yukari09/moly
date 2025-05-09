defmodule MolyWeb.DaisyUi do
  use Phoenix.Component

  # alias Phoenix.LiveView.JS

  import Moly.Utilities.Account, only: [user_avatar: 2, user_name: 2]

  attr(:user, Moly.Accounts.User, default: nil)
  attr(:size, :integer, default: 32)
  attr(:class, :string, default: nil)

  def avatar(%{user: nil} = assigns) do
    ~H"""
    <div class="avatar avatar-placeholder">
      <div class="bg-neutral text-neutral-content w-12 rounded-full">
        <span></span>
      </div>
    </div>
    """
  end

  def avatar(%{size: size, user: user} = assigns) do
    assigns = assign(assigns, :user_avatar_src, user_avatar(user, "#{size}"))

    ~H"""
    <div :if={@user_avatar_src} class="avatar">
      <div class={["rounded-full size-full", @class]}>
        <img src={@user_avatar_src} />
      </div>
    </div>
    <div :if={!@user_avatar_src} class="avatar avatar-placeholder size-full cursor-pointer">
      <div class="bg-neutral text-neutral-content rounded-full ">
        <span class="uppercase">{user_name(@user, 1)}</span>
      </div>
    </div>
    """
  end


  attr(:rows, :list, required: true)
  attr(:class, :string, default: nil)
  attr(:tbody_class, :string, default: "divide-y divide-gray-200 bg-white")

  slot :col, required: true do
    attr(:label, :string, required: true)
    attr(:field, :any)
    attr(:class, :string)
    attr(:td_class, :string)
    attr(:sortable, :boolean)
    attr(:sort_by, :any)
    attr(:align, :string)
    attr(:hidden, :boolean)
    attr(:width, :string)
    # For screen reader only labels
    attr(:sr_label, :string)
  end

  def table(assigns) do
    ~H"""
    <table class={["table", @class]}>
      <thead>
        <tr>
          <th
          :for={col <- @col}
          :if={!Map.get(col, :hidden, false)}
          class={[
            col[:align] == "right" && "text-right",
            col[:align] == "center" && "text-center",
            col[:align] != "right" && col[:align] != "center" && "text-left",
            Map.get(col, :sortable, false) && "cursor-pointer",
            col[:class]
          ]}
          style={col[:width] && "width: #{col[:width]}"}
          >
            <span :if={col[:sr_label]} class="sr-only">{col.sr_label}</span>
            <span :if={!col[:sr_label]}>{col.label}</span>
            <span :if={ Map.get(col, :sortable, false)} class="ml-2 inline-flex">↑↓</span>
          </th>
        </tr>
      </thead>
      <tbody class={@tbody_class}>
        <tr :for={row <- @rows}>
          <td
            :for = {col <- @col}
            :if={!Map.get(col, :hidden, false)}
            class={[
              col[:align] == "right" && "text-right",
              col[:align] == "center" && "text-center",
              col[:td_class]
            ]}
          >{render_slot(col, row)}</td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr :size, :string, default: "md"
  attr :color, :string, default: nil
  attr :soft?, :boolean, default: false
  attr :outline?, :boolean, default: false
  attr :dash?, :boolean, default: false
  attr :ghost?, :boolean, default: false
  slot :inner_block
  def badge(assigns) do
    ~H"""
    <div class={[
      "badge",
      "badge-#{@size}",
      @color && "badge-#{@color}",
      @soft? && "badge-soft",
      @outline? && "badge-outline",
      @ghost? && "badge-ghost",
    ]}>{render_slot(@inner_block)}</div>
    """
  end


  @doc """
  Renders a tooltip component.

  ## Examples
      <.tooltip>
        <.button>Hover me</.button>
      </.tooltip>

      <.tooltip tip="Custom message" color="primary" open={true} position="top">
        <.button>Hover me</.button>
      </.tooltip>
  """
  attr :tip, :string, default: "hello"
  attr :color, :string, default: nil
  attr :position, :string, default: nil # top, bottom, left, right
  attr :open, :boolean, default: false
  attr :responsive, :boolean, default: false
  attr :class, :string, default: nil
  slot :inner_block, required: true
  slot :content

  def tooltip(assigns) do
    ~H"""
    <div class={[
      "tooltip",
      @responsive && "lg:tooltip",
      @open && "tooltip-open",
      @position && "tooltip-#{@position}",
      @color && "tooltip-#{@color}",
      @class
    ]} data-tip={@tip}>
        <div :if={@content} class="tooltip-content">
          <%= render_slot(@content) %>
        </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a tabs component.

  ## Examples
      <.tabs name="my_tabs">
        <:tab label="Tab 1">Content 1</:tab>
        <:tab label="Tab 2" checked>Content 2</:tab>
        <:tab label="Tab 3">Content 3</:tab>
      </.tabs>
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :box?, :boolean, default: false
  attr :border?, :boolean, default: false
  attr :lift?, :boolean, default: false

  slot :tab, required: true do
    attr :label, :string, required: true
    attr :checked, :boolean
    attr :disabled, :boolean
  end

  def tabs(assigns) do
    ~H"""
    <div class={[
      "tabs",
      @box? && "tabs-box",
      @border? && "tabs-border",
      @lift? && "tabs-lift",
      @class
    ]} role="tablist">
      <template :for={{tab, i} <- Enum.with_index(@tab)}>
      <input
        type="radio"
        name={@name}
        class="tab"
        aria-label={tab.label}
        checked={tab.checked}
        disabled={tab.disabled}
      />
      <div class="tab-content border-base-300 bg-base-100 p-10">
        {render_slot(tab)}
      </div>
      </template>
    </div>
    """
  end

  def header(assigns) do
    ~H"""
      <div class="flex items-center">
        <h3 class="font-medium text-lg">{@title}</h3>
        <div class="breadcrumbs max-w-xs text-sm ml-auto">
          <ul>
            <li :for={{text, url} <- @items}>
              <.link :if={url} navigate={url}>{text}</.link>
              <%=if !url do%>{text}<% end %>
            </li>
          </ul>
        </div>
      </div>
    """
  end
end
