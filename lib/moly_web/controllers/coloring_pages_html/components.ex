defmodule MolyWeb.PageHtml.Components do
  use MolyWeb, :html

  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :data, :map, required: true
  attr :srcset, :list, default: [
    {2343, 1562},
    {300, 200},
    {1024, 683},
    {768, 512},
    {1536, 1024},
    {2048, 1365}
  ]
  attr :sizes, :string, default: "
    (max-width: 768px) 100vw,
    (max-width: 1024px) 70vw,
    (max-width: 1536px) 50vw,
    40vw
  "
  attr :lazy, :boolean, default: true
  attr :rest, :global, include: ~w(alt fetchpriority decoding)
  def responsive_image_es(%{data: %{source: %{"thumbnail_id" => %{"attached_file" => attached_file}}}, sizes: sizes, srcset: srcset} = assigns) do
    srcset =
      Enum.map(srcset, fn {w, h} ->
        image_src = Moly.Helper.image_resize(attached_file, w, h)
        "#{image_src} #{w}w"
      end)
      |> Enum.join(",")
    src = Moly.Helper.image_resize(attached_file, 768, 512)
    assigns = assign(assigns, srcset: srcset, src: src, sizes: sizes)
    ~H"""
    <img id={@id || Moly.Helper.generate_random_id()} loading={@lazy && "lazy"} class={[@class]} sizes={@sizes} srcset={@srcset} {@rest}/>
    """
  end


  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :data, :map, required: true
  def datetime_es(assigns) do
    update_at = Moly.Helper.get_in_from_keys(assigns, [:data, :source, "updated_at"]) |> NaiveDateTime.from_iso8601!
    assigns = assign(assigns, :update_at, update_at)
    ~H"""
    <time id={@id || Moly.Helper.generate_random_id()} class={[@class]} datetime={@update_at}>{Timex.format!(@update_at, "{Mfull} {0D}, {YYYY}")}</time>
    """
  end

  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :image_class, :string, default: nil
  attr :image_link_class, :string, default: nil
  attr :fetchpriority, :string, default: nil
  attr :decoding, :string, default: nil
  attr :content_class, :string, default: nil
  attr :data, :map, required: true
  slot :title_slot, required: true
  slot :datetime_slot, required: false
  slot :excerpt_slot, required: true
  slot :read_more_slot, required: false
  def post_card(%{data: data} = assigns) do
    navigate = ~p"/post/#{Moly.Helper.get_in_from_keys(data, [:source, "post_name"])}"
    assigns = assign(assigns, :navigate, navigate)
    ~H"""
    <div id={@id || Moly.Helper.generate_random_id()} class={@class}>
      <.link class={["block", @image_link_class]} navigate={@navigate}>
        <.responsive_image_es class={@image_class} data={@data} fetchpriority={@fetchpriority} decoding={@decoding} alt={Moly.Helper.get_in_from_keys(@data, [:source, "post_title"])}/>
      </.link>
      <div class={[@content_class]}>
        <.link :if={@title_slot != []} class="block" navigate={@navigate}>{render_slot(@title_slot)}</.link>
        {render_slot(@datetime_slot)}
        <.link :if={@excerpt_slot != []} class="block" navigate={@navigate}>{render_slot(@excerpt_slot)}</.link>
        <.link :if={@read_more_slot != []} class="block" navigate={@navigate}>{render_slot(@read_more_slot)}</.link>
      </div>
    </div>
    """
  end

  # attr :class, :string, default: nil
  # attr :post, :map, required: true
  # def article(assigns) do
  #   ~H"""
  #   <article class={[
  #     "prose prose-sm sm:prose lg:prose-lg !max-w-none bricolage-grotesque-4 mx-auto break-words",
  #     @class
  #   ]}>
  #     <h1 class="!text-[#8C4B4C] text-lg sm:text-xl md:text-3xl xl:text-5xl tracking-tight">{Moly.Helper.get_in_from_keys(@post, [:source, "post_title"])}</h1>



  #     <div class="flex items-center divide-x my-4 divide-base-content/50 leading-3 gap-2 text-base-content/50  text-xs md:text-sm">
  #       <.link :if={Moly.Helper.get_in_from_keys(@post, [:source, "category", 0, "slug"])} class="pr-2" navigate={~p"/@#{Moly.Helper.get_in_from_keys(@post, [:source, "category", 0, "slug"])}"}>{Moly.Helper.get_in_from_keys(@post, [:source, "category", 0, "name"])}</.link>
  #       <MolyWeb.PageHtml.Components.datetime_es data={@post} />
  #     </div>


  #     <div class="grid grid-cols-3 gap-4">
  #       <img
  #         class="object-cover w-full max-w-xs"
  #         style={"aspect-ratio: 210/297;"}
  #         src="http://localhost:8000/v4Fcn5jLtfsw2Nkf6GVZsD37cnM=/1024x576/smart/filters:format(webp)/image/webp/c1952c3f-6224-41fe-9d67-b31c4d5fed43.webp"
  #       />
  #       <img
  #         class="object-cover w-full max-w-xs"
  #         style={"aspect-ratio: 210/297;"}
  #         src="http://localhost:8000/v4Fcn5jLtfsw2Nkf6GVZsD37cnM=/1024x576/smart/filters:format(webp)/image/webp/c1952c3f-6224-41fe-9d67-b31c4d5fed43.webp"
  #       />
  #       <img
  #         class="object-cover w-full max-w-xs"
  #         style={"aspect-ratio: 210/297;"}
  #         src="http://localhost:8000/v4Fcn5jLtfsw2Nkf6GVZsD37cnM=/1024x576/smart/filters:format(webp)/image/webp/c1952c3f-6224-41fe-9d67-b31c4d5fed43.webp"
  #       />
  #     </div>

  #     <p>
  #       <ul class="space-y-2 text-[#431e33] !p-0 !list-none">

  #         <li>
  #           <div class="flex items-center  justify-between">
  #             <div class="flex items-center gap-2">
  #               <img src="/images/color_tip.png" class="size-20" />

  #               <ul class="flex items-center gap-2 !list-none !p-0">
  #                 <li>
  #                   <button class="btn btn-xs bg-[#431e33] btn-circle"></button>
  #                   <span class="text-xs font-medium" style="color:#431e33">#431e33</span>
  #                 </li>
  #                 <li>
  #                   <button class="btn btn-xs bg-[#6A5ACD] btn-circle"></button>
  #                   <span class="text-xs font-medium" style="color:#431e33">#6A5ACD</span>
  #                 </li>
  #                 <li>
  #                   <button class="btn btn-xs bg-[#00BCD4] btn-circle"></button>
  #                   <span class="text-xs font-medium" style="color:#00BCD4">#00BCD4</span>
  #                 </li>
  #                 <li>
  #                   <button class="btn btn-xs bg-[#FF8C69] btn-circle"></button>
  #                   <span class="text-xs font-medium" style="color:#FF8C69">#FF8C69</span>
  #                 </li>
  #               </ul>
  #             </div>
  #             <button
  #               class="btn bg-[#0d5b5f] btn-xs md:btn-md outline-none border-none text-[#fff9ef]"
  #             ><Lucideicons.download class= "size-4 md:size-5"/>Download All</button>
  #           </div>
  #         </li>
  #       </ul>
  #     </p>

  #     <%= for %{"data" => data, "id" => id, "type" => type} <- Moly.Helper.get_in_from_keys(@post, [:source, "post_content"]) |> JSON.decode! |> Moly.Helper.get_in_from_keys(["blocks"]) do %>
  #     <h2 id={id} :if={type == "header" && data["level"] == 2} style="color: #0E5B5F;" class="font-medium">
  #       <img phx-track-static :if={data["text"] == "What Kind of Pens are Suitable for This Painting?"} src={~p"/images/color-pen.webp"} class="w-full object-cover" style="aspect-ratio: 8/1" />
  #       <img phx-track-static :if={data["text"] == "Suitable Paper for This Painting"} src={"/images/post-paper.webp"} class="w-full object-cover" style="aspect-ratio: 8/1" />
  #       <img phx-track-static :if={data["text"] == "Expert Opinion/Suggestions for This Image"} src={"/images/cute-girl.webp"} class="w-full object-cover" style="aspect-ratio: 8/1" />
  #       <div>{data["text"]}</div>
  #     </h2>
  #     <h3 id={id} :if={type == "header" && data["level"] == 3} style="color: #FD8075;" class="font-medium">
  #       {data["text"]}
  #     </h3>
  #     <h4 id={id} :if={type == "header" && data["level"] == 4} style="color: #6DB9E8;" class="font-medium">
  #       {data["text"]}
  #     </h4>
  #     <p id={id}  :if={type == "paragraph"} class="!font-thin">{raw data["text"]}</p>
  #     <p id={id} :if={type == "image"}>
  #       <img
  #         class="rounded-box border border-base-content/4 bg-base-100 not-prose w-full"
  #         alt={Moly.Helper.get_in_from_keys(@post, [:source, "post_title"])}
  #         srcset = {
  #           Enum.map(Moly.Helper.get_in_from_keys(data, ["file", "additional", "sizes"]), fn {_, %{"width" => width, "file" => file}} ->
  #             "#{file} #{width}w"
  #           end)
  #           |> Enum.join(",")
  #         }
  #         style={"aspect-ratio: #{data["file"]["additional"]["width"]} / #{data["file"]["additional"]["height"]}"}
  #         sizes="(min-width: 1024px) 800px, 100vw"
  #         fetchpriority="high"
  #         decoding="async"
  #         loading="lazy"
  #       />
  #     </p>
  #     <ol id={id} :if={type == "list" && data["style"] == "ordered"}>
  #       <li :for={item <- data["items"]}>{raw item["content"]}</li>
  #     </ol>
  #     <ul id={id} :if={type == "list" && data["style"] == "unordered"}>
  #       <li :for={item <- data["items"]}>{raw item["content"]}</li>
  #     </ul>
  #     <div id={id} class={["rounded-box border border-base-content/4 bg-base-100 not-prose", data["stretched"] && "overflow-x-auto"]} :if={type == "table"}>
  #       <table class="table">
  #         <thead :if={data["withHeadings"]}>
  #           <tr>
  #             <th :for={cell <- hd(data["content"])}>{raw cell}</th>
  #           </tr>
  #         </thead>
  #         <tbody>
  #           <tr :for={{row, i} <- Enum.with_index(data["content"])}>
  #             <td :if={!data["withHeadings"] || i > 0} :for={cell <- row}>{raw cell}</td>
  #           </tr>
  #         </tbody>
  #       </table>
  #     </div>
  #     <% end %>
  #   </article>
  #   """
  # end

  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :category_slug, :string, required: false
  attr :tag_slug, :string, required: false
  def pagination(assigns) do
    category_slug = Moly.Helper.get_in_from_keys(assigns, [:category_slug])
    tag_slug = Moly.Helper.get_in_from_keys(assigns, [:tag_slug])
    for_url = fn page ->
      if category_slug do
        ~p"/posts/#{category_slug}?page=#{page}"
      else
        ~p"/tags/#{tag_slug}?page=#{page}"
      end
    end
    assigns = assign(assigns, for_url: for_url)
    ~H"""
    <nav id={@id || Moly.Helper.generate_random_id()} class={[@class, "flex gap-4 justify-center"]}>
      <.link class={["font-semibold", !@page_meta.prev && "opacity-50 pointer-events-none"]} navigate={@page_meta.prev && for_url.(@page_meta.prev)}>« Previous</.link>
      <.link class={["font-semibold", page == @page_meta.current_page && "text-primary"]} :for={page <- @page_meta.page_range} href={for_url.(page)}>{page}</.link>
      <.link class={["font-semibold", !@page_meta.next && "opacity-50 pointer-events-none"]} navigate={@page_meta.next && for_url.(@page_meta.next)}>Next »</.link>
    </nav>
    """
  end

end
