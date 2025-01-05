defmodule MonorepoWeb.AdminPostLive.NewCategory do
  use MonorepoWeb.Admin, :live_view

  def mount(_params, %{"user" => "user?id="<>user_id, "modal_id" => modal_id}, socket) do
    current_user =
      Ash.get!(Monorepo.Accounts.User, user_id, context: %{private: %{ash_authentication?: true}})

    parent_categories =
      Monorepo.Terms.read_by_term_taxonomy!("category", nil, actor: current_user)
      |> Enum.map(&{&1.id, &1.name})

    socket =
      socket
      |> assign(:parent_categories, parent_categories)
      |> assign(:form, category_to_form())
      |> assign(:current_user, current_user)
      |> assign(:modal_id, modal_id)

    {:ok, socket}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form =  AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"form" => params}, socket) do
    :timer.sleep(50)
    case AshPhoenix.Form.submit(socket.assigns.form, params: params, action_opts: [actor: socket.assigns.current_user]) do
      {:ok, result} ->
        socket =
          socket
          |> push_event("js-exec", %{to: "##{socket.assigns.modal_id}", attr: "phx-remove"})
        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end

  def render(assigns) do
    ~H"""
    <.form id="submenu-form" :let={f} for={@form} class="space-y-4" phx-change="validate" phx-submit="save">
      <div>
        <.input field={f[:name]} label="New Category Name" phx-debounce="blur" autocomplete="off" help_text="Input a new category name"/>
      </div>
      <div>
        <.input field={f[:slug]} label="Slug" phx-debounce="blur" value={f[:name].value} autocomplete="off" help_text="Input a slug"/>
      </div>
      <div>
      <.inputs_for :let={term_taxonomy} field={f[:term_taxonomy]}>
        <.input field={term_taxonomy[:taxonomy]} value="category" label={nil} class="hidden" />
        <.select field={term_taxonomy[:parent_id]} options={@parent_categories} label="Parent Category" prompt="Select a parent category(option)"  />
      </.inputs_for>
      </div>
      <div class="flex justify-end">
        <.button type="button" variant="outline" phx-click={hide_modal(@modal_id)}>Cancel</.button>
        <.button type="submit" form={f} phx-disable-with="Saving...">Save</.button>
      </div>
    </.form>
    """
  end

  defp category_to_form() do
    AshPhoenix.Form.for_create(Monorepo.Terms.Term, :create_category, [
      forms: [
        term_taxonomy: [
          type: :list,
          data: [%Monorepo.Terms.TermTaxonomy{taxonomy: "category"}],
          resource: Monorepo.Terms.TermTaxonomy,
          update_action: :create
        ]
      ]
    ])
    |> to_form()
  end


end
