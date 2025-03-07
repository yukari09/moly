defmodule MonorepoWeb.AdminWebsiteLive.Form do
  use MonorepoWeb.Admin, :live_component

  def update(%{patch_url: patch_url, id: id, current_user: user, item: item}, socket) do
    socket =
      socket
      |> assign(:patch_url, patch_url)
      |> assign(:id, id)
      |> assign(:current_user, user)
      |> assign(:item, item)
      |> resource_form()

    {:ok, socket}
  end

  def handle_event("add-form", %{"path" => path}, socket) do
    form = AshPhoenix.Form.add_form(socket.assigns.form, path, params: %{})
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("remove-form", %{"path" => path}, socket) do
    form = AshPhoenix.Form.remove_form(socket.assigns.form, path)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("change", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"form" => params}, socket) do
    socket =
      AshPhoenix.Form.submit(socket.assigns.form,
        params: params,
        action_opts: [actor: socket.assigns.current_user]
      )
      |> case do
        {:ok, _} ->
          socket
          |> push_event("js-exec", %{to: "##{socket.assigns.id}", attr: "phx-remove"})
          |> push_patch(to: socket.assigns.patch_url)
        {:error, form} ->
          assign(socket, :form, form)
      end
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div id={@id} class="py-6">
    <.form :let={f} for={@form} class="space-y-4" phx-change="change" phx-submit="save" phx-target={@myself}>
      <.input label="Name of Environment" field={f[:name]}  show_error={false} />
      <.input label="Slug" field={f[:slug]} show_error={false}/>
      <input name={f[:term_taxonomy].name<>"[0][taxonomy]"} value="website" class="hidden" type="hidden">
      <div class="border-b"></div>
      <.inputs_for :let={ff} field={f[:term_meta]}>
        <div class="flex items-center gap-2">
          <.input field={ff[:term_key]} placeholder="Name" show_error={false} />
          <.input field={ff[:term_value]} placeholder="Value" show_error={false}/>
          <.button variant="gray" size="sm" phx-click="remove-form" phx-target={@myself} phx-value-path={ff.name}>
            <.icon name="hero-minus" class="size-3" />
          </.button>
        </div>
      </.inputs_for>
      <.button variant="gray" size="sm" phx-target={@myself} type="button" phx-click="add-form" phx-value-path={@form.name <> "[term_meta]"}>
        <.icon name="hero-plus" class="size-4"/> Add a item
      </.button>
      <.button size="sm" type="submit" form={f} phx-disable-with="Saving..." class="absolute right-0 top-0 mr-4 !mt-4">Save</.button>
    </.form>
    </div>
    """
  end

  defp resource_form(%{assigns: %{item: nil}} = socket) do
    form = AshPhoenix.Form.for_create(Monorepo.Terms.Term, :create, [forms: [auto?: true], actor: socket.assigns.current_user])
    assign(socket, :form, form)
  end

  defp resource_form(%{assigns: %{item: %Monorepo.Terms.Term{} = item}} = socket) do
    forms = [
      term_taxonomy: [
        type: :list,
        resource: Monorepo.Terms.TermTaxonomy,
        update_action: :update,
        create_action: :create,
        data: item.term_taxonomy
      ],
      term_meta: [
        type: :list,
        resource: Monorepo.Terms.TermMeta,
        update_action: :update,
        create_action: :create,
        data: item.term_meta
      ]
    ]
    form = AshPhoenix.Form.for_update(item, :update, [forms: forms, actor: socket.assigns.current_user])
    assign(socket, :form, form)
  end

end
