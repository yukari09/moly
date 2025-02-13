defmodule MonorepoWeb.Affiliate.UserPageLive do
  use MonorepoWeb, :live_view

  require Ash.Query

  @per_page 20

  def mount(_params, _session, socket) do
    country_category = Monorepo.Terms.read_by_term_slug!("countries", actor: %{roles: [:user]}) |> List.first()
    industry_category = Monorepo.Terms.read_by_term_slug!("industries", actor: %{roles: [:user]}) |> List.first()
    socket =
      socket
      |> assign(country_category: country_category, industry_category: industry_category)
    {:ok, socket}
  end

  def handle_params(%{"username" => "@" <> username} = params, _uri, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    post_type = Map.get(params, "type", "published")
    posts = get_user_posts(username, page, post_type)
    socket =
      assign(socket, page: page, post_type: post_type, end_of_timeline?: false)
      |> stream(:posts, posts)
    {:noreply, socket}
  end


  defp get_user_posts(username, page, "published") do
    offset = (page - 1) * @per_page

    opts = [
      action: :read,
      actor: %{roles: [:user]},
      page: [limit: @per_page, offset: offset, count: true]
    ]

    Ash.Query.filter(Monorepo.Contents.Post, post_type == :affiliate and post_status in [:pending, :publish])
    |> Ash.Query.filter(author.user_meta.meta_key == :username and author.user_meta.meta_value == ^username)
    |> Ash.Query.load([:author, :post_tags, :post_categories, post_meta: :children])
    |> Ash.read!(opts)
    |> Map.get(:results)
  end

  # defp get_user_posts(username, page, "saved") do
  #   []
  # end


  def render(assigns) do
    ~H"""
    <div>
      <div class="relative lg:h-[250px] bg-primary">
        <div class="w-full h-full overflow-hidden">
          <img class="w-full h-full object-cover overflow-hidden" src={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :banner)["xxl"]} />
        </div>
        <div class="-bottom-10 mx-4 absolute size-24 cursor-pointer">
          <img :if={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :avatar)} class="inline-block size-24 rounded-full" src={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :avatar)["128"]} alt="">
          <span :if={!Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :avatar)} class="inline-flex size-24 items-center justify-center rounded-full bg-primary border-2 border-white">
            <span class="font-medium text-white uppercase text-4xl">{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :name) |> String.slice(0, 1)}</span>
          </span>
        </div>
      </div>

      <div class="flex items-start gap-8">
        <div class="w-80 py-4 px-2 mt-12">
          <div class="text-2xl px-4 text-gray-900">
            <p><%= Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :name) %></p>
            <p class="text-xs/6">@{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :username)}</p>
          </div>
          <div class="mb-12 mt-4">
            <div>
              <div class="px-4 w-full text-sm  !text-gray-500 !outline-none break-words resize-none overflow-hidden">{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :description)}</div>
            </div>

            <div class="grid grid-cols-1">
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :location)}
              </div>
              <.icon name="hero-map-pin" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
            </div>

            <div class="grid grid-cols-1">
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :website)}
              </div>
              <.icon name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
            </div>

            <div class="grid grid-cols-1">
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :twitter)}
              </div>
              <Lucideicons.twitter name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
            </div>

            <div class="grid grid-cols-1">
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :facebook)}
              </div>
              <Lucideicons.facebook name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
            </div>

            <div class="grid grid-cols-1">
              <div class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6">
                {Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :instagram)}
              </div>
              <Lucideicons.instagram name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
            </div>
          </div>
        </div>
        <!--start tab-->
        <div class="grow container mx-auto sm:px-6 lg:px-8">
          <div class="relative border-b border-gray-200 pb-5 sm:pb-0">
            <%!-- <div class="md:flex md:items-center md:justify-between">
              <div class="mt-3 flex md:absolute md:top-3 md:right-0 md:mt-0">
                <button type="button" class="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 ring-1 shadow-xs ring-gray-300 ring-inset hover:bg-gray-50">Share</button>
                <button type="button" class="ml-3 inline-flex items-center rounded-md bg-gray-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-gray-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-600">Create</button>
              </div>
            </div> --%>
            <div class="mt-4">
              <div class="grid grid-cols-1 sm:hidden">
                <!-- Use an "onChange" listener to redirect the user to the selected tab URL. -->
                <select aria-label="Select a tab" class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-2 pr-8 pl-3 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600">
                  <option>Applied</option>
                  <option>Phone Screening</option>
                  <option selected>Interview</option>
                  <option>Offer</option>
                  <option>Hired</option>
                </select>
                <svg class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end fill-gray-500" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true" data-slot="icon">
                  <path fill-rule="evenodd" d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd" />
                </svg>
              </div>
              <!-- Tabs at small breakpoint and up -->
              <div class="hidden sm:block">
                <nav class="-mb-px flex space-x-8">
                  <!-- Current: "border-gray-500 text-gray-600", Default: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700" -->
                  <a href="#" class="border-b-2 border-green-500 px-1 pb-4 text-sm font-medium whitespace-nowrap text-green-600" aria-current="page">Published</a>
                  <a href="#" class="border-b-2 border-transparent px-1 pb-4 text-sm font-medium whitespace-nowrap text-gray-500 hover:border-gray-300 hover:text-gray-700">Saved</a>
                </nav>
              </div>
            </div>
          </div>
          <div
            id={"#{@post_type}-list"}
            phx-update="stream"

            class="mx-auto pt-6 pb-10 grid max-w-2xl grid-cols-1 gap-x-8 gap-y-20 lg:mx-0 lg:max-w-none lg:grid-cols-3"
            phx-page-loading
          >
            <article :for={{id, post} <- @streams.posts} id={id} class="flex flex-col items-start justify-between">
              <div class="relative w-full">
                <img src={Monorepo.Utilities.MetaValue.post_feature_image(post, :attachment_affiliate_media_feature, "medium")} alt="" class="aspect-video w-full rounded-2xl bg-gray-100 object-cover sm:aspect-[2/1] lg:aspect-[3/2]">
                <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-900/10"></div>
              </div>
              <div class="max-w-xl">
                <div class="relative">
                  <h3 class="mt-3 text-lg/6 font-semibold text-gray-900 group-hover:text-gray-600 line-clamp-2">
                    <.link navigate={~p"/product/#{post.post_name}"}>
                      <span class="absolute inset-0"></span>
                      {post.post_title}
                    </.link>
                  </h3>
                </div>
                <div class="mt-2 flex items-center gap-x-4 text-xs">
                  <time datetime="2020-03-16" class="text-gray-500">{post.inserted_at |> Timex.format!("{Mshort} {D}, {YYYY}")}</time>
                  <a href="#" class="relative z-10 rounded-full bg-gray-50 px-3 py-1.5 font-medium text-gray-600 hover:bg-gray-100">{Monorepo.Utilities.Term.get_first_category_and_return_by_keys(post, "category", [:name], @industry_category.id)}</a>
                  <a href="#" class="relative z-10 rounded-full bg-gray-50 px-3 py-1.5 font-medium text-gray-600 hover:bg-gray-100">
                    <span class="font-bold">{Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_min) |> Monorepo.Utilities.MetaValue.format_meta_value}</span>
                    {Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_unit) |> Monorepo.Utilities.MetaValue.format_meta_value}
                    -
                    <span class="font-bold">{Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_max) |> Monorepo.Utilities.MetaValue.format_meta_value}</span>
                    {Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_unit) |> Monorepo.Utilities.MetaValue.format_meta_value}

                    <span class="font-medium">{Monorepo.Utilities.MetaValue.filter_meta_by_key_first(post, :commission_model) |> Monorepo.Utilities.MetaValue.format_meta_value}</span>
                  </a>
                </div>
              </div>
            </article>
          </div>
        </div>
        <!--end-->
      </div>
    </div>
    """
  end
end
