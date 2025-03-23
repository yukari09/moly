defmodule MolyWeb.TailwindUI do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import MolyWeb.Gettext
  import Moly.Helper, only: [generate_random_id: 1]
  import MolyWeb.CoreComponents, only: [translate_error: 1]

  ## JS Commands
  # off_canvas_menu_id  #{off_canvas_menu_id}
  def open_off_canvas_menu(js \\ %JS{}, off_canvas_menu_id) do
    js
    |> JS.transition({"transition-opacity ease-linear duration-300", "opacity-0", "opacity-100"},
      to: "##{off_canvas_menu_id}-backdrop",
      time: 300
    )
    |> JS.transition(
      {"transition ease-in-out duration-300 transform", "-translate-x-full", "translate-x-0"},
      to: "##{off_canvas_menu_id}-content-inner",
      time: 300
    )
    |> JS.transition({"ease-in-out duration-300", "opacity-0", "opacity-100"},
      to: "##{off_canvas_menu_id}-close-button",
      time: 300
    )
    |> JS.remove_class("hidden", to: "##{off_canvas_menu_id}-backdrop")
    |> JS.remove_class("hidden", to: "##{off_canvas_menu_id}-content-inner")
    |> JS.remove_class("hidden", to: "##{off_canvas_menu_id}")
  end

  def close_off_canvas_menu(js \\ %JS{}, off_canvas_menu_id) do
    js
    |> JS.add_class("hidden",
      to: "##{off_canvas_menu_id}-backdrop",
      time: 300,
      transition: {"transition-opacity ease-linear duration-300", "opacity-100", "opacity-0"}
    )
    |> JS.add_class("hidden",
      to: "##{off_canvas_menu_id}-content-inner",
      time: 300,
      transition:
        {"transition ease-in-out duration-300 transform", "translate-x-0", "-translate-x-full"}
    )
    |> JS.transition({"ease-in-out duration-300", "opacity-100", "opacity-0"},
      to: "##{off_canvas_menu_id}-close-button",
      time: 300
    )
    |> JS.add_class("hidden",
      to: "##{off_canvas_menu_id}",
      time: 300,
      transition: {"duration-300", "", ""}
    )
  end

  def hide_dropdown(menu_dom_id) do
    JS.hide(
      to: "##{menu_dom_id}",
      transition:
        {"transition ease-in duration-75", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def show_dropdown(menu_dom_id) do
    JS.show(
      to: "##{menu_dom_id}",
      transition:
        {"transition ease-out duration-100", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"}
    )
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

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

  @doc """
  Dropdown menu.
  """
  attr(:id, :string, required: true)
  attr(:class, :string, default: nil)
  slot(:button_slot, required: true)
  slot(:menu_slot, required: true)

  def dropdown(assigns) do
    menu_id = generate_random_id(8)
    button_id = generate_random_id(8)

    assigns =
      assigns
      |> assign(menu_id: menu_id)
      |> assign(button_id: button_id)

    ~H"""
    <div class={["relative overflow-visible", @class]} id={@id}>
      <button
        :for={{slot, index} <- Enum.with_index(@button_slot)}
        id={"#{@button_id}-#{index}"}
        type="button"
        class={[
          "-m-1.5 flex items-center p-1.5",
          Map.has_key?(slot, :class) && slot.class
        ]}
        aria-expanded="false"
        aria-haspopup="true"
        phx-click={show_dropdown("#{@menu_id}-#{index}")}
        disabled={Map.get(slot, :disabled, false)}
      >
        {render_slot(slot)}
      </button>

      <div
        :for={{slot, index} <- Enum.with_index(@menu_slot)}
        id={"#{@menu_id}-#{index}"}
        class={
          [
            "absolute right-0 z-10 mt-2 origin-top-right rounded-md bg-white ring-1 shadow-lg ring-black/5 focus:outline-hidden hidden divide-y divide-gray-100",
            # Width from menu slot or default
            Map.get(slot, :class, "w-32")
          ]
        }
        role="menu"
        aria-orientation="vertical"
        aria-labelledby={@button_id}
        tabindex="-1"
        phx-click-away={hide_dropdown("#{@menu_id}-#{index}")}
        data-menu-id={Map.get(slot, :"data-menu-id", "#{@menu_id}-#{index}")}
        data-id={Map.get(slot, :"data-id", "#{@menu_id}-#{index}")}
      >
        {render_slot(slot)}
      </div>
    </div>
    """
  end

  attr(:id, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:active, :boolean, default: false)
  attr(:rest, :global)
  attr(:disabled, :boolean, default: false)
  slot(:inner_block, required: true)

  def dropdown_link(assigns) do
    ~H"""
    <a
      class={[
        "block px-4 py-2 text-sm hover:bg-gray-100 hover:text-gray-900 hover:outline-none  cursor-pointer",
        @active && "bg-gray-100 text-gray-900 outline-none",
        !@active && "text-gray-700",
        @disabled && "pointer-events-none opacity-50",
        @class
      ]}
      role="menuitem"
      tabindex="-1"
      id={@id}
      disabled={@disabled}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr(:type, :string, default: "button")
  attr(:class, :string, default: nil)
  attr(:variant, :string, default: "primary", values: ["primary", "secondary", "gray", "error"])
  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])
  attr(:navigate, :string, default: nil)
  attr(:patch, :string, default: nil)
  attr(:href, :string, default: nil)
  attr(:form, :any, default: nil)
  attr(:rest, :global)
  attr(:disabled, :boolean, default: false)
  slot(:inner_block, required: true)

  def button(assigns) do
    assigns = assign_new(assigns, :form, fn -> nil end)
    assigns = assign_new(assigns, :variant, fn -> "primary" end)
    assigns = assign_new(assigns, :size, fn -> "md" end)
    assigns = assign_new(assigns, :class, fn -> [] end)
    assigns = assign_new(assigns, :disabled, fn -> false end)

    ~H"""
    <.link
      :if={@navigate || @patch || @href}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      class={
        [
          "inline-flex items-center justify-center font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
          # Size-specific styles
          @size == "xs" && "h-7 rounded-md px-2.5 text-xs",
          @size == "sm" && "h-8 rounded-md px-3 text-sm",
          @size == "md" && "h-9 rounded-md px-4 text-sm",
          @size == "lg" && "h-10 rounded-md px-4 text-sm",
          @size == "xl" && "h-11 rounded-md px-5 text-md",
          # Variant-specific styles
          @variant == "primary" &&
            "bg-gray-900 text-white hover:bg-gray-800 focus-visible:outline-gray-800",
          @variant == "secondary" &&
            "bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
          @variant == "gray" && "bg-gray-50 text-gray-900 hover:bg-gray-100 hover:text-gray-900",
          @variant == "error" &&
            "bg-red-600 text-white hover:bg-red-500 focus-visible:outline-red-500",
          (@disabled || (@form && (@form.errors != [] || @form.source.valid? == false))) &&
            "opacity-50 pointer-events-none",
          # Custom classes
          @class
        ]
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>

    <button
      :if={!@navigate && !@patch && !@href}
      type={@type}
      class={
        [
          "inline-flex items-center justify-center font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
          @form && (@form.errors != [] || @form.source.valid? == false) && "opacity-50",
          # Size-specific styles
          @size == "xs" && "h-7 rounded-md px-2.5 text-xs",
          @size == "sm" && "h-8 rounded-md px-3 text-sm",
          @size == "md" && "h-9 rounded-md px-4 text-sm",
          @size == "lg" && "h-10 rounded-md px-4 text-sm",
          @size == "xl" && "h-11 rounded-md px-5 text-md",
          # Variant-specific styles
          @variant == "primary" &&
            "bg-gray-900 text-white hover:bg-gray-800 focus-visible:outline-gray-800",
          @variant == "secondary" &&
            "bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
          @variant == "gray" && "bg-gray-50 text-gray-900 hover:bg-gray-100 hover:text-gray-900",
          @variant == "error" &&
            "bg-red-600 text-white hover:bg-red-500 focus-visible:outline-red-500",
          (@disabled || (@form && (@form.errors != [] || @form.source.valid? == false))) &&
            "opacity-50 pointer-events-none",
          # Custom classes
          @class
        ]
      }
      disabled={@disabled || (@form && (@form.errors != [] || @form.source.valid? == false))}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Header component
  """
  attr(:title, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:size, :string, default: "lg", values: ["sm", "md", "lg", "xl"])
  slot(:inner_block, required: false)

  def header(assigns) do
    ~H"""
    <div class={["sm:flex sm:items-center", @class]}>
      <div class="sm:flex-auto">
        <h3 :if={@size == "sm"} class="font-semibold text-lg text-gray-900">{@title}</h3>
        <h2 :if={@size == "md"} class="font-semibold text-xl text-gray-900">{@title}</h2>
        <h1 :if={@size == "lg"} class="font-semibold text-2xl text-gray-900">{@title}</h1>
        <h1 :if={@size == "xl"} class="font-semibold text-3xl text-gray-900">{@title}</h1>
        <p :if={@description} class="mt-2 text-sm text-gray-700">{@description}</p>
      </div>
      <div :if={@inner_block != []} class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
        {render_slot(@inner_block)}
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
    <table class={["min-w-full divide-y divide-gray-300 ", @class]}>
      <thead>
        <tr>
          <th
            :for={col <- @col}
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
              <span class="sr-only">{col.sr_label}</span>
            <% else %>
              {col.label}
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
                {render_slot(col, row)}
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
  attr(:variant, :string,
    default: "success",
    values: ["success", "warning", "error", "gray", "info"]
  )

  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def badge(assigns) do
    ~H"""
    <span
      class={
        [
          "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset",
          # Variant-specific styles
          @variant == "success" && "bg-green-50 text-green-700 ring-green-600/20",
          @variant == "warning" && "bg-yellow-50 text-yellow-700 ring-yellow-600/20",
          @variant == "error" && "bg-red-50 text-red-700 ring-red-600/20",
          @variant == "gray" && "bg-gray-50 text-gray-700 ring-gray-600/20",
          @variant == "info" && "bg-blue-50 text-blue-700 ring-blue-600/20",
          @class
        ]
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr(:badge, :string, default: nil)
  attr(:class, :string, default: nil)

  def badge_span(assigns) do
    ~H"""
    <span
      :if={@badge}
      class={[
        "hidden rounded-full bg-gray-100 px-2.5 text-xs py-0.5 font-medium text-gray-900 md:inline-block",
        @class
      ]}
    >
      {@badge}
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
  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def avatar(assigns) do
    ~H"""
    <span
      class={
        [
          "inline-block",
          # Size variants
          @size == "xs" && "size-6",
          @size == "sm" && "size-8",
          @size == "md" && "size-10",
          @size == "lg" && "size-12",
          @size == "xl" && "size-14",
          @class
        ]
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr(:src, :string, required: true)
  attr(:alt, :string, default: "")
  attr(:class, :string, default: nil)
  attr(:rest, :global)

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

  attr(:class, :string, default: nil)
  attr(:rest, :global)
  attr(:initials, :string, required: true)

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

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:type, :string, default: "text")
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:container_class, :string, default: nil)
  attr(:help_text, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:show_error, :boolean, default: true)
  attr(:value, :any, default: nil)
  attr(:field_subfix, :string, default: nil)
  attr(:rest, :global)
  attr(:aria_label, :string, default: nil)

  def input(%{field: field, field_subfix: field_subfix} = assigns) do
    error_messages = error_messages(field.errors)
    # error_messages =
    #   field.form.source.touched_forms
    #   |> MapSet.member?(field.field)
    #   |> case do
    #     true -> error_messages
    #     false -> []
    #   end
    assigns = assign(assigns, :errors, error_messages)

    assigns =
      if field_subfix do
        field = %Phoenix.HTML.FormField{
          field
          | name: "#{field.name}#{field_subfix}",
            id: "#{field.id}#{String.replace(field_subfix, ~r/\[|\]/, "_")}"
        }

        assign(assigns, :field, field)
      else
        assigns
      end

    ~H"""
    <div class={@container_class}>
      <input
        :if={@aria_label}
        type={@type}
        name={@field.name}
        id={@field.id}
        value={@value || @field.value}
        placeholder={@placeholder}
        aria-label={@aria_label}
        class={[
          "block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6 phx-submit-loading:opacity-50",
          @errors != [] &&
            "text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600",
          @class
        ]}
        {@rest}
      />
      <label :if={!@aria_label} for={@field.id} class="block text-sm/6 font-medium text-gray-900">
        {@label}
      </label>
      <div :if={!@aria_label} class={[@label && "mt-2", @errors != [] && "grid grid-cols-1"]}>
        <input
          type={@type}
          name={@field.name}
          id={@field.id}
          value={@value || @field.value}
          placeholder={@placeholder}
          class={[
            "block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900  outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6 phx-submit-loading:opacity-50",
            @errors != [] &&
              "col-start-1 row-start-1 text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600 pr-10",
            @class
          ]}
          aria-invalid={@errors != []}
          aria-describedby={
            cond do
              @errors != [] -> "#{@field.id}-error"
              @help_text -> "#{@field.id}-description"
              true -> nil
            end
          }
          {@rest}
        />
        <svg
          :if={@errors != []}
          class="pointer-events-none col-start-1 row-start-1 mr-3 size-5 self-center justify-self-end text-red-500 sm:size-4"
          viewBox="0 0 16 16"
          fill="currentColor"
          aria-hidden="true"
          data-slot="icon"
        >
          <path
            fill-rule="evenodd"
            d="M8 15A7 7 0 1 0 8 1a7 7 0 0 0 0 14ZM8 4a.75.75 0 0 1 .75.75v3a.75.75 0 0 1-1.5 0v-3A.75.75 0 0 1 8 4Zm0 8a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z"
            clip-rule="evenodd"
          />
        </svg>
      </div>
      <p
        :if={@help_text && @errors == []}
        class="mt-2 text-sm text-gray-500"
        id={"#{@field.id}-description"}
      >
        {@help_text}
      </p>
      <p
        :if={@errors != [] && @show_error}
        class="mt-2 text-sm text-red-600"
        id={"#{@field.id}-error"}
      >
        {@label} {List.first(@errors)}
      </p>
    </div>
    """
  end

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:help_text, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:value, :any, default: nil)
  attr(:field_subfix, :string, default: nil)
  attr(:rest, :global)
  attr(:rows, :integer, default: 3)
  slot(:inner_block)

  def textarea(%{field: field, value: value, field_subfix: field_subfix} = assigns) do
    error_messages = error_messages(field.errors)
    assigns = assign(assigns, :errors, error_messages)

    assigns =
      if value do
        field = %{field | value: value}
        assign(assigns, :field, field)
      else
        assigns
      end

    assigns =
      if field_subfix do
        field = %{
          field
          | name: "#{field.name}#{field_subfix}",
            id: "#{field.id}#{String.replace(field_subfix, ~r/\[|\]/, "_")}"
        }

        assign(assigns, :field, field)
      else
        assigns
      end

    ~H"""
    <div>
      <label for={@field.id} class="block text-sm/6 font-medium text-gray-900">{@label}</label>
      <div class={[@label && "mt-2", @errors != [] && "grid grid-cols-1"]}>
        <textarea
          name={@field.name}
          id={@field.id}
          placeholder={@placeholder}
          rows={@rows}
          class={[
            "block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6 phx-submit-loading:opacity-50",
            @errors != [] &&
              "col-start-1 row-start-1 text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600",
            @class
          ]}
          aria-invalid={@errors != []}
          aria-describedby={
            cond do
              @errors != [] -> "#{@field.id}-error"
              @help_text -> "#{@field.id}-description"
              true -> nil
            end
          }
          {@rest}
        ><%= Phoenix.HTML.Form.normalize_value("textarea", @field.value) %></textarea>
        <svg
          :if={@errors != []}
          class="pointer-events-none col-start-1 row-start-1 mr-3 size-5 self-start justify-self-end text-red-500 sm:size-4 mt-2"
          viewBox="0 0 16 16"
          fill="currentColor"
          aria-hidden="true"
          data-slot="icon"
        >
          <path
            fill-rule="evenodd"
            d="M8 15A7 7 0 1 0 8 1a7 7 0 0 0 0 14ZM8 4a.75.75 0 0 1 .75.75v3a.75.75 0 0 1-1.5 0v-3A.75.75 0 0 1 8 4Zm0 8a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z"
            clip-rule="evenodd"
          />
        </svg>
      </div>
      <p
        :if={@help_text && @errors == []}
        class="mt-2 text-sm text-gray-500"
        id={"#{@field.id}-description"}
      >
        {@help_text}
      </p>
      <p :if={@errors != []} class="mt-2 text-sm text-red-600" id={"#{@field.id}-error"}>
        {@label} {List.first(@errors)}
      </p>
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
  attr(:text, :string, required: true)
  attr(:direction, :string, default: "top", values: ["top", "right", "bottom", "left"])
  attr(:size, :string, default: "sm", values: ["xs", "sm", "md", "lg"])
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

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
        {render_slot(@inner_block)}
      </div>
      <div class={
        [
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
        ]
      }>
        {@text}
        <div class={[
          "absolute h-2 w-2 rotate-45 bg-gray-900",
          arrow_classes[@direction_atom]
        ]}>
        </div>
      </div>
    </div>
    """
  end

  def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-backdrop",
      time: 300,
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-panel",
      time: 300,
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-backdrop",
      time: 200,
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-panel",
      time: 200,
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
  end

  @doc """
  Renders a modal dialog component.
  """
  attr(:id, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:inner_class, :string, default: nil)
  attr(:show, :boolean, default: false)
  attr(:block_click_away, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{})
  slot(:inner_block, required: true)
  attr(:rest, :global)

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class={["hidden", @class]}
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      {@rest}
    >
      <div
        id={"#{@id}-backdrop"}
        class="fixed inset-0 bg-gray-500/75 transition-opacity z-20"
        aria-hidden="true"
      >
      </div>

      <div class="fixed inset-0 z-50 w-screen overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4 text-center sm:items-center sm:p-0">
          <div
            id={"#{@id}-panel"}
            class={[
              "relative transform overflow-hidden rounded-lg bg-white px-4 pt-5 pb-4 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-sm sm:p-6",
              @inner_class
            ]}
            phx-click-away={!@block_click_away && JS.exec("data-cancel", to: "##{@id}")}
          >
            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:button_text, :string, required: true)
  attr(:button_class, :string, required: true)
  attr(:on_confirm, JS, default: %JS{})

  def action_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel}>
      <div>
        <div class="mx-auto flex size-12 items-center justify-center rounded-full bg-green-100">
          <svg
            class="size-6 text-green-600"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            aria-hidden="true"
            data-slot="icon"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
          </svg>
        </div>
        <div class="mt-3 text-center sm:mt-5">
          <h3 class="text-base font-semibold text-gray-900" id="modal-title">{@title}</h3>
          <div class="mt-2">
            <p class="text-sm text-gray-500">{@description}</p>
          </div>
        </div>
      </div>
      <div class="mt-5 sm:mt-6">
        <.button class="w-full" phx-click={@on_confirm}>
          {@button_text}
        </.button>
      </div>
    </.modal>
    """
  end

  attr(:label, :string, required: true)
  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:value, :any, default: nil)
  attr(:field_subfix, :string, default: nil)
  attr(:options, :list, required: true)
  attr(:class, :string, default: nil)
  attr(:multiple, :boolean, default: false)
  attr(:prompt, :string, default: nil)
  attr(:rest, :global)

  def select(%{field: field, value: value, field_subfix: field_subfix} = assigns) do
    assigns =
      if value do
        field = %{field | value: value}
        assign(assigns, :field, field)
      else
        assigns
      end

    assigns =
      if field_subfix do
        field = %{
          field
          | name: "#{field.name}#{field_subfix}",
            id: "#{field.id}#{String.replace(field_subfix, ~r/\[|\]/, "_")}"
        }

        assign(assigns, :field, field)
      else
        assigns
      end

    ~H"""
    <div>
      <label for={@field.id} class="block text-sm/6 font-medium text-gray-900">{@label}</label>
      <div class={[@label && "mt-2", "grid grid-cols-1"]}>
        <select
          id={@field.id}
          name={(@multiple && "#{@field.name}[]") || @field.name}
          class={[
            "col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-1.5 pl-3 pr-8 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6 phx-submit-loading:opacity-50",
            @class
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="" disabled selected>{@prompt}</option>
          <option
            :for={{options_value, label} <- @options}
            value={options_value}
            selected={
              (is_binary(@field.value) && options_value == @field.value) ||
                (is_list(@field.value) && options_value in @field.value)
            }
          >
            {label}
          </option>
        </select>
        <svg
          class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end fill-gray-500"
          viewBox="0 0 16 16"
          fill="currentColor"
          aria-hidden="true"
          data-slot="icon"
        >
          <path
            fill-rule="evenodd"
            d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z"
            clip-rule="evenodd"
          />
        </svg>
      </div>
    </div>
    """
  end

  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:value, :string, default: nil)
  attr(:label, :string, required: false, default: nil)
  attr(:label_class, :string, required: false, default: nil)
  attr(:description, :string, default: nil)
  attr(:checked, :boolean, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def checkbox(assigns) do
    ~H"""
    <div class="flex gap-3">
      <div class="flex h-6 shrink-0 items-center">
        <div class="group grid size-4 grid-cols-1 phx-submit-loading:opacity-50">
          <input
            type="checkbox"
            id={@id || @field.id}
            name={@name || @field.name}
            checked={@checked}
            value={(is_nil(@value) && @field.value) || @value}
            class={[
              "col-start-1 row-start-1 appearance-none rounded border border-gray-300 bg-white",
              "checked:border-gray-600 checked:bg-gray-600",
              "indeterminate:border-gray-600 indeterminate:bg-gray-600",
              "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-600",
              "disabled:border-gray-300 disabled:bg-gray-100 disabled:checked:bg-gray-100",
              "forced-colors:appearance-auto",
              @class
            ]}
            {@rest}
          />
          <svg
            class="pointer-events-none col-start-1 row-start-1 size-3.5 self-center justify-self-center stroke-white group-has-[:disabled]:stroke-gray-950/25"
            viewBox="0 0 14 14"
            fill="none"
          >
            <path
              class="opacity-0 group-has-[:checked]:opacity-100"
              d="M3 8L6 11L11 3.5"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
            <path
              class="opacity-0 group-has-[:indeterminate]:opacity-100"
              d="M3 7H11"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
        </div>
      </div>
      <label class="text-sm/6 cursor-pointer flex-1" for={@id || @field.id}>
        <span :if={@label} for={@id || @field.id} class={["font-medium text-gray-900", @label_class]}>
          {@label}
        </span>
        <span :if={@description} id={"#{@id || @field.id}-description"} class="text-gray-500">
          <span class="sr-only">{@label}</span>{@description}
        </span>
      </label>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:input_class, :string, default: nil)
  attr(:value, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:rest, :global)

  def search_input(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "flex items-center rounded-md bg-white pl-3 outline outline-1 -outline-offset-1 outline-gray-300 has-[input:focus-within]:outline has-[input:focus-within]:outline-2 has-[input:focus-within]:-outline-offset-2 has-[input:focus-within]:outline-gray-600",
        @class
      ]}
    >
      <Lucideicons.search class="size-4 text-gray-400" />
      <input
        type="search"
        name={@name}
        value={@value}
        autocomplete="off"
        class={[
          "block min-w-0 grow py-1.5 pl-1 pr-3 text-base text-gray-900 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6",
          @input_class
        ]}
        placeholder={@placeholder || "Search"}
        {@rest}
      />
    </div>
    """
  end

  @doc """
  Tabs with underline and badges.
  """
  attr(:id, :string, required: true)
  attr(:tabs, :list, required: true)
  attr(:current_tab, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:inner_class, :string, default: nil)

  def tabs_with_badges(assigns) do
    ~H"""
    <div class={@class}>
      <div class="grid grid-cols-1 sm:hidden">
        <!-- Use an "onChange" listener to redirect the user to the selected tab URL. -->
        <select
          aria-label="Select a tab"
          class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-1.5 pl-3 pr-8 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600"
        >
          <option
            :for={tab <- @tabs}
            value={tab.value}
            selected={tab.value == @current_tab}
            phx-click={JS.patch(tab.href)}
            disabled={tab[:disabled]}
          >
            {tab.label}
          </option>
        </select>
        <svg
          class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end fill-gray-500"
          viewBox="0 0 16 16"
          fill="currentColor"
          aria-hidden="true"
          data-slot="icon"
        >
          <path
            fill-rule="evenodd"
            d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z"
            clip-rule="evenodd"
          />
        </svg>
      </div>
      <div class="hidden sm:block">
        <div class={["border-b border-gray-200", @inner_class]}>
          <nav class="-mb-px flex space-x-8" aria-label="Tabs">
            <.link
              :for={tab <- @tabs}
              patch={!tab[:disabled] && tab.href}
              class={[
                "flex whitespace-nowrap px-1 py-4 text-sm font-medium border-b-2 ",
                tab.value == @current_tab && "border-gray-500 text-gray-600",
                tab.value != @current_tab &&
                  "border-b-transparent text-gray-500 hover:border-b-gray-200 hover:text-gray-700",
                tab[:disabled] && "pointer-events-none opacity-50"
              ]}
            >
              {tab.label}
              <.badge_span class="ml-3" badge={tab.badge} />
            </.link>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  attr(:tabs, :list, required: true)
  attr(:class, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:selected, :string, required: true)

  def tabs(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <div class="grid grid-cols-1 sm:hidden">
        <select
          aria-label="Select a tab"
          class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-2 pl-3 pr-8 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600"
        >
          <%= for tab <- @tabs do %>
            <option selected={tab.value == @selected} value={tab.value}>{tab.label}</option>
          <% end %>
        </select>
        <svg
          class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end fill-gray-500"
          viewBox="0 0 16 16"
          fill="currentColor"
          aria-hidden="true"
          data-slot="icon"
        >
          <path
            fill-rule="evenodd"
            d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z"
            clip-rule="evenodd"
          />
        </svg>
      </div>
      <div class="hidden sm:block">
        <nav class="flex space-x-4" aria-label="Tabs">
          <%= for tab <- @tabs do %>
            <.link
              patch={tab.href}
              class={[
                "rounded-md px-3 py-2 text-sm font-medium",
                tab.value == @selected && "bg-gray-100 text-gray-700",
                tab.value != @selected && "text-gray-500 hover:text-gray-700"
              ]}
              aria-current={tab.value == @selected && "page"}
            >
              {tab.label}
            </.link>
          <% end %>
        </nav>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.
  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
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
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <MolyWeb.CoreComponents.icon
          :if={@kind == :info}
          name="hero-information-circle-mini"
          class="h-4 w-4"
        />
        <MolyWeb.CoreComponents.icon
          :if={@kind == :error}
          name="hero-exclamation-circle-mini"
          class="h-4 w-4"
        />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <MolyWeb.CoreComponents.icon
          name="hero-x-mark-solid"
          class="h-5 w-5 opacity-40 group-hover:opacity-70"
        />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <MolyWeb.CoreComponents.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <MolyWeb.CoreComponents.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:on_change, JS, default: %JS{})
  attr(:class, :string, default: nil)
  attr(:enabled, :boolean, default: false)
  attr(:rest, :global)

  def toggle_switch(assigns) do
    ~H"""
    <div id={@id} class="flex items-center">
      <button
        type="button"
        class={[
          "relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent bg-gray-200 transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-gray-600 focus:ring-offset-2",
          (@enabled && "bg-gray-600") || "bg-gray-300",
          @class
        ]}
        role="switch"
        aria-checked="false"
        aria-labelledby="toggle-label"
        phx-click={
          @on_change
          |> JS.exec("data-toggle", to: "##{@id}-toggle")
          |> JS.toggle_class("bg-gray-600 bg-gray-300")
        }
      >
        <!-- Enabled: "translate-x-5", Not Enabled: "translate-x-0" -->
        <span
          id={"#{@id}-toggle"}
          aria-hidden="true"
          class={[
            "pointer-events-none inline-block size-5  rounded-full bg-white shadow ring-0 transform transition duration-200 ease-in-out",
            (@enabled && "translate-x-5") || "translate-x-0"
          ]}
          data-toggle={JS.toggle_class("translate-x-5 translate-x-0")}
        >
        </span>
      </button>
      <span :if={@label} class="ml-3 text-sm">
        <span class="font-medium text-gray-900">{@label}</span>
      </span>
    </div>
    """
  end

  defp generate_page_url(url, new_page) do
    uri = URI.parse(url)
    query_params = URI.decode_query(uri.query) || %{}

    updated_query_params =
      case Map.has_key?(query_params, "page") do
        true -> Map.put(query_params, "page", Integer.to_string(new_page))
        # If "page" doesn't exist, add it
        false -> Map.put(query_params, "page", Integer.to_string(new_page))
      end

    updated_query = URI.encode_query(updated_query_params)

    updated_uri = %{uri | query: updated_query}
    URI.to_string(updated_uri)
  end

  defp error_messages(errors) do
    Enum.map(errors, &translate_error(&1))
  end

  attr(:class, :string, default: nil)
  attr(:page_meta, :map, required: true)
  attr(:current_url, :string, required: true)
  attr(:rest, :global)

  def pagination(assigns) do
    ~H"""
    <div
      class={["flex items-center justify-between border-t border-gray-200 bg-white  py-3", @class]}
      {@rest}
    >
      <div class="flex flex-1 justify-between sm:hidden">
        <.link
          :if={@page_meta.prev}
          patch={generate_page_url(@current_url, @page_meta.prev)}
          class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Previous
        </.link>
        <.link
          :if={@page_meta.next}
          patch={generate_page_url(@current_url, @page_meta.next)}
          class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Next
        </.link>
      </div>
      <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
        <div>
          <p class="text-sm text-gray-700">
            Showing <span class="font-medium">{@page_meta.start_row}</span>
            to <span class="font-medium">{@page_meta.end_row}</span>
            of <span class="font-medium">{@page_meta.total}</span>
            results
          </p>
        </div>
        <div>
          <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
            <.link
              patch={@page_meta.prev && generate_page_url(@current_url, @page_meta.prev)}
              class={[
                "relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0",
                !@page_meta.prev && "pointer-events-none opacity-50"
              ]}
            >
              <span class="sr-only">Previous</span>
              <svg
                class="size-5"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
                data-slot="icon"
              >
                <path
                  fill-rule="evenodd"
                  d="M11.78 5.22a.75.75 0 0 1 0 1.06L8.06 10l3.72 3.72a.75.75 0 1 1-1.06 1.06l-4.25-4.25a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </.link>

            <.link
              :for={page <- @page_meta.page_range}
              patch={generate_page_url(@current_url, page)}
              aria-current={page == @page_meta.current_page && "page"}
              class={[
                "relative inline-flex items-center px-4 py-2 text-sm font-semibold",
                page == @page_meta.current_page &&
                  "z-10 bg-gray-800 text-white focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-600",
                page != @page_meta.current_page &&
                  "text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
              ]}
            >
              {page}
            </.link>

            <span
              :if={@page_meta.ellipsis}
              class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0"
            >
              ...
            </span>

            <.link
              patch={@page_meta.next && generate_page_url(@current_url, @page_meta.next)}
              class={[
                "relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0",
                !@page_meta.next && "pointer-events-none opacity-50"
              ]}
            >
              <span class="sr-only">Next</span>
              <svg
                class="size-5"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
                data-slot="icon"
              >
                <path
                  fill-rule="evenodd"
                  d="M8.22 5.22a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.75.75 0 0 1-1.06-1.06L11.94 10 8.22 6.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </.link>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  def no_results(assigns) do
    ~H"""
    <div class="text-center py-12">
      <svg
        class="mx-auto h-12 w-12 text-gray-400"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        aria-hidden="true"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
        />
      </svg>
      <h3 class="mt-2 text-sm font-semibold text-gray-900">No results found</h3>
      <p class="mt-1 text-sm text-gray-500">
        We couldn't find anything matching your search.
        <br />Try adjusting your filters or search terms.
      </p>
    </div>
    """
  end
end
