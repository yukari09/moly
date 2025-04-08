defmodule MolyWeb.Affinew.Components do
  use MolyWeb, :html

  alias MolyWeb.Affinew.Links
  import MolyWeb.Affinew.Helper

  def commission_unit_option, do: [{"USD", "$"}, {"EUR", "€"}, {"%", "%"}, {"$", "$"}]

  def payment_cycle_options,
    do: [
      {"monthly", "Monthly"},
      {"semi-monthly", "Semi-Monthly"},
      {"weekly", "Weekly"},
      {"quarterly", "Quarterly"},
      {"bi-annually", "Bi-Annually"},
      {"annually", "Annually"},
      {"on-demand", "On-Demand"},
      {"net-30", "Net 30"},
      {"net-60", "Net 60"}
    ]

  def commission_options,
    do: [
      {nil, "Fixed Bounty"},
      {"bounty-1-5", "1 - 5"},
      {"bounty-5-10", "5 - 10"},
      {"bounty-10-20", "10 - 20"},
      {"bounty-20-50", "20 - 50"},
      {"bounty-50-100", "50 - 100"},
      {"bounty-100-", "100+"},
      {nil, "Revenue Share"},
      {"revenue_share-1-5", "1% - 5%"},
      {"revenue_share-5-12", "5% - 12%"},
      {"revenue_share-12-20", "12% - 20%"},
      {"revenue_share-20-30", "20% - 30%"},
      {"revenue_share-30-50", "30% - 50%"},
      {"revenue_share-50-", "50%+"}
    ]

  def cookie_duration_options,
    do: [
      {"1-5", "1 - 15 Days"},
      {"15-30", "15 - 30 Days"},
      {"15-60", "30 - 60 Days"},
      {"60-90", "60 - 90 Days"},
      {"90-120", "90 - 120 Days"},
      {"120-", "120+ Days"}
    ]

  def sort_options,
    do: [
      {"created_at_desc", "Newest"},
      {"created_at_asc", "Oldest"}
    ]

  def commission_type_option,
    do: [
      {"bounty", "Fixed Bounty"},
      {"revenue_share", "Revenue Share"},
      {"hybrid", "Hybrid"}
    ]

  def commission_unit_option(label),
    do: commission_unit_option() |> Map.new(&{elem(&1, 0), elem(&1, 1)}) |> Map.get(label)

  def payment_cycle_option(label),
    do: payment_cycle_options() |> Map.new(&{elem(&1, 0), elem(&1, 1)}) |> Map.get(label)

  def commission_type_option_label(value),
    do: commission_type_option() |> Map.new(&{elem(&1, 0), elem(&1, 1)}) |> Map.get(value)

  def show_option_label(options, current_value, default_label \\ nil) do
    Enum.find(options, fn {v, _} -> v == current_value end)
    |> case do
      nil -> default_label
      found_el -> elem(found_el, 1)
    end
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

  def close_dropdown(js \\ %JS{}, selector) do
    JS.dispatch(js, "app:focus-el", to: selector)
    |> JS.dispatch("app:blur-el", to: selector)
  end

  def open_dropdown(js \\ %JS{}, selector) do
    JS.dispatch(js, "app:blur-el", to: selector)
    |> JS.dispatch("app:focus-el", to: selector)
  end

  attr(:post, :map, required: true)

  def card(assigns) do
    ~H"""
    <div class="card w-full bg-white border border-base-content/10">
      <figure
        :if={featrue_image_src(@post)}
        class="aspect-video overflow-hidden !block relative text-base-content rounded-t-lg"
      >
        <.link
          navigate={
            Moly.Helper.get_in_from_keys(@post, [:source, "post_name"])
            |> MolyWeb.Affinew.Links.view()
          }
        ><img class="object-center" src={featrue_image_src(@post)} /></.link>
        <.link
          :if={
            affiliate_category = Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_category"])
          }
          navigate={Moly.Helper.get_in_from_keys(affiliate_category, [0, "slug"]) |> Links.term()}
          class="badge badge-xs xs:badge-sm sm:badge-md  bg-primary border-none text-white rounded-br-lg rounded-tl-lg absolute top-0 left-0"
        >
          {Moly.Helper.get_in_from_keys(affiliate_category, [0, "name"])}
        </.link>
        <.link
          navigate={
            Moly.Helper.get_in_from_keys(@post, [:source, "post_name"])
            |> MolyWeb.Affinew.Links.view()
          }
          class="btn btn-neutral btn-sm absolute right-0 bottom-0 mr-1 mb-1"
        >
          Detail
        </.link>
      </figure>
      <div class="card-body">
        <.link navigate={
          Moly.Helper.get_in_from_keys(@post, [:source, "post_name"]) |> MolyWeb.Affinew.Links.view()
        }>
          <h2 class="lg:text-lg font-bold flex items-top gap-2 mb-1">
            {Moly.Helper.get_in_from_keys(@post, [:source, "post_title"])}
          </h2>
        </.link>
        <ol>{Moly.Helper.get_in_from_keys(@post, [:source, "commission"])}</ol>
        <ol class="list-decimal list-inside flex flex-col gap-2">
          <li
            :if={is_list(Moly.Helper.get_in_from_keys(@post, [:source, "commission"]))}
            :for={
              %{
                "commission_amount" => commission_amount,
                "commission_type" => commission_type,
                "commission_unit" => commission_unit
              } = c <- Moly.Helper.get_in_from_keys(@post, [:source, "commission"])
            }
            class="marker:italic"
          >
            <.commission_text
              commission_amount={commission_amount}
              commission_unit={commission_unit}
              commission_type={commission_type}
              commission_notes={Map.get(c, "commission_notes")}
            />
          </li>
        </ol>
      </div>
    </div>
    """
  end

  def user_dropdown(assigns) do
    assigns = assign(assigns, :id, Moly.Helper.generate_random_id())

    ~H"""
    <.link :if={!@current_user} class="btn btn-sm md:btn-md" navigate={~p"/sign-in"}>Log in</.link>
    <div :if={@current_user} id={"dropdown-#{@id}"} class="dropdown dropdown-bottom dropdown-end p-0">
      <div tabindex="0" class="size-8" id={"dropdown-btn-#{@id}"}>
        <MolyWeb.DaisyUi.avatar user={@current_user} />
      </div>
      <div
        id={"dropdown-menu-#{@id}"}
        tabindex="0"
        class="dropdown-content border border-base-300 bg-white rounded-box z-1 w-56 shadow-lg  mt-2"
      >
        <div class="px-2 py-4 flex items-center gap-2 border-b border-gray-900/10" role="none">
          <.link navigate={Links.user(@current_user)} class="block size-10" role="none">
            <MolyWeb.DaisyUi.avatar user={@current_user} size={64} />
          </.link>
          <.link navigate={Links.user(@current_user)} class="block" role="none">
            <p class="text-sm font-semibold">
              {Moly.Utilities.Account.user_name(@current_user)}
            </p>
            <p class="text-sm text-base-content/60">{@current_user.email}</p>
          </.link>
        </div>
        <div class="py-1" role="none">
          <.link
            :if={:admin in @current_user.roles}
            navigate={~p"/admin/dashboard"}
            class="group flex items-center px-4 py-2 text-sm font-medium hover:bg-base-content/10"
            role="menuitem"
            tabindex="-1"
            phx-click={close_dropdown("#dropdown-btn-#{@id}")}
          >
            <Lucideicons.sticker class="mr-3 size-4" /> Admin
          </.link>
          <.link
            navigate={Links.user(@current_user)}
            class="group flex items-center px-4 py-2 text-sm font-medium hover:bg-base-content/10"
            role="menuitem"
            tabindex="-1"
            phx-click={close_dropdown("#dropdown-btn-#{@id}")}
          >
            <Lucideicons.user class="mr-3 size-4" /> Profile
          </.link>
          <.link
            patch="/sign-out"
            class="group flex items-center px-4 py-2 text-sm font-medium hover:bg-base-content/10"
            role="menuitem"
            tabindex="-1"
            phx-click={close_dropdown("#dropdown-btn-#{@id}")}
          >
            <Lucideicons.log_out name="hero-arrow-up-tray" class="mr-3 size-4" /> Sign out
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
        <div :if={Moly.Utilities.Page.social_links() != []} class="mt-16 flex justify-center gap-x-10">
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

  attr(:label, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:class_btn, :string, default: nil)
  attr(:name, :string, required: true)
  attr(:params, :map, default: %{})
  attr(:options, :list, default: [])
  attr(:term_slug, :string, default: nil)
  attr(:q, :string, default: nil)

  def filter_dropdown(%{name: name, params: params, options: options, label: label} = assigns) do
    id = Moly.Helper.generate_random_id()

    show_label = show_option_label(options, params[name], label)

    assigns = assign(assigns, id: id, show_label: show_label)

    ~H"""
    <div id={@id} class={["dropdown", @class]}>
      <div
        id={"dropdown-btn-#{@id}"}
        tabindex="0"
        id={"dropdown-button-#{id}"}
        class={[
          "btn btn-xs sm:btn-sm md:btn-md bg-white text-black border-[#e5e5e5] flex items-center rounded-md",
          @class_btn
        ]}
        role="button"
      >
        {@show_label}<Lucideicons.chevron_down class="size-4" />
      </div>
      <ul
        id={"dropdown-menu-#{@id}"}
        tabindex="0"
        class="dropdown-content menu menu-sm md:menu-md mt-1 w-60 rounded-box bg-white border border-base-300 shadow-lg max-h-[240px] overflow-y-scroll overflow-x-hidden block"
      >
        <li :for={{value, label} <- @options} class={[!value && "menu-title"]}>
          <.link
            :if={value}
            phx-click={close_dropdown("#dropdown-btn-#{@id}")}
            navigate={
              @q && Links.results(Map.put(@params, @name, value))
              || @term_slug && Links.term(@term_slug, Map.put(@params, @name, value))
              || Links.programs(Map.put(@params, @name, value))
            }
          >
            {label}
          </.link>
          <span :if={!value}>{label}</span>
        </li>
      </ul>
    </div>
    """
  end

  attr(:class, :string, default: nil)
  attr(:links, :list, required: true)
  def breadcrumb(assigns) do
    ~H"""
    <div class={["breadcrumbs text-sm mt-4 overflow-hidden max-w-full", @class]}>
      <ul class="text-xs sm:text-sm">
        <li :for={{link, label} <- @links}>
          <.link :if={link} navigate={link} >{label}</.link>
          <span :if={!link}>{label}</span>
        </li>
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
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      role="alert"
      class={["alert gap-1", (@kind == :info && "alert-success") || "alert-error"]}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
    >
      <%!-- <.icon name="hero-x-circle" class="size-4" /> --%>
      <span>{msg}</span>
      <Lucideicons.x class="size-4" />
    </div>
    """
  end

  def view_title(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl md:text-3xl lg:text-4xl font-semibold text-primary">{Moly.Helper.get_in_from_keys(@post, [:source, "post_title"])}</h1>
      <div class="flex flex-col md:flex-row md:items-center gap-2 mt-6 text-base-content/60">
        <.link
          :if={
            affiliate_category = Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_category"])
          }
          navigate={Moly.Helper.get_in_from_keys(affiliate_category, [0, "slug"]) |> Links.term()}
          class="badge badge-sm badge-outline text-white bg-primary  badge-primary rounded-lg"
        >
          {Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_category", 0, "name"])}
        </.link>
        <div class="flex items-center gap-2 mt-2 md:mt-0">
          <time class="text-sm ">{Moly.Helper.get_in_from_keys(@post, [:source, "updated_at"]) |> format_es_data()}</time>
          <.link onclick="share_modal.showModal()" class="text-sm flex items-center gap-1 link link-hover">
            <Lucideicons.share_2 class="size-4 inline"/> Share
          </.link>
          <.link class="text-sm flex items-center gap-1 link link-hover" phx-click={@bookmark_event}>
            <span :if={@bookmark_event in ["require_login", "bookmark_post"]}><Lucideicons.book_marked class="size-4 inline"/> Save</span>
            <span :if={@bookmark_event in ["unbookmark_post"]}><Lucideicons.bookmark_check class="size-4 inline"/> Saved</span>
          </.link>
          <.link href={Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_program_link"])} rel="nofollow" class="text-sm flex items-center gap-1 link link-hover">
            <Lucideicons.external_link class="size-4 inline"/>Website
          </.link>
        </div>
      </div>
    </div>
    <.figure_image post={@post} class="block md:hidden mt-4 md:mt-8" />
    <!--intro-->
    <p class="mt-4 md:mt-8 line-clamp-3">{Moly.Helper.get_in_from_keys(@post, [:source, "post_excerpt"])}</p>
    <ul class="list bg-[rgb(255,253,246)] rounded-box mt-4 md:mt-12">
      <%!-- <li class="p-4 pb-2 text-xs opacity-60 tracking-wide">Commissions of this affiliate program</li> --%>
      <li class="list-row" :for={{commission, i} <- Moly.Helper.get_in_from_keys(@post, [:source, "commission"]) |> Enum.with_index()}>
        <div class="text-2xl md:text-4xl font-thin opacity-30 tabular-nums flex flex-col justify-center">0{i + 1}</div>
        <div class="flex flex-col justify-center w-16 uppercase font-semibold opacity-60 text-xs">{  Map.get(commission, "commission_type") |> commission_type_option_label()}</div>
        <div class="flex flex-col justify-center w-20">
          <div :if={Map.get(commission, "commission_unit") != "%"} class="text-xl/6 md:text-2xl/6 text-[#ff5000]">
            {Map.get(commission, "commission_unit") |> commission_unit_option()}{Map.get(commission, "commission_amount")}
          </div>
          <div :if={Map.get(commission, "commission_unit") == "%"} class="text-xl/6 md:text-2xl/6 text-[#ff5000] mt-1">
            {Map.get(commission, "commission_amount")}%
          </div>
        </div>
        <p class="list-col-grow flex flex-col justify-center">
          <span >{Map.get(commission, "commission_notes")}</span>
        </p>
      </li>
    </ul>
    <dialog id="share_modal" class="modal">
      <div class="modal-box w-auto relative">
        <h3 class="text-lg font-bold">Share</h3>
        <div class="grid grid-cols-4 gap-4 py-4 mt-4 rounded-box">
          <div id="share-twitter" class="text-center space-y-1 cursor-pointer" data-share="twitter" phx-hook="ShareHook">
            <svg class="size-11 mx-auto" xmlns="http://www.w3.org/2000/svg" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" image-rendering="optimizeQuality" fill-rule="evenodd" clip-rule="evenodd" viewBox="0 0 512 509.64"><rect width="512" height="509.64" rx="115.61" ry="115.61"/><path fill="#fff" fill-rule="nonzero" d="M323.74 148.35h36.12l-78.91 90.2 92.83 122.73h-72.69l-56.93-74.43-65.15 74.43h-36.14l84.4-96.47-89.05-116.46h74.53l51.46 68.04 59.53-68.04zm-12.68 191.31h20.02l-129.2-170.82H180.4l130.66 170.82z"/></svg>
            <span class="text-sm">X(twitter)</span>
          </div>
          <div id="share-facebook" class="text-center space-y-1 cursor-pointer" data-share="facebook" phx-hook="ShareHook">
            <svg class="size-11 mx-auto" xmlns="http://www.w3.org/2000/svg" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" image-rendering="optimizeQuality" fill-rule="evenodd" clip-rule="evenodd" viewBox="0 0 512 509.64"><rect fill="#0866FF" width="512" height="509.64" rx="115.612" ry="115.612"/><path fill="#fff" d="M287.015 509.64h-92.858V332.805h-52.79v-78.229h52.79v-33.709c0-87.134 39.432-127.522 124.977-127.522 16.217 0 44.203 3.181 55.651 6.361v70.915c-6.043-.636-16.536-.953-29.576-.953-41.976 0-58.194 15.9-58.194 57.241v27.667h83.618l-14.365 78.229h-69.253V509.64z"/></svg>
            <span class="text-sm">Facebook</span>
          </div>
          <div id="share-threads" class="text-center space-y-1 cursor-pointer" data-share="threads" phx-hook="ShareHook">
            <svg class="size-11 mx-auto" xmlns="http://www.w3.org/2000/svg" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" image-rendering="optimizeQuality" fill-rule="evenodd" clip-rule="evenodd" viewBox="0 0 512 512"><path d="M105 0h302c57.75 0 105 47.25 105 105v302c0 57.75-47.25 105-105 105H105C47.25 512 0 464.75 0 407V105C0 47.25 47.25 0 105 0z"/><path fill="#fff" fill-rule="nonzero" d="M337.36 243.58c-1.46-.7-2.95-1.38-4.46-2.02-2.62-48.36-29.04-76.05-73.41-76.33-25.6-.17-48.52 10.27-62.8 31.94l24.4 16.74c10.15-15.4 26.08-18.68 37.81-18.68h.4c14.61.09 25.64 4.34 32.77 12.62 5.19 6.04 8.67 14.37 10.39 24.89-12.96-2.2-26.96-2.88-41.94-2.02-42.18 2.43-69.3 27.03-67.48 61.21.92 17.35 9.56 32.26 24.32 42.01 12.48 8.24 28.56 12.27 45.26 11.35 22.07-1.2 39.37-9.62 51.45-25.01 9.17-11.69 14.97-26.84 17.53-45.92 10.51 6.34 18.3 14.69 22.61 24.73 7.31 17.06 7.74 45.1-15.14 67.96-20.04 20.03-44.14 28.69-80.55 28.96-40.4-.3-70.95-13.26-90.81-38.51-18.6-23.64-28.21-57.79-28.57-101.5.36-43.71 9.97-77.86 28.57-101.5 19.86-25.25 50.41-38.21 90.81-38.51 40.68.3 71.76 13.32 92.39 38.69 10.11 12.44 17.73 28.09 22.76 46.33l28.59-7.63c-6.09-22.45-15.67-41.8-28.72-57.85-26.44-32.53-65.1-49.19-114.92-49.54h-.2c-49.72.35-87.96 17.08-113.64 49.73-22.86 29.05-34.65 69.48-35.04 120.16v.24c.39 50.68 12.18 91.11 35.04 120.16 25.68 32.65 63.92 49.39 113.64 49.73h.2c44.2-.31 75.36-11.88 101.03-37.53 33.58-33.55 32.57-75.6 21.5-101.42-7.94-18.51-23.08-33.55-43.79-43.48zm-76.32 71.76c-18.48 1.04-37.69-7.26-38.64-25.03-.7-13.18 9.38-27.89 39.78-29.64 3.48-.2 6.9-.3 10.25-.3 11.04 0 21.37 1.07 30.76 3.13-3.5 43.74-24.04 50.84-42.15 51.84z"/></svg>
            <span class="text-sm">Threads</span>
          </div>
          <div id="share-reddit" class="text-center space-y-1 cursor-pointer" data-share="reddit" phx-hook="ShareHook">
            <svg class="size-11 mx-auto" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg" fill-rule="evenodd" clip-rule="evenodd" stroke-linejoin="round" stroke-miterlimit="2"><path d="M512 128v256c0 70.646-57.355 128-128 128H128C57.354 512 0 454.646 0 384V128C0 57.354 57.354 0 128 0h256c70.645 0 128 57.354 128 128z" fill="#ff4500"/><g transform="translate(1.249 1.608) scale(1.99024)"><circle cx="200.6" cy="123.7" r="29.9" fill="url(#prefix___Radial1)"/><circle cx="55.4" cy="123.7" r="29.9" fill="url(#prefix___Radial2)"/><ellipse cx="128.1" cy="149.3" rx="85.3" ry="64" fill="url(#prefix___Radial3)"/><path d="M102.8 143.1c-.5 10.8-7.7 14.8-16.1 14.8-8.4 0-14.8-5.6-14.3-16.4.5-10.8 7.7-18 16.1-18 8.4 0 14.8 8.8 14.3 19.6zM183.6 141.5c.5 10.8-5.9 16.4-14.3 16.4s-15.6-3.9-16.1-14.8c-.5-10.8 5.9-19.6 14.3-19.6s15.6 7.1 16.1 18z" fill="#842123" fill-rule="nonzero"/><path d="M153.3 144.1c.5 10.1 7.2 13.8 15 13.8s13.8-5.5 13.4-15.7c-.5-10.1-7.2-16.8-15-16.8s-13.9 8.5-13.4 18.7z" fill="url(#prefix___Radial4)" fill-rule="nonzero"/><path d="M102.8 144.1c-.5 10.1-7.2 13.8-15 13.8s-13.8-5.5-13.3-15.7c.5-10.1 7.2-16.8 15-16.8s13.8 8.5 13.3 18.7z" fill="url(#prefix___Radial5)" fill-rule="nonzero"/><path d="M128.1 165.1c-10.6 0-20.7.5-30.1 1.4-1.6.2-2.6 1.8-2 3.2 5.2 12.3 17.6 21 32.1 21s26.8-8.6 32.1-21c.6-1.5-.4-3.1-2-3.2-9.4-.9-19.5-1.4-30.1-1.4z" fill="#bbcfda" fill-rule="nonzero"/><path d="M128.1 167.5c-10.6 0-20.7.5-30 1.5-1.6.2-2.6 1.8-2 3.3 5.2 12.5 17.6 21.3 32 21.3 14.4 0 26.8-8.8 32-21.3.6-1.5-.4-3.1-2-3.3-9.4-1-19.5-1.5-30-1.5z" fill="#fff" fill-rule="nonzero"/><path d="M128.1 166.2c-10.4 0-20.3.5-29.5 1.4-1.6.2-2.6 1.8-2 3.2 5.2 12.3 17.3 21 31.5 21s26.3-8.6 31.5-21c.6-1.5-.4-3.1-2-3.2-9.2-.8-19.1-1.4-29.5-1.4z" fill="url(#prefix___Radial6)" fill-rule="nonzero"/><circle cx="174.8" cy="55.5" r="21.2" fill="url(#prefix___Radial7)"/><path d="M127.8 88c-2.5 0-4.6-1.1-4.6-2.7 0-19 15.4-34.4 34.4-34.4 2.5 0 4.6 2.1 4.6 4.6 0 2.5-2.1 4.6-4.6 4.6-13.9 0-25.2 11.3-25.2 25.2 0 1.7-2.1 2.7-4.6 2.7z" fill="url(#prefix___Radial8)" fill-rule="nonzero"/><path d="M97.3 149.1c0 3.9-4.2 5.7-9.3 5.7-5.1 0-9.3-1.8-9.3-5.7 0-3.9 4.2-7.1 9.3-7.1 5.1 0 9.3 3.1 9.3 7.1zM177.5 149.1c0 3.9-4.2 5.7-9.3 5.7-5.1 0-9.3-1.8-9.3-5.7 0-3.9 4.2-7.1 9.3-7.1 5.1 0 9.3 3.1 9.3 7.1z" fill="#ff6101" fill-rule="nonzero"/><ellipse cx="94.4" cy="134.8" rx="3.3" ry="3.6" fill="#ffc49c"/><ellipse cx="173.3" cy="134.8" rx="3.3" ry="3.6" fill="#ffc49c"/></g><defs><radialGradient id="prefix___Radial1" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(59.9015 0 0 -52.2545 201.012 107.557)"><stop offset="0" stop-color="#feffff"/><stop offset=".4" stop-color="#feffff"/><stop offset=".51" stop-color="#f9fcfc"/><stop offset=".62" stop-color="#edf3f5"/><stop offset=".7" stop-color="#dee9ec"/><stop offset=".72" stop-color="#d8e4e8"/><stop offset=".76" stop-color="#ccd8df"/><stop offset=".8" stop-color="#c8d5dd"/><stop offset=".83" stop-color="#ccd6de"/><stop offset=".85" stop-color="#d8dbe2"/><stop offset=".88" stop-color="#ede3e9"/><stop offset=".9" stop-color="#ffebef"/><stop offset="1" stop-color="#ffebef"/></radialGradient><radialGradient id="prefix___Radial2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(59.9015 0 0 -52.2545 55.892 107.557)"><stop offset="0" stop-color="#feffff"/><stop offset=".4" stop-color="#feffff"/><stop offset=".51" stop-color="#f9fcfc"/><stop offset=".62" stop-color="#edf3f5"/><stop offset=".7" stop-color="#dee9ec"/><stop offset=".72" stop-color="#d8e4e8"/><stop offset=".76" stop-color="#ccd8df"/><stop offset=".8" stop-color="#c8d5dd"/><stop offset=".83" stop-color="#ccd6de"/><stop offset=".85" stop-color="#d8dbe2"/><stop offset=".88" stop-color="#ede3e9"/><stop offset=".9" stop-color="#ffebef"/><stop offset="1" stop-color="#ffebef"/></radialGradient><radialGradient id="prefix___Radial3" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(180.687 0 0 -126.865 130.347 99.176)"><stop offset="0" stop-color="#feffff"/><stop offset=".4" stop-color="#feffff"/><stop offset=".51" stop-color="#f9fcfc"/><stop offset=".62" stop-color="#edf3f5"/><stop offset=".7" stop-color="#dee9ec"/><stop offset=".72" stop-color="#d8e4e8"/><stop offset=".76" stop-color="#ccd8df"/><stop offset=".8" stop-color="#c8d5dd"/><stop offset=".83" stop-color="#ccd6de"/><stop offset=".85" stop-color="#d8dbe2"/><stop offset=".88" stop-color="#ede3e9"/><stop offset=".9" stop-color="#ffebef"/><stop offset="1" stop-color="#ffebef"/></radialGradient><radialGradient id="prefix___Radial4" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(-15.0964 0 0 22.1628 165.28 150.971)"><stop offset="0" stop-color="#f60"/><stop offset=".5" stop-color="#ff4500"/><stop offset=".7" stop-color="#fc4301"/><stop offset=".82" stop-color="#f43f07"/><stop offset=".92" stop-color="#e53812"/><stop offset="1" stop-color="#d4301f"/></radialGradient><radialGradient id="prefix___Radial5" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(15.0964 0 0 22.1628 90.19 150.971)"><stop offset="0" stop-color="#f60"/><stop offset=".5" stop-color="#ff4500"/><stop offset=".7" stop-color="#fc4301"/><stop offset=".82" stop-color="#f43f07"/><stop offset=".92" stop-color="#e53812"/><stop offset="1" stop-color="#d4301f"/></radialGradient><radialGradient id="prefix___Radial6" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(53.2322 0 0 -35.1106 128.369 194.908)"><stop offset="0" stop-color="#172e35"/><stop offset=".29" stop-color="#0e1c21"/><stop offset=".73" stop-color="#030708"/><stop offset="1"/></radialGradient><radialGradient id="prefix___Radial7" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(46.7274 0 0 -46.7274 175.312 34.106)"><stop offset="0" stop-color="#feffff"/><stop offset=".4" stop-color="#feffff"/><stop offset=".51" stop-color="#f9fcfc"/><stop offset=".62" stop-color="#edf3f5"/><stop offset=".7" stop-color="#dee9ec"/><stop offset=".72" stop-color="#d8e4e8"/><stop offset=".76" stop-color="#ccd8df"/><stop offset=".8" stop-color="#c8d5dd"/><stop offset=".83" stop-color="#ccd6de"/><stop offset=".85" stop-color="#d8dbe2"/><stop offset=".88" stop-color="#ede3e9"/><stop offset=".9" stop-color="#ffebef"/><stop offset="1" stop-color="#ffebef"/></radialGradient><radialGradient id="prefix___Radial8" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(38.3003 0 0 -38.3003 155.84 85.046)"><stop offset="0" stop-color="#7a9299"/><stop offset=".48" stop-color="#7a9299"/><stop offset=".67" stop-color="#172e35"/><stop offset=".75"/><stop offset=".82" stop-color="#172e35"/><stop offset="1" stop-color="#172e35"/></radialGradient></defs></svg>
            <span class="text-sm">Reddit</span>
          </div>
        </div>
        <button onclick="share_modal.close()" class="btn btn-sm btn-circle mt-2 mr-2 absolute right-0 top-0"><Lucideicons.x class="size-4" /></button>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  def view_base_info(assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-4 px-4 py-6 bg-green-light/10">
      <div class="text-sm font-medium">Min Payout Threshold</div>
      <div><span class="text-lg text-primary font-medium">{Moly.Helper.get_in_from_keys(@post, [:source, "min_payout_threshold"])}</span> <span class="text-xs text-base-content/60">{Moly.Helper.get_in_from_keys(@post, [:source, "currency"])}</span></div>
      <div class="text-sm font-medium">Payment Method</div>
      <div class="text-sm font-medium">{Moly.Helper.get_in_from_keys(@post, [:source, "payment_method"]) |> Enum.join(",")}</div>
      <div class="text-sm font-medium">Duration Months</div>
      <div :if={Moly.Helper.get_in_from_keys(@post, [:source, "duration_months"]) != 0}><span class="text-lg text-primary font-medium">{Moly.Helper.get_in_from_keys(@post, [:source, "duration_months"])}</span> <span class="text-xs text-base-content/60">Months</span></div>
      <div :if={Moly.Helper.get_in_from_keys(@post, [:source, "duration_months"]) == 0}>Not specified</div>
      <div class="text-sm font-medium">Cookie Duration</div>
      <div><span class="text-lg text-primary font-medium">{Moly.Helper.get_in_from_keys(@post, [:source, "cookie_duration"])}</span> <span class="text-xs text-base-content/60">Days</span></div>
      <div class="text-sm font-medium">Payment Cycle</div>
      <div class="text-sm font-medium uppercase">{Moly.Helper.get_in_from_keys(@post, [:source, "payment_cycle"])}</div>
      <div class="text-sm font-medium">Applicable Region</div>
      <div class="text-sm font-medium">{Moly.Helper.get_in_from_keys(@post, [:source, "region"])}</div>
    </div>
    """
  end

  def view_description(assigns) do
    ~H"""
    <h2 class="text-xl mb-4 font-medium">Description</h2>
    <div class="prose text-base-content/70">{Moly.Helper.get_in_from_keys(@post, [:source, "post_content"]) |> to_safe_html}</div>
    """
  end

  def view_signup_requirements(assigns) do
    ~H"""
    <h2 class="text-xl mb-4 font-medium">Signup Requirements</h2>
    <div class="prose  text-base-content/70">{Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_signup_requirements"])  |> to_safe_html}</div>
    """
  end

  def view_category(assigns) do
    ~H"""
    <div class="px-2 lg:px-8 py-4 rounded-box bg-base-100/50">
      <h2 class="text-xl">Categoriy</h2>
      <p class="mt-4 text-sm text-base-content/80">
      <.link navigate={Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_category", 0, "slug"]) |> Links.term()}>
        {Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_category", 0, "name"])}
      </.link>
      </p>
    </div>
    """
  end

  def view_tags(assigns) do
    ~H"""
    <div class="px-2 lg:px-8 py-4 rounded-box bg-base-100/50">
      <h2 class="text-xl">Tags</h2>
      <p class="mt-4 text-sm text-base-content/80 flex items-center gap-4 flex-wrap">
        <.link
          :for={%{"name" => name, "slug" => slug} <- Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_tag"])} class="link link-hover"
          navigate={Links.term(slug)}
        >#{name}</.link>
      </p>
    </div>
    """
  end

  def figure_image(assigns) do
    ~H"""
    <figure :if={featrue_image_src(@post)} class={["aspect-[3/2] overflow-hidden rounded-lg", @class]}>
      <img
        src={featrue_image_src(@post)}
      />
    </figure>
    """
  end

  defp commission_text(assigns) do
    ~H"""
    <span class="text-sm md:text-base">
      <span class="font-semibold text-orange">
        <span :if={@commission_unit != "%"}>{commission_unit_option(@commission_unit)}</span>{@commission_amount}<span :if={
          @commission_unit == "%"
        }>%</span>
      </span>
      {@commission_notes || (@commission_type == "bounty" && "Fixed Bounty") ||
        (@commission_type == "revenue_share" && "Revenue Share")}
    </span>
    """
  end

  def to_safe_html(raw_string) do
    String.replace(raw_string, ~r/<script[^>]*>/, "&lt;script&gt;")
    |> String.replace(~r/<\/script>/, "&lt;/script&gt;")
    |> String.replace(~r/<a[^>]*>.*?<\/a>/, "")
    |> String.replace(~r/<img[^>]*>/, "")
    |> raw
  end


  def featrue_image_src(post) do
    Moly.Helper.get_in_from_keys(post, [
      :source,
      "attachment_affiliate_media_feature",
      "attachment_metadata",
      "sizes"
    ])
    |> case do
      nil ->
        nil

      sizes ->
        Enum.reduce_while(["large", "medium"], nil, fn size, _ ->
          image_src = Moly.Helper.get_in_from_keys(sizes, [size, "file"])
          if image_src, do: {:halt, image_src}, else: {:cont, nil}
        end)
    end
  end
end
