defmodule MolyWeb.Affiliate.SubmitLive do
  use MolyWeb, :live_view

  require Ash.Query

  import MolyWeb.TailwindUI

  def mount(params, _session, socket) do
    {:ok, resource_socket(socket, params)}
  end


  defp resource_socket(socket, params) do
    post_name = Map.get(params, "post_name")
    is_active_user = Moly.Utilities.Account.is_active_user(socket.assigns.current_user)

    post =
      if is_nil(post_name) do
        %Moly.Contents.Post{}
      else
        Ash.Query.filter(
          Moly.Contents.Post,
          post_name == ^post_name and author_id == ^socket.assigns.current_user.id
        )
        |> Ash.Query.load([:affiliate_categories, :post_tags, post_meta: :children])
        |> Ash.read_first!(actor: socket.assigns.current_user)
      end

    if is_active_user && post do
      form =
        if post_name do
          AshPhoenix.Form.for_update(post, :update_post,
            forms: [auto?: true],
            actor: set_current_user_as_owner(socket.assigns.current_user)
          )
        else
          AshPhoenix.Form.for_create(Moly.Contents.Post, :create_post,
            forms: [auto?: true],
            actor: set_current_user_as_owner(socket.assigns.current_user)
          )
        end
        |> to_form()

      countries = get_term_taxonomy("countries", socket.assigns.current_user)
      industries = get_term_taxonomy("industries", socket.assigns.current_user)

      assign(socket, countries: countries, industries: industries, form: form, post: post)
      |> allow_upload(:media,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 6,
        max_file_size: 4_000_000
      )
      |> assign(:is_active_user, is_active_user)
    else
      push_navigate(socket, to: ~p"/")
    end
  end


  defp get_term_taxonomy(slug, current_user) do
    Ash.Query.filter(Moly.Terms.TermTaxonomy, parent.slug == ^slug)
    |> Ash.Query.load([:term])
    |> Ash.read!(actor: current_user)
  end


  defp set_current_user_as_owner(current_user),
    do: %{current_user | roles: [:owner | current_user.roles]}

end
