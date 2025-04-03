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
        <ol class="list-decimal list-inside flex flex-col gap-2">
          <li
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
    <.link :if={!@current_user} class="btn" navigate={~p"/sign-in"}>Log in</.link>
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
    <div class={["breadcrumbs text-sm mt-4", @class]}>
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
      class={["alert", (@kind == :info && "alert-success") || "alert-error"]}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
    >
      <.icon name="hero-x-circle" class="size-5" />
      <span>{msg}</span>
    </div>
    """
  end

  def view_title(assigns) do
    ~H"""
    <div>
      <h1 class="text-3xl lg:text-4xl font-semibold text-primary">{Moly.Helper.get_in_from_keys(@post, [:source, "post_title"])}</h1>
      <div class="flex items-center gap-2 mt-6 text-base-content/60">
        <.link
          :if={
            affiliate_category = Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_category"])
          }
          navigate={Moly.Helper.get_in_from_keys(affiliate_category, [0, "slug"]) |> Links.term()}
          class="badge badge-sm badge-outline text-white bg-primary  badge-primary rounded-lg"
        >
          {Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_category", 0, "name"])}
        </.link>
        <time class="text-sm ">{Moly.Helper.get_in_from_keys(@post, [:source, "updated_at"]) |> format_es_data()}</time>
        <.link class="text-sm flex items-center gap-1 link link-hover">
          <Lucideicons.share_2 class="size-4 inline"/> Share
        </.link>
        <.link class="text-sm flex items-center gap-1 link link-hover">
          <Lucideicons.book_marked class="size-4 inline"/> Save
        </.link>
        <.link class="text-sm flex items-center gap-1 link link-hover">
          <Lucideicons.external_link class="size-4 inline"/>Website
        </.link>
      </div>
    </div>
    <!--intro-->
    <p class="mt-8 line-clamp-3">{Moly.Helper.get_in_from_keys(@post, [:source, "post_content"]) |> Floki.parse_document!() |> Floki.text()}</p>
    <ul class="list bg-[rgb(255,253,246)] rounded-box mt-12">
      <li class="p-4 pb-2 text-xs opacity-60 tracking-wide">Commissions of this affiliate program</li>
      <li class="list-row" :for={{commission, i} <- Moly.Helper.get_in_from_keys(@post, [:source, "commission"]) |> Enum.with_index()}>
        <div class="text-4xl font-thin opacity-30 tabular-nums flex flex-col justify-center">0{i + 1}</div>
        <div class="flex flex-col justify-center w-16 uppercase font-semibold opacity-60">{  Map.get(commission, "commission_type") |> commission_type_option_label()}</div>
        <div class="flex flex-col justify-center w-20">
          <div :if={Map.get(commission, "commission_unit") != "%"} class="text-lg/6 md:text-2xl/6 text-[#ff5000]">
            {Map.get(commission, "commission_unit")}{Map.get(commission, "commission_amount")}
          </div>
          <div :if={Map.get(commission, "commission_unit") == "%"} class="text-lg/6 md:text-2xl/6 text-[#ff5000] mt-1">
            {Map.get(commission, "commission_amount")}%
          </div>
        </div>
        <p class="list-col-grow flex flex-col justify-center">
          <span >{Map.get(commission, "commission_notes")}</span>
        </p>
      </li>
    </ul>
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
      <div><span class="text-lg text-primary font-medium">{Moly.Helper.get_in_from_keys(@post, [:source, "duration_months"])}</span> <span class="text-xs text-base-content/60">Months</span></div>
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
    <h3 class="text-xl mb-4">Description</h3>
    <div class="prose">{raw Moly.Helper.get_in_from_keys(@post, [:source, "post_content"])}</div>
    """
  end

  def view_signup_requirements(assigns) do
    ~H"""
    <h3 class="text-xl mb-4">Signup Requirements</h3>
    <div class="prose">{raw Moly.Helper.get_in_from_keys(@post, [:source, "affiliate_signup_requirements"])}</div>
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
    <figure :if={featrue_image_src(@post)} class="aspect-[3/2] overflow-hidden rounded-lg">
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

  defp featrue_image_src(post) do
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
