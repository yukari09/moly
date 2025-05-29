defmodule MolyWeb.HtmlComponents do
  use Phoenix.Component

  # alias Phoenix.LiveView.JS
  # import MolyWeb.Gettext

  attr :avatar, :string, required: true
  attr :username, :string, required: true
  attr :date, :string, required: true
  attr :rating, :integer, required: true
  attr :description, :string, required: true
  def review(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex items-center space-x-2">
        <img src={@avatar} class="size-10 rounded-full">
        <div>
            <p class="font-semibold  text-sm/6">{@username}</p>
            <p class="text-sm text-[var(--secondary-text-color)]">{@date}</p>
        </div>
      </div>
      <div class="rating rating-xs space-x-1">
        <div :for={i <- 1..5} class="mask mask-star-2 bg-[var(--primary-color)]" aria-label={"#{i} star"} aria-current={i == @rating && "true"}></div>
      </div>
      <p class="text-sm ">
        {@description}
      </p>
    </div>
    """
  end

  attr :header_txt, :string, required: true
  attr :sub_header_txt, :string, required: true
  def header(assigns) do
    ~H"""
    <div class="mb-8 space-y-2">
      <h2 class="text-2xl font-bold ">{@header_txt}</h2>
      <h3 class="/80">{@sub_header_txt}</h3>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :header, :string, required: true
  def card(assigns) do
    ~H"""
    <.card_container>
      {render_slot(@header)}
      <h3 class="font-semibold ">{@title}</h3>
      <p class="text-[var(--secondary-text-color)] text-sm">
        {@description}
      </p>
    </.card_container>
    """
  end

  slot :inner_block
  def card_container(assigns) do
    ~H"""
    <div class="px-4 py-6 border-1 border-base-300 rounded-sm space-y-3">
      {render_slot(@inner_block)}
    </div>
    """
  end

end
