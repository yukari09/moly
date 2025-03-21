defmodule MolyWeb.DaisyUi do
  use Phoenix.Component

  # alias Phoenix.LiveView.JS

  import Moly.Utilities.Account, only: [user_avatar: 2, user_name: 2]

  attr(:user, Moly.Accounts.User, required: true)
  attr(:size, :string, default: "32")
  attr(:class, :string, default: nil)

  def avatar(%{size: size, user: user} = assigns) do
    assigns = assign(assigns, :user_avatar_src, user_avatar(user, "#{size}"))

    ~H"""
    <div class="avatar">
      <div class={["rounded-full size-full", @class]}>
        <img :if={@user_avatar_src} src={@user_avatar_src} />
        <span :if={!@user_avatar_src} class="inline-flex size-full items-center justify-center rounded-full bg-primary border-2 border-white">
          <span class="font-medium text-white uppercase text-sm">{user_name(@user, 1)}</span>
        </span>
      </div>
    </div>
    """
  end
end
