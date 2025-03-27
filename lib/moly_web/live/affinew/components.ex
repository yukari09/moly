defmodule MolyWeb.Affinew.Components do
  use MolyWeb, :html

  def page_link(:programs), do: ~p"/programs"
  def page_link(:under_construction), do: ~p"/under-construction"
  def page_link(:submit), do: ~p"/program/submit"
  def page_link(:term, slug), do: ~p"/programs/#{slug}"
  def page_link(:post_view, post_name), do: ~p"/program/#{post_name}"
  def page_link(:user, %Moly.Accounts.User{} = user) do
    username = Moly.Utilities.Account.user_username(user)
    ~p"/user/@#{username}"
  end


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


  def card(assigns) do
    ~H"""
    <div class="card w-full bg-white border border-base-content/10">
    <figure class="aspect-[3/2] overflow-hidden !block relative text-base-content rounded-lg">
        <img
          src={~p"/images/brevo-affiliates.png"}
         />
         <span class="badge badge-xs xs:badge-sm sm:badge-md  bg-primary border-none text-white rounded-br-lg rounded-tl-lg absolute top-0 left-0">Financial & Insurance</span>
      </figure>
      <div class="card-body">

        <h2 class="text-xl font-bold flex items-center my-2 gap-2" >
          <img src="https://cdn.shopify.com/shopifycloud/web/assets/v1/favicon-default-6cbad9de243dbae3.ico" class="size-5 rounded-lg"/>
          Brevo Affiliate Program
        </h2>
        <div class="flex items-end justify-between">
          <ol class="list-decimal list-inside flex flex-col gap-2 text-base ml-2">
            <li class="marker:italic">
              <%!-- <Lucideicons.dot class="size-6 me-2 inline-block text-green-light" /> --%>
              <span><span class="font-semibold text-[#ff5000]">$5.00</span> free registration</span>
            </li>
            <li class="marker:italic">
            <%!-- <Lucideicons.dot class="size-6 me-2 inline-block text-green-light" /> --%>
              <span><span class="font-semibold text-[#ff5000]">$100.00</span> pay subscribe</span>
            </li>
            <li class="marker:italic">
              <%!-- <Lucideicons.dot class="size-6 me-2 inline-block text-green-light" /> --%>
              <span><span class="font-semibold text-[#ff5000]">20%</span> consistently</span>
            </li>
          </ol>
          <div class="mt-4">
            <button class="btn btn-outline btn-sm">Detail<Lucideicons.arrow_right class="size-4" /></button>
          </div>
        </div>
      </div>
    </div>
    """
  end


  def user_dropdown(assigns) do
    ~H"""
    <.link :if={!@current_user} class="btn" patch={~p"/sign-in"}>Log in</.link>
    <div :if={@current_user} class="dropdown dropdown-bottom dropdown-end p-0">
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
      <h1 class="text-2xl sm:text-4xl font-semibold text-primary">{@headline}</h1>
      <p class="mt-3 line-clamp-1">{@subtitle}</p>
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

  attr :class, :string, default: nil
  def breadcrumb(assigns) do
    ~H"""
    <div class={["breadcrumbs text-sm mt-4", @class]}>
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
        class="relative bg-gray-900/5 py-0.5 sm:py-1 md:py-2 pl-2.5 pr-8 rounded-sm border border-gray-900/0"
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

  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")
  attr(:class, :string, default: nil)
  def flash_group(assigns) do
    ~H"""
    <div id={@id} class={["toast toast-top toast-right z-1", @class]}>
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash kind={:info} title={gettext("Error!")} flash={@flash} />
    </div>
    """
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
      role="alert"
      class={["alert", @kind == :info && "alert-success" || "alert-error"]}
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
    >
      <.icon name="hero-x-circle" class="size-5"/>
      <span>{msg}</span>
    </div>
    """
  end
end
