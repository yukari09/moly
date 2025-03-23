defmodule MolyWeb.AdminPostLive.NewCategory do
  use MolyWeb.Admin, :live_view

  def mount(_params, %{"user" => "user?id=" <> user_id}, socket) do
    current_user =
      Ash.get!(Moly.Accounts.User, user_id, context: %{private: %{ash_authentication?: true}})

    parent_categories =
      Moly.Terms.read_by_term_taxonomy!("category", nil, actor: current_user)
      |> Enum.map(&{&1.id, &1.name})

    socket =
      socket
      |> assign(:parent_categories, parent_categories)
      |> assign(:form, category_to_form())
      |> assign(:current_user, current_user)

    {:ok, socket}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"form" => params}, socket) do
    :timer.sleep(50)

    case AshPhoenix.Form.submit(socket.assigns.form,
           params: params,
           action_opts: [actor: socket.assigns.current_user]
         ) do
      {:ok, _result} ->
        socket =
          socket
          |> push_event("js-exec", %{to: "#create_category_modal_id", attr: "phx-remove"})
          |> assign(:form, category_to_form())

        send_update(socket.parent_pid, MolyWeb.AdminPostLive.FormField.PostCategories,
          id: "form-field-post-categories"
        )

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end

  def render(assigns) do
    ~H"""
    <.form
      :let={f}
      id="submenu-form"
      for={@form}
      class="space-y-4"
      phx-change="validate"
      phx-submit="save"
    >
      <div>
        <.input
          field={f[:name]}
          label="New Category Name"
          phx-debounce="blur"
          autocomplete="off"
          help_text="Input a new category name"
        />
      </div>
      <div>
        <.input
          field={f[:slug]}
          label="Slug"
          phx-debounce="blur"
          value={f[:name].value}
          autocomplete="off"
          help_text="Input a slug"
        />
      </div>
      <div>
        <.inputs_for :let={term_taxonomy} field={f[:term_taxonomy]}>
          <.input field={term_taxonomy[:taxonomy]} value="category" label={nil} class="hidden" />
          <.select
            field={term_taxonomy[:parent_id]}
            options={@parent_categories}
            label="Parent Category"
            prompt="Select a parent category(option)"
          />
        </.inputs_for>
      </div>
      <div class="flex justify-end">
        <.button type="button" variant="outline" phx-click={hide_modal("create_category_modal_id")}>
          Cancel
        </.button>
        <.button type="submit" form={f} phx-disable-with="Saving...">Save</.button>
      </div>
    </.form>
    """
  end

  defp category_to_form() do
    AshPhoenix.Form.for_create(Moly.Terms.Term, :create,
      forms: [
        term_taxonomy: [
          type: :list,
          data: [%Moly.Terms.TermTaxonomy{taxonomy: "category"}],
          resource: Moly.Terms.TermTaxonomy,
          update_action: :create
        ]
      ]
    )
    |> to_form()
  end
end
