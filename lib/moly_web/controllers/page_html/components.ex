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
        <.responsive_image_es class={@image_class} data={@data} fetchpriority={@fetchpriority} decoding={@decoding}/>
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

  attr :post, :map, required: true
  def article(assigns) do
    ~H"""
    <article class="prose prose-sm sm:prose lg:prose-lg max-w-none mt-6 bricolage-grotesque-4 mx-auto font-light break-words">
      <%= for %{"data" => data, "id" => id, "type" => type} <- Moly.Helper.get_in_from_keys(@post, [:source, "post_content"]) |> JSON.decode! |> Moly.Helper.get_in_from_keys(["blocks"]) do %>
      <h2 id={id} :if={type == "header" && data["level"] == 2}>{data["text"]}</h2>
      <h3 id={id} :if={type == "header" && data["level"] == 3}>{data["text"]}</h3>
      <h4 id={id} :if={type == "header" && data["level"] == 4}>{data["text"]}</h4>
      <h5 id={id} :if={type == "header" && data["level"] == 5}>{data["text"]}</h5>
      <p id={id}  :if={type == "paragraph"}>{raw data["text"]}</p>
      <ol id={id} :if={type == "list" && data["style"] == "ordered"}>
        <li :for={item <- data["items"]}>{raw item["content"]}</li>
      </ol>
      <ul id={id} :if={type == "list" && data["style"] == "unordered"}>
        <li :for={item <- data["items"]}>{raw item["content"]}</li>
      </ul>
      <div id={id} class={["rounded-box border border-base-content/4 bg-base-100 not-prose", data["stretched"] && "overflow-x-auto"]} :if={type == "table"}>
        <table class="table">
          <thead :if={data["withHeadings"]}>
            <tr>
              <th :for={cell <- hd(data["content"])}>{raw cell}</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{row, i} <- Enum.with_index(data["content"])}>
              <td :if={!data["withHeadings"] || i > 0} :for={cell <- row}>{raw cell}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <% end %>
      <p class="flex flex-wrap items-center text-sm text-base-content/80 gap-2">
        <span class="mr-2">Tags:</span>
        <.link class="badge badge-ghost"  :for={tag <- Moly.Helper.get_in_from_keys(@post, [:source, "post_tag"])}>{tag["name"]}</.link>
      </p>
    </article>
    """
  end

  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :category_slug, :string, required: true
  def pagination(assigns) do
    ~H"""
    <nav id={@id || Moly.Helper.generate_random_id()} class={[@class, "flex gap-4 justify-center"]}>
      <.link class={["font-semibold", !@page_meta.prev && "opacity-50 pointer-events-none"]} navigate={@page_meta.prev && ~p"/posts/#{@category_slug}?page=#{@page_meta.prev}"}>« Previous</.link>
      <.link class={["font-semibold", page == @page_meta.current_page && "text-primary"]} :for={page <- @page_meta.page_range} href={~p"/posts/#{@category_slug}?page=#{page}"}>{page}</.link>
      <.link class={["font-semibold", !@page_meta.next && "opacity-50 pointer-events-none"]} navigate={@page_meta.next && ~p"/posts/#{@category_slug}?page=#{@page_meta.next}"}>Next »</.link>
    </nav>
    """
  end

end
