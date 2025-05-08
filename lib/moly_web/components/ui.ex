defmodule MolyWeb.UI do
  use Phoenix.Component

  # alias Phoenix.LiveView.JS
  alias Phoenix.HTML.FormField

  # import MolyWeb.Gettext
  # import Moly.Helper, only: [generate_random_id: 1]
  import MolyWeb.CoreComponents, only: [icon: 1]

  attr(:type, :string, required: false, default: "text")
  attr(:field, FormField, required: true)
  slot(:label, required: false)
  slot(:input_helper, required: false)
  slot(:foot_other, required: false)
  attr(:input_dispatch, :string, required: false, default: nil)
  attr(:options, :list, required: false)
  attr(:option_selectd, :string, required: false)
  attr(:rest, :global)

  def input(%{type: "text"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="block text-sm/6 font-medium text-gray-900">
        {render_slot(@label)}
      </label>
      <div class="mt-2 grid grid-cols-1">
        <input
          type="text"
          id={@field.id}
          name={@field.name}
          value={@field.value}
          autocomplete="off"
          class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 text-base outline outline-1 -outline-offset-1 focus:outline focus:outline-2 focus:-outline-offset-2 sm:text-sm/6 px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
          data-error-class="pl-3 pr-10 text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600 sm:pr-9"
          data-normal-class="px-3 text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-gray-600"
          phx-update="ignore"
          data-input-dispatch={@input_dispatch}
          {@rest}
        />
        <.icon
          name="hero-exclamation-circle-solid"
          class={
            "#{@field.id}-icon" <>
            "pointer-events-none col-start-1 row-start-1 mr-3 size-5 self-center justify-self-end text-red-500 sm:size-4 hidden"
          }
        />
      </div>
      <div class="mt-1 text-sm/6 flex justify-between">
        <p :if={@input_helper} class="text-sm text-gray-500" id={"#{@field.id}-helper"}>
          {render_slot(@input_helper)}
        </p>
        <p class="text-sm text-red-500" id={"#{@field.id}-error"}></p>
        <p :if={@foot_other}>{render_slot(@foot_other)}</p>
      </div>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="block text-sm/6 font-medium text-gray-900">
        {render_slot(@label)}
      </label>
      <div class="mt-2">
        <textarea
          id={@field.id}
          name={@field.name}
          placeholder="Description(text or markdown)"
          rows="5"
          phx-debounce="50"
          phx-update="ignore"
          data-input-dispatch={@input_dispatch}
          class="block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
          {@rest}
        >{@field.value}</textarea>
      </div>
      <div class="mt-1 text-sm/6 flex justify-between">
        <p :if={@input_helper} class="text-sm text-gray-500" id={"#{@field.id}-helper"}>
          {render_slot(@input_helper)}
        </p>
        <p class="text-sm text-red-500" id={"#{@field.id}-error"}></p>
        <p :if={@foot_other}>{render_slot(@foot_other)}</p>
      </div>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="block text-sm/6 font-medium text-gray-900">
        {render_slot(@label)}
      </label>
      <div class="mt-2 grid grid-cols-1">
        <select
          id={@field.id}
          name={@field.name}
          phx-update="ignore"
          class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-1.5 pl-3 pr-8 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:text-sm/6"
          {@rest}
        >
          <option :for={{value, key} <- @options} value={value} selected={value == @option_selectd}>
            {key}
          </option>
        </select>
        <.icon
          name="hero-chevron-down"
          class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end text-gray-500 sm:size-4"
        />
      </div>
      <div class="mt-1 text-sm/6 flex justify-between">
        <p :if={@input_helper} class="text-sm text-gray-500" id={"#{@field.id}-helper"}>
          {render_slot(@input_helper)}
        </p>
        <p class="text-sm text-red-500" id={"#{@field.id}-error"}></p>
        <p :if={@foot_other}>{render_slot(@foot_other)}</p>
      </div>
    </div>
    """
  end
end
