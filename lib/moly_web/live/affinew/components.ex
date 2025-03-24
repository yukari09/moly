defmodule MolyWeb.Affinew.Components do
  use MolyWeb, :html

  def page_link(:programs), do: ~p"/programs"
  def page_link(:news), do: ~p"/news"
  def page_link(:resource), do: ~p"/resource"
  def page_link(:categries), do: ~p"/program/categories"
  def page_link(:submit), do: ~p"/program/submit"
  def page_link(:term, slug), do: ~p"/programs/#{slug}"
  def page_link(:term, slug, post_name), do: ~p"/programs/#{slug}/#{post_name}"
  def page_link(:user, %Moly.Accounts.User{} = user) do
    username = Moly.Utilities.Account.user_username(user)
    ~p"/user/@#{username}"
  end

  def card(assigns) do
    ~H"""
    <div class="card w-full shadow-sm bg-white">
        <figure class="aspect-[3/2] overflow-hidden !block relative">
        <img
          src={~p"/images/brevo-affiliates.png"}
         />
         <span class="badge badge-xs xs:badge-sm sm:badge-md  badge-primary rounded-br-lg absolute top-0 left-0">Financial & Insurance</span>
      </figure>
      <div class="card-body py-3">
        <h2 class="text-lg md:text-xl font-bold text-green-brilliant flex items-center gap-2" >
          <img src="https://cdn.shopify.com/shopifycloud/web/assets/v1/favicon-default-6cbad9de243dbae3.ico" class="size-6"/>
          Brevo Affiliate Program
        </h2>
        <ol class="mt-2 list-decimal list-inside flex flex-col gap-2 text-xs sm:text-sm ml-4">
          <li class="marker:italic">
            <%!-- <Lucideicons.dot class="size-6 me-2 inline-block text-green-light" /> --%>
            <span><span class="font-bold">$5.00</span> <span class="text-base-content/60">免費註冊</span></span>
          </li>
          <li class="marker:italic">
          <%!-- <Lucideicons.dot class="size-6 me-2 inline-block text-green-light" /> --%>
            <span><span class="font-bold">$100.00</span> <span class="text-base-content/60">付費訂閱</span></span>
          </li>
          <li class="marker:italic">
            <%!-- <Lucideicons.dot class="size-6 me-2 inline-block text-green-light" /> --%>
            <span><span class="font-bold">20%</span> <span class="text-base-content/60">持續收入分成</span></span>
          </li>
        </ol>
        <div class="mt-4">
          <button class="btn rounded-md btn-sm md:btn-md btn-block">Detail -></button>
        </div>
      </div>
    </div>
    """
  end

  def card2(assigns) do
    ~H"""
    <div class="card w-full shadow-sm">
        <figure class="aspect-[3/2] overflow-hidden !block">
        <img
          src={~p"/images/brevo-affiliates.png"}
         />
      </figure>
      <div class="card-body p-2">
        <h2 class="font-bold text-green-brilliant flex items-center gap-2" >
            <img src="https://cdn.shopify.com/shopifycloud/web/assets/v1/favicon-default-6cbad9de243dbae3.ico" class="size-6"/>
            Brevo Affiliate Program
          </h2>
      </div>
    </div>
    """
  end

  def user_dropdown(assigns) do
    ~H"""
    <div class="dropdown dropdown-bottom dropdown-end p-0">
      <div tabindex="0" class="size-8">
        <MolyWeb.DaisyUi.avatar user={@current_user} />
      </div>
      <div
        tabindex="0"
        class="dropdown-content border border-base-300 bg-white rounded-box z-1 w-56 shadow-lg  mt-2"
      >
        <div
          class="px-2 py-4 flex items-center gap-2 border-b border-gray-900/10"
          role="none"
        >
          <.link
            patch={page_link(:user, @current_user)}
            class="block size-10"
            role="none"
          >
            <MolyWeb.DaisyUi.avatar user={@current_user} size={64} />
          </.link>
          <.link
            patch={page_link(:user, @current_user)}
            class="block"
            role="none"
          >
            <p class="text-sm font-semibold">
              {Moly.Utilities.Account.user_name(@current_user)}
            </p>
            <p class="text-sm text-base-content/60">{@current_user.email}</p>
          </.link>
        </div>
        <div class="py-1" role="none">
          <.link
            :if={:admin in @current_user.roles}
            patch={~p"/admin/dashboard"}
            class="group flex items-center px-4 py-2 text-sm font-medium hover:bg-base-content/10"
            role="menuitem"
            tabindex="-1"
          >
            <Lucideicons.sticker class="mr-3 size-4" /> Admin
          </.link>
          <.link
            patch={page_link(:user, @current_user)}
            class="group flex items-center px-4 py-2 text-sm font-medium hover:bg-base-content/10"
            role="menuitem"
            tabindex="-1"
          >
            <Lucideicons.user class="mr-3 size-4" /> Profile
          </.link>
          <.link
            patch="/sign-out"
            class="group flex items-center px-4 py-2 text-sm font-medium hover:bg-base-content/10"
            role="menuitem"
            tabindex="-1"
          >
            <Lucideicons.log_out name="hero-arrow-up-tray" class="mr-3 size-4" />
            Sign out
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def header(assigns) do
    ~H"""
    <div id={@id} class={[(@class && @class) || "mb-8"]}>
      <h1 class="text-2xl sm:text-4xl font-semibold text-green-brilliant">{@headline}</h1>
      <p class="mt-2 font-light text-sm sm:text-base line-clamp-1">{@subtitle}</p>
    </div>
    """
  end

  def footer(assigns) do
    ~H"""
    <footer class="bg-gray-900">
      <div class="mx-auto max-w-7xl overflow-hidden px-6 py-20 sm:py-24 lg:px-8">
        <nav
          :if={Moly.Utilities.Page.website_links() != []}
          class="-mb-6 flex flex-wrap justify-center gap-x-12 gap-y-3 text-sm/6"
          aria-label="Footer"
        >
          <a
            :for={termmeta <- Moly.Utilities.Page.website_links()}
            href={termmeta.meta_value}
            class="text-gray-400 hover:text-white"
          >
            {termmeta.meta_key}
          </a>
        </nav>
        <div
          :if={Moly.Utilities.Page.social_links() != []}
          class="mt-16 flex justify-center gap-x-10"
        >
          <a
            :for={termmeta <- Moly.Utilities.Page.social_links()}
            :if={is_map(termmeta.term_value)}
            href={termmeta.term_value["url"]}
            class="text-gray-400 hover:text-gray-300"
          >
            {raw(termmeta.term_value["icon"])}
          </a>
          <a
            :for={termmeta <- Moly.Utilities.Page.social_links()}
            :if={!is_map(termmeta.term_value)}
            href={termmeta.term_value}
            class="text-gray-400 hover:text-gray-300"
          >
            {termmeta.term_key}
          </a>
        </div>
        <p class="mt-10 text-center text-sm/6 text-gray-400">
          © {Timex.now() |> Timex.format!("{YYYY}")} {Moly.Utilities.Page.website_name()}, Inc. All rights reserved.
        </p>
      </div>
    </footer>
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: nil
  def filter_dropdown(assigns) do
    ~H"""
    <button class={["btn btn-xs sm:btn-sm md:btn-md bg-white text-black border-[#e5e5e5] flex items-center rounded-md", @class]} popovertarget="popover-1" style="anchor-name:--anchor-1">
      {@name}<Lucideicons.chevron_down class="size-4"/>
    </button>
    <ul class="dropdown menu w-52 rounded-box bg-base-100 shadow-sm"
      popover id="popover-1" style="position-anchor:--anchor-1">
      <li><a>Item 1</a></li>
      <li><a>Item 2</a></li>
    </ul>
    """
  end

  def breadcrumb(assigns) do
    ~H"""
    <div class="breadcrumbs text-sm mt-4">
      <ul class="text-xs sm:text-sm">
          <li><a>Home</a></li>
          <li><a>Documents</a></li>
          <li>Add Document</li>
      </ul>
    </div>
    """
  end

  def search_form(assigns) do
    ~H"""
    <.form action="/search" method="get" id="search-form" class="mx-auto w-full">
    <div
        id="index-header-search-bar"
        class="relative bg-gray-900/5 py-0.5 sm:py-1 md:py-2 pl-2.5 pr-8 rounded-full border border-gray-900/0"
    >
        <input
        id="index-search-input"
        type="text"
        placeholder="Search..."
        aria-label="Search"
        autocomplete="off"
        name="q"
        class="w-full px-2  !border-none focus:shadow-none focus-visible:ring-0 focus:outline-none focus:ring-0 focus:ring-transparent"
        phx-focus={
            JS.toggle_class(
            "bg-gray-900/5 bg-gray-900/0 border-gray-900/10 border-gray-900/0 transition-colors duration-50",
            to: "#index-header-search-bar"
            )
            |> JS.toggle_class("text-gray-400 text-gray-500", to: "#index-search-icon")
        }
        phx-blur={
            JS.toggle_class(
            "bg-gray-900/5 bg-gray-900/0  border-gray-900/10 border-gray-900/0 transition-colors duration-50",
            to: "#index-header-search-bar"
            )
            |> JS.toggle_class("text-gray-400 text-gray-500", to: "#index-search-icon")
        }
        />
        <Lucideicons.search
        id="index-search-icon"
        class="w-5 h-5 absolute top-1/2 right-3.5 transform -translate-y-1/2 text-gray-500"
        />
    </div>
    </.form>
    """
  end

  def sort_by(assigns) do
    ~H"""
    <button class="btn btn-ghost flex items-center" popovertarget="popover-1" style="anchor-name:--anchor-1">
      Last <Lucideicons.chevron_down class="size-4"/>
    </button>
    <ul class="dropdown menu w-52 rounded-box bg-base-100 shadow-sm"
      popover id="popover-1" style="position-anchor:--anchor-1">
      <li><a>Item 1</a></li>
      <li><a>Item 2</a></li>
    </ul>
    """
  end
end
