defmodule MonorepoWeb.Layouts.Helper do
  use MonorepoWeb, :live_component

  slot :inner_block
  def admin_sidebar(assigns) do
    ~H"""
    <.sidebar_provider>
      <.sidebar id="main-sidebar">
        <.sidebar_header>
          <div class="flex items-center gap-2">
            <img class="h-8" src="/images/logo.png" alt="Monorepo">
            <span class="font-bold">Monorepo</span>
          </div>
        </.sidebar_header>
        <.sidebar_content>
          <.sidebar_group :for={{group_name, group_items} <- admin_categories()}>
            <.sidebar_group_label>
              {group_name}
            </.sidebar_group_label>
            <.sidebar_group_content>
              <.sidebar_menu>
                <.collapsible
                  :for={item <- group_items}
                  id={id(item.title)}
                  as_child="as_child"
                  open={get_breadcrumbs_items(@view) |> Enum.member?(item.title)}
                  class="group/collapsible block"
                >
                  <.sidebar_menu_item>
                    <.as_child tag={&collapsible_trigger/1} child={&sidebar_menu_button/1} tooltip={item.title}>
                      <.dynamic :if={not is_nil(item.icon)} tag={item.icon} />
                      <span>
                        <%= item.title %>
                      </span>
                      <Lucideicons.chevron_right :if={Enum.count(item.items) > 0} class="ml-auto transition-transform duration-200 group-data-[state=open]/collapsible:rotate-90" />
                    </.as_child>
                    <.collapsible_content :if={Enum.count(item.items) > 0}>
                      <.sidebar_menu_sub>
                        <.sidebar_menu_sub_item :for={sub_item <- item.items} :if={sub_item.show} is_active={@view in sub_item.view} class={[ @view in sub_item.view && "bg-accent"]}>
                          <.as_child tag={&sidebar_menu_sub_button/1} child="a" phx-click={JS.patch(sub_item.url)} class="cursor-pointer">
                            <span>
                              <%= sub_item.title %>
                            </span>
                          </.as_child>
                        </.sidebar_menu_sub_item>
                      </.sidebar_menu_sub>
                    </.collapsible_content>
                  </.sidebar_menu_item>
                </.collapsible>
              </.sidebar_menu>
            </.sidebar_group_content>
          </.sidebar_group>
        </.sidebar_content>
        <.sidebar_footer>
          <.sidebar_menu>
            <.sidebar_menu_item>
              <.dropdown_menu class="block">
                <.as_child tag={&dropdown_menu_trigger/1}
                  child={&sidebar_menu_button/1}
                  size="lg"
                  class="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
                >
                  <.avatar class="h-8 w-8 rounded-lg">
                    <.avatar_image :if={Monorepo.Accounts.Helper.current_user_avatar(@current_user)} src={Monorepo.Accounts.Helper.current_user_avatar(@current_user)} alt={Monorepo.Accounts.Helper.current_user_name(@current_user)} />
                    <.avatar_fallback class="rounded-lg">
                      {Monorepo.Accounts.Helper.current_user_short_name(@current_user)}
                    </.avatar_fallback>
                  </.avatar>
                  <div class="grid flex-1 text-left text-sm leading-tight">
                    <span class="truncate font-semibold">
                      { Monorepo.Accounts.Helper.current_user_name(@current_user) }
                    </span>
                    <span class="truncate text-xs">
                      { @current_user.email }
                    </span>
                  </div>
                  <Lucideicons.chevrons_up_down class="ml-auto size-4" />
                </.as_child>
                <.dropdown_menu_content
                  class="w-[--radix-dropdown-menu-trigger-width] min-w-56 rounded-lg"
                  side="right"
                  align="end"
                  sideoffset="{4}"
                >
                  <.menu>
                    <.menu_label class="p-0 font-normal">
                      <div class="flex items-center gap-2 px-1 py-1.5 text-left text-sm">
                        <.avatar class="h-8 w-8 rounded-lg">
                          <.avatar_image :if={Monorepo.Accounts.Helper.current_user_avatar(@current_user)} src={Monorepo.Accounts.Helper.current_user_avatar(@current_user)} alt={Monorepo.Accounts.Helper.current_user_name(@current_user)} />
                          <.avatar_fallback class="rounded-lg">
                            {Monorepo.Accounts.Helper.current_user_short_name(@current_user)}
                          </.avatar_fallback>
                        </.avatar>
                        <div class="grid flex-1 text-left text-sm leading-tight">
                          <span class="truncate font-semibold">
                            { Monorepo.Accounts.Helper.current_user_name(@current_user) }
                          </span>
                          <span class="truncate text-xs">
                            { @current_user.email }
                          </span>
                        </div>
                      </div>
                    </.menu_label>
                    <%!-- <.menu_separator></.menu_separator>
                    <dropdownmenugroup>
                      <.menu_item>
                        <Lucideicons.sparkles class="w-4 h-4 mr-2" /> Upgrade to Pro
                      </.menu_item>
                    </dropdownmenugroup>
                    <.menu_separator></.menu_separator>
                    <dropdownmenugroup>
                      <.menu_item>
                        <Lucideicons.badge_check class="w-4 h-4 mr-2" /> Account
                      </.menu_item>
                      <.menu_item>
                        <Lucideicons.credit_card class="w-4 h-4 mr-2" /> Billing
                      </.menu_item>
                      <.menu_item>
                        <Lucideicons.bell class="w-4 h-4 mr-2" /> Notifications
                      </.menu_item>
                    </dropdownmenugroup> --%>
                    <.menu_separator></.menu_separator>
                    <.menu_item>
                      <Lucideicons.log_out class="w-4 h-4 mr-2" /> Log out
                    </.menu_item>
                  </.menu>
                </.dropdown_menu_content>
              </.dropdown_menu>
            </.sidebar_menu_item>
          </.sidebar_menu>
        </.sidebar_footer>
        <.sidebar_rail />
      </.sidebar>
      <.sidebar_inset>
        <header class="flex h-16 shrink-0 items-center gap-2 border-b px-4">
          <.sidebar_trigger target="main-sidebar" class="-ml-1">
            <Lucideicons.panel_left class="w-4 h-4" />
          </.sidebar_trigger>
          <.separator orientation="vertical" class="mr-2 h-4"></.separator>
          <.breadcrumb>
            <.breadcrumb_list>

              <%= for c <- get_breadcrumbs_items(@view) |> Enum.map_intersperse(:separator, & &1) do %>
              <.breadcrumb_item class="hidden md:block" :if={c != :separator}>
                <.breadcrumb_link href="#">
                  {c}
                </.breadcrumb_link>
              </.breadcrumb_item>

              <.breadcrumb_separator class="hidden md:block" :if={c == :separator}></.breadcrumb_separator>
              <% end %>

            </.breadcrumb_list>
          </.breadcrumb>
        </header>
        <div class="flex flex-1 flex-col gap-4 p-4">
          <%= render_slot(@inner_block) %>
        </div>
      </.sidebar_inset>
    </.sidebar_provider>
    """
  end

  defp admin_categories do
    %{
      General: [
        %{
          title: "Accounts",
          url: "#",
          icon: &Lucideicons.circle_user/1,
          is_active: true,
          items: [
            %{
              title: "Users",
              url: ~p"/admin/users",
              view: [MonorepoWeb.UserLive.Index],
              show: true
            }
          ]
        },
        %{
          title: "Contents",
          url: "#",
          icon: &Lucideicons.pen_tool/1,
          items: [
            %{
              title: "Posts",
              url: ~p"/admin/posts",
              view: [MonorepoWeb.PostLive.Index],
              show: true
            },
            %{
              title: "Create Posts",
              url: ~p"/admin/posts/new",
              view: [MonorepoWeb.PostLive.New],
              show: false
            },
            %{
              title: "Categories",
              url: ~p"/admin/categories",
              view: [MonorepoWeb.CategoryLive.Index],
              show: true
            },
            %{
              title: "Tags",
              url: ~p"/admin/tags",
              view: [MonorepoWeb.TagLive.Index],
              show: true
            }
          ]
        },
        %{
          title: "Comments",
          url: "#",
          icon: &Lucideicons.message_square_dot/1,
          items: [
            %{
              title: "Comments",
              url: "#",
              view: [],
              show: true
            }
          ]
        },
        %{
          title: "WebSite",
          url: "#",
          icon: &Lucideicons.settings/1,
          items: [
            %{
              title: "Privacy",
              url: "#",
              view: [],
              show: true
            },
            %{
              title: "Terms",
              url: "#",
              view: [],
              show: true
            },
            %{
              title: "Press",
              url: "#",
              view: [],
              show: true
            },
            %{
              title: "About Us",
              url: "#",
              view: [],
              show: true
            },
            %{
              title: "Social Network",
              url: "#",
              view: [],
              show: true
            },
          ]
        }
      ]
    }
  end

  defp get_breadcrumbs_items(view) do
    Enum.reduce(admin_categories(), [], fn {group_name, group_items}, acc ->
      Enum.reduce(group_items, acc, fn group_item, acc ->
        Enum.reduce(group_item.items, acc, fn item, acc ->
          if view in item.view, do: [group_name, group_item.title, item.title | acc], else: acc
        end)
      end)
    end)
  end


end
