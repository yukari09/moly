defmodule MolyWeb.Affinew.Components do
  use MolyWeb, :html

  alias MolyWeb.Affinew.Links

  def commission_unit_option, do: [{"USD", "$"}, {"EUR", "€"}, {"%", "%"}]
  def payment_cycle_options, do: [
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

  def commission_options, do: [
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

  def cookie_duration_options, do: [
    {"1-5", "1 - 15 Days"},
    {"15-30", "15 - 30 Days"},
    {"15-60", "30 - 60 Days"},
    {"60-90", "60 - 90 Days"},
    {"90-120", "90 - 120 Days"},
    {"120-", "120+ Days"}
  ]

  def commission_unit_option(label), do: commission_unit_option() |> Map.new(&{elem(&1, 0), elem(&1, 1)}) |> Map.get(label)
  def payment_cycle_option(label), do: payment_cycle_options() |> Map.new(&{elem(&1, 0), elem(&1, 1)}) |> Map.get(label)

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

  attr :post, Moly.Contents.Post
  def card(assigns) do
    ~H"""
    <div class="card w-full bg-white border border-base-content/10">
    <figure :if={featrue_image_src(@post)} class="aspect-video overflow-hidden !block relative text-base-content rounded-t-lg">
        <img
          class="object-center"
          src={featrue_image_src(@post)}
         />
         <.link patch={Links.term(category_slug(@post))} class="badge badge-xs xs:badge-sm sm:badge-md  bg-primary border-none text-white rounded-br-lg rounded-tl-lg absolute top-0 left-0">
           {category_name(@post)}
         </.link>
         <.link patch={Links.view(@post.post_name)} class="btn btn-neutral btn-sm absolute right-0 bottom-0 mr-1 mb-1">
           Detail
         </.link>
      </figure>
      <div class="card-body">
        <h2 class="lg:text-lg font-bold flex items-top gap-2 mb-1" >
          <%!-- <img src="https://cdn.shopify.com/shopifycloud/web/assets/v1/favicon-default-6cbad9de243dbae3.ico" class="size-5 rounded-lg"/> --%>
          {@post.post_title}
        </h2>
        <ol class="list-decimal list-inside flex flex-col gap-2">
            <li :for={{i, c} <- commissions(@post)} class="marker:italic">
              <.commission_text data={c} />
            </li>
            <%!-- <li class="marker:italic">
              <span><span class="font-semibold text-[#ff5000]">$5.00</span> free registration</span>
            </li>
            <li class="marker:italic">
              <span><span class="font-semibold text-[#ff5000]">$100.00</span> pay subscribe</span>
            </li>
            <li class="marker:italic">
              <span><span class="font-semibold text-[#ff5000]">20%</span> consistently</span>
            </li> --%>
          </ol>
        <%!-- <div class="flex items-end justify-between">
          <ol class="list-decimal list-inside flex flex-col gap-2 text-base">
            <li :for={{i, c} <- commissions(@post)} class="marker:italic">
              <.commission_text data={c} />
            </li>
            <li class="marker:italic">
              <span><span class="font-semibold text-[#ff5000]">$5.00</span> free registration</span>
            </li>
            <li class="marker:italic">
              <span><span class="font-semibold text-[#ff5000]">$100.00</span> pay subscribe</span>
            </li>
            <li class="marker:italic">
              <span><span class="font-semibold text-[#ff5000]">20%</span> consistently</span>
            </li>
          </ol>
          <div class="mt-4">
            <button class="btn btn-outline btn-sm">Detail<Lucideicons.arrow_right class="size-4" /></button>
          </div>
        </div> --%>
      </div>
    </div>
    """
  end

  def user_dropdown(assigns) do
    assigns = assign(assigns, :id, Moly.Helper.generate_random_id())
    ~H"""
    <.link :if={!@current_user} class="btn" patch={~p"/sign-in"}>Log in</.link>
    <div id={"dropdown-#{@id}"} :if={@current_user} class="dropdown dropdown-bottom dropdown-end p-0">
      <div tabindex="0" class="size-8" id={"dropdown-btn-#{@id}"}>
        <MolyWeb.DaisyUi.avatar user={@current_user} />
      </div>
      <div
        id={"dropdown-menu-#{@id}"}
        tabindex="0"
        class="dropdown-content border border-base-300 bg-white rounded-box z-1 w-56 shadow-lg  mt-2"
      >
        <div
          class="px-2 py-4 flex items-center gap-2 border-b border-gray-900/10"
          role="none"
        >
          <.link
            patch={Links.user(@current_user)}
            class="block size-10"
            role="none"
          >
            <MolyWeb.DaisyUi.avatar user={@current_user} size={64} />
          </.link>
          <.link
            patch={Links.user(@current_user)}
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
            phx-click={close_dropdown("#dropdown-btn-#{@id}")}
          >
            <Lucideicons.sticker class="mr-3 size-4" /> Admin
          </.link>
          <.link
            patch={Links.user(@current_user)}
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

  attr :label, :string, required: true
  attr :class, :string, default: nil
  attr :name, :string, required: true
  attr :params, :map, default: %{}
  attr :options, :list, default: []
  def filter_dropdown(%{name: name, params: params, options: options, label: label} = assigns) do
    id = Moly.Helper.generate_random_id()
    show_label =
      Enum.find(options, fn {v, _} -> v == params[name]  end)
      |> case do
        nil -> label
        found_el -> elem(found_el, 1)
      end
    assigns = assign(assigns, id: id, label: show_label)
    ~H"""
    <div class="dropdown" id={@id} class={@class}>
      <div id={"dropdown-btn-#{@id}"} tabindex="0" id={"dropdown-button-#{id}"} class={["btn btn-xs sm:btn-sm md:btn-md bg-white text-black border-[#e5e5e5] flex items-center rounded-md"]} role="button">
        {@label}<Lucideicons.chevron_down class="size-4"/>
      </div>
      <ul
        id={"dropdown-menu-#{@id}"}
        tabindex="0"
        class="dropdown-content menu menu-sm md:menu-md mt-1 w-60 rounded-box bg-white border border-base-300 shadow-lg max-h-[240px] overflow-y-scroll overflow-x-hidden block"
      >
        <li :for={{value, label} <- @options} class={[!value && "menu-title"]}>
          <.link :if={value} phx-click={close_dropdown("#dropdown-btn-#{@id}")} patch={Links.programs(Map.put(@params, @name, value))}>{label}</.link>
          <span :if={!value}>{label}</span>
        </li>
      </ul>
    </div>
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

  defp commission_text(%{data: c} = assigns) do
    assigns = assign(assigns, c)
    ~H"""
    <span class="text-sm md:text-base" :if={@commission_type == "bounty"}>&nbsp;<span class="font-semibold text-[#ff5000]">{commission_unit_option(@commission_unit) || @commission_unit}{Moly.Helper.format_to_int(@commission_amount,1)}</span> {Map.get(@data, :commission_notes) || "Fixed Bounty"}</span>
    <span class="text-sm md:text-base" :if={@commission_type == "revenue_share"}>&nbsp;<span class="font-semibold text-[#ff5000]">{Moly.Helper.format_to_int(@commission_amount,0)}%</span>  {Map.get(@data, :commission_notes) || "Revenue Share"}</span>
    <span class="text-sm md:text-base" :if={@commission_type == "hybrid"}>&nbsp;<span class="font-semibold text-[#ff5000]">{Moly.Helper.format_to_int(@commission_amount,1)}{Moly.Helper.format_to_int(@commission_amount,1)}</span>  {Map.get(@data, :commission_notes)}</span>
    """
  end

  defp featrue_image_src(post) do
    Moly.Utilities.Post.post_attachment_metadata_images(post, "attachment_affiliate_media_feature", ["large", "medium"])
    |>  Moly.Helper.get_in_from_keys([0, 0, 1, "file"])
  end

  defp commissions(post) do
    Moly.Utilities.Post.post_meta_by_filter(post, "commission")
    |> Enum.group_by(fn %{meta_key: meta_key} ->
      meta_key |> String.split("_") |> Enum.at(-1)
    end, fn %{meta_key: meta_key, meta_value: meta_value} ->
      k = meta_key |> String.split("_") |> Enum.slice(0..-2//1) |> Enum.join("_")
      {k, meta_value}
    end)
    |> Enum.map(fn {i, t} ->
      {i, Map.new(t, fn {k, v} -> {String.to_atom(k), v} end)}
    end)
  end

  defp category_name(post), do:
    Moly.Helper.get_in_from_keys(post, [:affiliate_categories, 0, :name])

  defp category_slug(post), do:
    Moly.Helper.get_in_from_keys(post, [:affiliate_categories, 0, :slug])
end
