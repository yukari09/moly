defmodule MonorepoWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use MonorepoWeb, :controller` and
  `use MonorepoWeb, :live_view`.
  """
  use MonorepoWeb, :html

  embed_templates("layouts/*")

  def admin_items() do
    [
      %{
          title: "Dashboard",
          icon: "hero-home",
          url: ~p"/admin/dashboard",
          view: [MonorepoWeb.AdminDashboardLive]
      },
      %{
          title: "Accounts",
          icon: "hero-users",
          url: ~p"/admin/users",
          view: [MonorepoWeb.AdminUserLive.Index]
      },
      %{
          title: "Contents",
          icon: "hero-newspaper",
          items: [
              %{
                  title: "All posts",
                  url: ~p"/admin/posts",
                  view: [MonorepoWeb.AdminPostLive.Index],
                  show: true
              },
              %{
                  title: "Create new post",
                  url: ~p"/admin/post/create",
                  view: [MonorepoWeb.AdminPostLive.Create],
                  show: true
              },
              %{
                  title: "Categories",
                  url: ~p"/admin/categories",
                  view: [MonorepoWeb.AdminCategoryLive.Index],
                  show: true
              },
              %{
                  title: "Tags",
                  url: ~p"/admin/tags",
                  view: [MonorepoWeb.AdminTagLive.Index],
                  show: true
              }
          ]
      },
      %{
          title: "Media",
          icon: "hero-photo",
          url: ~p"/admin/media",
          view: [MonorepoWeb.AdminMediaLive.Index, MonorepoWeb.AdminMediaLive.Edit]
      },
      %{
          title: "Comments",
          icon: "hero-chat-bubble-left-right",
          url: ~p"/admin/comments",
          view: [MonorepoWeb.AdminCommentLive.Index]
      },
      %{
          title: "Pages",
          icon: "hero-document-text",
          items: [
            %{
              title: "All pages",
              url: ~p"/admin/pages",
              view: [MonorepoWeb.AdminPageLive.Index],
              show: true
            },
            %{
                title: "Create new page",
                url: ~p"/admin/page/create",
                view: [MonorepoWeb.AdminPageLive.Create],
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
                  view: [MonorepoWeb.AdminAffiliateLive.Index],
                  show: true
              },
              %{
                  title: "Create new affiliate",
                  url: ~p"/affiliate/submit",
                  view: [MonorepoWeb.AdminAffiliateLive.Create],
                  show: true
              },
              %{
                  title: "Categories",
                  url: ~p"/admin/affiliate/categories",
                  view: [MonorepoWeb.AdminAffiliateLive.Categories.Index],
                  show: true
              },
              %{
                  title: "Tags",
                  url: ~p"/admin/affiliate/tags",
                  view: [MonorepoWeb.AdminAffiliateLive.Tags.Index],
                  show: true
              }
          ]
      },
      %{
        title: "WebSite",
        icon: "hero-globe-alt",
        url: ~p"/admin/website",
        view: [MonorepoWeb.AdminAffiliateLive.Website.Index]
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
        Enum.reduce(item.items, item_views, fn(item, acc) ->
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

end
