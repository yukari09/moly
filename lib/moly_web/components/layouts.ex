defmodule MolyWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use MolyWeb, :controller` and
  `use MolyWeb, :live_view`.
  """
  use MolyWeb, :html

  require Ash.Query

  embed_templates("layouts/*")

  @navbar_item_cache_key "Moly:Layouts:Cache:Data:Navbar:Items"

  def admin_items() do
    [
      %{
        title: "Dashboard",
        icon: "hero-home",
        url: ~p"/admin/dashboard",
        view: [MolyWeb.AdminDashboardLive]
      },
      %{
        title: "Accounts",
        icon: "hero-users",
        url: ~p"/admin/users",
        view: [MolyWeb.AdminUserLive.Index]
      },
      %{
        title: "Contents",
        icon: "hero-newspaper",
        items: [
          %{
            title: "All posts",
            url: ~p"/admin/posts",
            view: [MolyWeb.AdminPostLive.Index],
            show: true
          },
          %{
            title: "Create new post",
            url: ~p"/admin/post/create",
            view: [MolyWeb.AdminPostLive.Create],
            show: true
          },
          %{
            title: "Categories",
            url: ~p"/admin/categories",
            view: [MolyWeb.AdminCategoryLive.Index],
            show: true
          },
          %{
            title: "Tags",
            url: ~p"/admin/tags",
            view: [MolyWeb.AdminTagLive.Index],
            show: true
          }
        ]
      },
      %{
        title: "Media",
        icon: "hero-photo",
        url: ~p"/admin/media",
        view: [MolyWeb.AdminMediaLive.Index, MolyWeb.AdminMediaLive.Edit]
      },
      %{
        title: "Comments",
        icon: "hero-chat-bubble-left-right",
        url: ~p"/admin/comments",
        view: [MolyWeb.AdminCommentLive.Index]
      },
      %{
        title: "Pages",
        icon: "hero-document-text",
        items: [
          %{
            title: "All pages",
            url: ~p"/admin/pages",
            view: [MolyWeb.AdminPageLive.Index],
            show: true
          },
          %{
            title: "Create new page",
            url: ~p"/admin/page/create",
            view: [MolyWeb.AdminPageLive.Create],
            show: true
          }
        ]
      },
      %{
        title: "WebSite",
        icon: "hero-globe-alt",
        # url: ~p"/admin/website",
        items: [
          %{
            title: "Basic",
            url: ~p"/admin/website/basic",
            view: [MolyWeb.AdminWebsiteLive.Basic],
            show: true
          },
          %{
            title: "Appearance",
            url: ~p"/admin/website/appearance",
            view: [MolyWeb.AdminWebsiteLive.Appearance],
            show: true
          }
        ]
        # view: [MolyWeb.AdminWebsiteLive.Index]
      }
    ]
  end

  def admin_is_active_item(socket, item) do
    item_views =
      if Map.has_key?(item, :view) do
        item.view
      else
        []
      end

    item_views =
      if Map.has_key?(item, :items) do
        Enum.reduce(item.items, item_views, fn item, acc ->
          if Map.has_key?(item, :view) do
            [item.view | acc]
          else
            acc
          end
        end)
      else
        item_views
      end

    item_views = List.flatten(item_views)
    socket.view in item_views
  end

  def navbar_item() do
    show_in_navbar_term = fn ->
      Ash.Query.new(Moly.Terms.Term)
      |> Ash.Query.filter(term_meta.term_value in ["1", "true", "on"] and term_meta.term_key == "show_in_navbar")
      |> Ash.Query.load([:term_taxonomy, :term_meta])
      |> Ash.Query.sort(name: :asc)
      |> Ash.read!(actor: %{roles: [:user]})
    end
    Moly.Utilities.cache_get_or_put(@navbar_item_cache_key, show_in_navbar_term, :timer.hours(2))
  end

  def delete_navbar_item_cache(), do: Moly.Utilities.cache_exists?(@navbar_item_cache_key)

end
