defmodule MolyWeb.Affiliate.Components do
  use MolyWeb, :html

  attr(:id, :string, required: true)
  attr(:items, :list, required: true)
  attr(:class, :string, default: nil)

  def breadcrumb(assigns) do
    ~H"""
    <nav id={@id} class={[(@class && @class) || "flex py-4 lg:py-8"]} aria-label="Breadcrumb">
      <ol role="list" class="flex items-center">
        <li>
          <div>
            <.link href="/" class="text-gray-400 hover:text-gray-500">
              <.icon name="hero-home" class="size-5" />
            </.link>
          </div>
        </li>
        <li :for={{label, link} <- @items}>
          <div class="flex items-center">
            <.icon name="hero-slash text-gray-300" class="size-5" />
            <.link navigate={link} class="text-sm font-medium text-gray-500 hover:text-gray-700">
              {label}
            </.link>
          </div>
        </li>
      </ol>
    </nav>
    """
  end

  attr(:id, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:headline, :string, required: true)
  attr(:subtitle, :string, required: true)

  def header(assigns) do
    ~H"""
    <div id={@id} class={[(@class && @class) || "mb-8"]}>
      <h1 class="text-4xl text-gray-900 font-medium">{@headline}</h1>
      <p class="text-gray-500 mt-3 font-light ">{@subtitle}</p>
    </div>
    """
  end
end
