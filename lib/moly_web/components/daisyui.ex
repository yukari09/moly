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
end
