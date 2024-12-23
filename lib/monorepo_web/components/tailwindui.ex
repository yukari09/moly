defmodule MonorepoWeb.TailwindUI do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import MonorepoWeb.Gettext
  import Monorepo.Helper, only: [generate_random_id: 1]



  defp hide_dropdown(menu_dom_id) do
    JS.hide(to: "##{menu_dom_id}", transition: {"transition ease-in duration-75", "transform opacity-100 scale-100", "transform opacity-0 scale-95"})
  end

  defp show_dropdown(menu_dom_id) do
    JS.show(to: "##{menu_dom_id}", transition: {"transition ease-out duration-100", "transform opacity-0 scale-95", "transform opacity-100 scale-100"})
  end

  @doc """
  Dropdown menu.
  """
  attr :id, :string, required: true
  attr :class, :string, default: nil
  slot :button_slot, required: true
  slot :menu_slot, required: true

  def dropdown(assigns) do
    menu_id = generate_random_id(8)
    button_id = generate_random_id(8)

    assigns =
      assigns
      |> assign(menu_id: menu_id)
      |> assign(button_id: button_id)

    ~H"""
    <div class={["relative", @class]} id={@id}>
      <button
        id={@button_id}
        :for={slot <- Enum.slice(@button_slot, 0, 1)}
        type="button"
        class={[
          "-m-1.5 flex items-center p-1.5",
          Map.has_key?(slot, :class) && slot.class
        ]}
        aria-expanded="false"
        aria-haspopup="true"
        phx-click={show_dropdown(@menu_id)}
      >
        { render_slot(slot) }
      </button>

      <div
        id={@menu_id}
        :for={slot <- Enum.slice(@menu_slot, 0, 1)}
        class={[
          "absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-md bg-white ring-1 shadow-lg ring-black/5 focus:outline-hidden hidden",
          # Width from menu slot or default
          Map.get(slot, :class) || "w-32"
        ]}
        role="menu"
        aria-orientation="vertical"
        aria-labelledby={@button_id}
        tabindex="-1"
        phx-click-away={hide_dropdown(@menu_id)}
      >
        { render_slot(slot) }
      </div>
    </div>
    """
  end

  attr(:type, :string, default: "button")
  attr(:class, :string, default: nil)
  attr(:variant, :string, default: "primary", values: ["primary", "secondary"])
  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        # Base styles
        "font-semibold text-sm shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2",
        # Size-specific styles
        @size == "xs" && "px-2 py-1 text-xs rounded",
        @size == "sm" && "px-2 py-1 rounded",
        @size == "md" && "px-2.5 py-1.5 rounded-md",
        @size == "lg" && "px-3 py-2 rounded-md",
        @size == "xl" && "px-3.5 py-2.5 rounded-md",
        # Variant-specific styles
        @variant == "primary" && "bg-gray-900 text-white hover:bg-gray-700 focus-visible:outline-gray-800",
        @variant == "secondary" && "bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
        # Custom classes
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Header component
  """
  attr(:title, :string, required: true)
  attr(:description, :string, default: nil)
  slot(:inner_block, required: false)

  def header(assigns) do
    ~H"""
    <div class="sm:flex sm:items-center">
      <div class="sm:flex-auto">
        <h1 class="text-2xl font-semibold text-gray-900"><%= @title %></h1>
        <p :if={@description} class="mt-2 text-sm text-gray-700"><%= @description %></p>
      </div>
      <div :if={@inner_block != []} class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr :rows, :list, required: true
  attr :class, :string, default: nil
  attr :tbody_class, :string, default: "divide-y divide-gray-200 bg-white"

  slot :col, required: true do
    attr :label, :string, required: true
    attr :field, :any
    attr :class, :string
    attr :td_class, :string
    attr :sortable, :boolean
    attr :sort_by, :any
    attr :align, :string
    attr :hidden, :boolean
    attr :width, :string
    attr :sr_label, :string  # For screen reader only labels
  end

  def table(assigns) do
    ~H"""
    <table class={["min-w-full divide-y divide-gray-300", @class]}>
      <thead>
        <tr>
          <th :for={col <- @col}
              :if={!Map.get(col, :hidden, false)}
              scope="col"
              class={[
                "py-3.5 text-sm font-semibold text-gray-900",
                "first:pl-4 first:pr-3 first:sm:pl-0",
                "last:relative last:pr-4 last:pl-3 last:sm:pr-0",
                "not-first:not-last:px-3",
                col[:align] == "right" && "text-right",
                col[:align] == "center" && "text-center",
                col[:align] != "right" && col[:align] != "center" && "text-left",
                Map.get(col, :sortable, false) && "cursor-pointer hover:bg-gray-50",
                col[:class]
              ]}
              style={col[:width] && "width: #{col[:width]}"}
          >
            <%= if col[:sr_label] do %>
              <span class="sr-only"><%= col.sr_label %></span>
            <% else %>
              <%= col.label %>
            <% end %>
            <%= if Map.get(col, :sortable, false) do %>
              <span class="ml-2 inline-flex">↑↓</span>
            <% end %>
          </th>
        </tr>
      </thead>
      <tbody class={@tbody_class}>
        <tr :for={row <- @rows}>
          <%= for col <- @col do %>
            <%= if !Map.get(col, :hidden, false) do %>
              <td class={[
                "py-5 text-sm whitespace-nowrap",
                "first:pl-4 first:pr-3 first:sm:pl-0",
                "last:relative last:pr-4 last:pl-3 last:sm:pr-0",
                "not-first:not-last:px-3",
                col[:align] == "right" && "text-right",
                col[:align] == "center" && "text-center",
                col[:td_class]
              ]}>
                <%= render_slot(col, row) %>
              </td>
            <% end %>
          <% end %>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Badge component for status indicators.
  ## Examples
      <.badge>Active</.badge>
      <.badge variant="error">Failed</.badge>
  """
  attr :variant, :string, default: "success", values: ["success", "warning", "error", "gray", "info"]
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset",
      # Variant-specific styles
      @variant == "success" && "bg-green-50 text-green-700 ring-green-600/20",
      @variant == "warning" && "bg-yellow-50 text-yellow-700 ring-yellow-600/20",
      @variant == "error" && "bg-red-50 text-red-700 ring-red-600/20",
      @variant == "gray" && "bg-gray-50 text-gray-700 ring-gray-600/20",
      @variant == "info" && "bg-blue-50 text-blue-700 ring-blue-600/20",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  @doc """
  Avatar components for displaying user images or fallback initials.

  ## Examples
      <.avatar size="sm">
        <.avatar_image src="path/to/image.jpg" alt="User avatar" />
      </.avatar>

      <.avatar size="md">
        <.avatar_fallback>
          <span>TW</span>
        </.avatar_fallback>
      </.avatar>
  """
  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"]
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def avatar(assigns) do
    ~H"""
    <span
      class={[
        "inline-block",
        # Size variants
        @size == "xs" && "size-6",
        @size == "sm" && "size-8",
        @size == "md" && "size-10",
        @size == "lg" && "size-12",
        @size == "xl" && "size-14",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  attr :src, :string, required: true
  attr :alt, :string, default: ""
  attr :class, :string, default: nil
  attr :rest, :global

  def avatar_image(assigns) do
    ~H"""
    <img
      src={@src}
      alt={@alt}
      class={[
        "size-full rounded-full",
        @class
      ]}
      style="display:none"
      onload="this.style.display=''"
      {@rest}
    />
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  attr :initials, :string, required: true

  def avatar_fallback(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex size-full items-center justify-center rounded-full bg-gray-500",
        @class
      ]}
      {@rest}
    >
      <span class="font-medium text-white">
        {@initials}
      </span>
    </span>
    """
  end


  attr :type, :string, default: "text"
  attr :name, :string, required: true
  attr :id, :string
  attr :label, :string, required: true
  attr :value, :string
  attr :placeholder, :string, default: nil
  attr :class, :string, default: nil
  attr :help_text, :string, default: nil
  attr :error, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :rest, :global
  attr :aria_label, :string, default: nil

  def input(assigns) do
    assigns = assign_new(assigns, :id, fn -> assigns.name end)

    ~H"""
    <div>
      <%= if @aria_label do %>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={@value}
          placeholder={@placeholder}
          aria-label={@aria_label}
          class={[
            "block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6",
            @error && "text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600",
            @disabled && "cursor-not-allowed bg-gray-50 text-gray-500 outline-gray-200",
            @class
          ]}
          disabled={@disabled}
          {@rest}
        />
      <% else %>
        <label for={@id} class="block text-sm/6 font-medium text-gray-900"><%= @label %></label>
        <div class={["mt-2", @error && "grid grid-cols-1"]}>
          <input
            type={@type}
            name={@name}
            id={@id}
            value={@value}
            placeholder={@placeholder}
            class={[
              "block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6",
              @error && "col-start-1 row-start-1 text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600 pr-10",
              @disabled && "cursor-not-allowed bg-gray-50 text-gray-500 outline-gray-200",
              @class
            ]}
            aria-invalid={@error != nil}
            aria-describedby={cond do
              @error -> "#{@id}-error"
              @help_text -> "#{@id}-description"
              true -> nil
            end}
            disabled={@disabled}
            {@rest}
          />
          <%= if @error do %>
            <svg class="pointer-events-none col-start-1 row-start-1 mr-3 size-5 self-center justify-self-end text-red-500 sm:size-4" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true" data-slot="icon">
              <path fill-rule="evenodd" d="M8 15A7 7 0 1 0 8 1a7 7 0 0 0 0 14ZM8 4a.75.75 0 0 1 .75.75v3a.75.75 0 0 1-1.5 0v-3A.75.75 0 0 1 8 4Zm0 8a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z" clip-rule="evenodd" />
            </svg>
          <% end %>
        </div>
        <%= if @help_text do %>
          <p class="mt-2 text-sm text-gray-500" id={"#{@id}-description"}><%= @help_text %></p>
        <% end %>
        <%= if @error do %>
          <p class="mt-2 text-sm text-red-600" id={"#{@id}-error"}><%= @error %></p>
        <% end %>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a tooltip component.

  ## Examples

      <.tooltip text="This is a tooltip" direction="top" size="sm">
        <button>Hover me</button>
      </.tooltip>
  """
  attr :text, :string, required: true
  attr :direction, :string, default: "top", values: ["top", "right", "bottom", "left"]
  attr :size, :string, default: "sm", values: ["xs", "sm", "md", "lg"]
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def tooltip(assigns) do
    # Pre-calculate spacing based on size and direction
    spacing_classes = %{
      xs: %{top: "mb-1", right: "ml-1", bottom: "mt-1", left: "mr-1"},
      sm: %{top: "mb-2", right: "ml-2", bottom: "mt-2", left: "mr-2"},
      md: %{top: "mb-2.5", right: "ml-2.5", bottom: "mt-2.5", left: "mr-2.5"},
      lg: %{top: "mb-3", right: "ml-3", bottom: "mt-3", left: "mr-3"}
    }

    # Pre-calculate positioning classes
    position_classes = %{
      top: "bottom-full left-1/2 -translate-x-1/2",
      right: "left-full top-1/2 -translate-y-1/2",
      bottom: "top-full left-1/2 -translate-x-1/2",
      left: "right-full top-1/2 -translate-y-1/2"
    }

    # Pre-calculate arrow positioning
    arrow_classes = %{
      top: "bottom-[-4px] left-1/2 -translate-x-1/2",
      right: "left-[-4px] top-1/2 -translate-y-1/2",
      bottom: "top-[-4px] left-1/2 -translate-x-1/2",
      left: "right-[-4px] top-1/2 -translate-y-1/2"
    }

    # Convert direction and size to atoms for map lookup
    assigns =
      assigns
      |> assign(:direction_atom, String.to_existing_atom(assigns.direction))
      |> assign(:size_atom, String.to_existing_atom(assigns.size))

    ~H"""
    <div class="group relative inline-block">
      <div class={[
        @direction == "top" && "mt-1",
        @direction == "right" && "ml-1",
        @direction == "bottom" && "mb-1",
        @direction == "left" && "mr-1"
      ]}>
        <%= render_slot(@inner_block) %>
      </div>
      <div class={[
        # Base classes
        "invisible absolute z-50 whitespace-nowrap rounded-md bg-gray-900 opacity-0 shadow-sm transition-all group-hover:visible group-hover:opacity-100 text-white",
        # Size-based padding and text
        case @size do
          "xs" -> "px-2 py-1 text-xs"
          "sm" -> "px-3 py-2 text-sm"
          "md" -> "px-4 py-2.5 text-base"
          "lg" -> "px-5 py-3 text-lg"
        end,
        # Position classes
        position_classes[@direction_atom],
        # Spacing classes
        spacing_classes[@size_atom][@direction_atom],
        @class
      ]}>
        <%= @text %>
        <div class={[
          "absolute h-2 w-2 rotate-45 bg-gray-900",
          arrow_classes[@direction_atom]
        ]}></div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a modal dialog component.
  """
  attr :class, :string, default: nil
  attr :inner_class, :string, default: nil
  attr :show, :boolean, default: false
  slot :header, required: false
  slot :footer, required: false
  slot :inner_block

  def modal(assigns) do
    id = generate_random_id(8)
    assigns = assign(assigns, :id, id)

    ~H"""
      <div
        id={@id}
        class={["relative z-50", @class]}
        aria-labelledby="modal-title"
        role="dialog"
        aria-modal="true"
      >
      <!--
        Background backdrop, show/hide based on modal state.

        Entering: "ease-out duration-300"
          From: "opacity-0"
          To: "opacity-100"
        Leaving: "ease-in duration-200"
          From: "opacity-100"
          To: "opacity-0"
      -->
      <div class="fixed inset-0 bg-gray-500/75 transition-opacity" aria-hidden="true"></div>

      <div class="fixed inset-0 z-50 w-screen overflow-y-auto">
        <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
          <!--
            Modal panel, show/hide based on modal state.

            Entering: "ease-out duration-300"
              From: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
              To: "opacity-100 translate-y-0 sm:scale-100"
            Leaving: "ease-in duration-200"
              From: "opacity-100 translate-y-0 sm:scale-100"
              To: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
          -->
          <div
            class={[
              "relative transform overflow-hidden rounded-lg bg-white px-4 pt-5 pb-4 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-sm sm:p-6",
              @inner_class
            ]}
          >
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </div>
    </div>
    """
  end


end
