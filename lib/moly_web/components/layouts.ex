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

  embed_templates("layouts/*")

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
        title: "Affiliate",
        icon: "hero-briefcase",
        items: [
          %{
            title: "All affiliates",
            url: ~p"/admin/affiliates",
            view: [MolyWeb.AdminAffiliateLive.Index],
            show: true
          },
          %{
            title: "Create new affiliate",
            url: ~p"/affiliate/submit",
            view: [MolyWeb.AdminAffiliateLive.Create],
            show: true
          },
          %{
            title: "Categories",
            url: ~p"/admin/affiliate/categories",
            view: [MolyWeb.AdminAffiliateLive.Categories.Index],
            show: true
          },
          %{
            title: "Tags",
            url: ~p"/admin/affiliate/tags",
            view: [MolyWeb.AdminAffiliateLive.Tags.Index],
            show: true
          }
        ]
      },
      %{
        title: "WebSite",
        icon: "hero-globe-alt",
        url: ~p"/admin/website",
        view: [MolyWeb.AdminWebsiteLive.Index]
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

  def nav_categories() do
    [
      {"Browse", MolyWeb.Affinew.Links.programs()},
      {"AI & Tech", MolyWeb.Affinew.Links.term("ai-technology")},
      {"Financial", MolyWeb.Affinew.Links.term("financial-insurance")},
      {"SaaS", MolyWeb.Affinew.Links.term("saas-solutions")}
    ]
    # [
    #   {"Browse", MolyWeb.Affinew.Links.programs()},
    #   {"Categories", MolyWeb.Affinew.Links.under_construction()},
    #   {"News", MolyWeb.Affinew.Links.under_construction()},
    #   {"Resources", MolyWeb.Affinew.Links.under_construction()}
    # ]
  end
end
