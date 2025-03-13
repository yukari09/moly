defmodule MolyWeb.AdminAffiliateLive.Tags.Form do
  use MolyWeb.Admin, :live_component

  def update(
        %{form: form, modal_id: modal_id, patch_url: patch_url, current_user: current_user} =
          _assigns,
        socket
      ) do
    parent_categories =
      Moly.Terms.read_by_term_taxonomy!("category", nil, actor: current_user)
      |> Enum.map(&{&1.id, &1.name})

    socket =
      socket
      |> assign(:parent_categories, parent_categories)
      |> assign(:form, form)
      |> assign(:modal_id, modal_id)
      |> assign(:current_user, current_user)
      |> assign(:patch_url, patch_url)

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
          |> push_event("js-exec", %{to: "##{socket.assigns.modal_id}", attr: "phx-remove"})
          |> push_patch(to: socket.assigns.patch_url)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form id="submenu-form" :let={f} for={@form} class="space-y-4" phx-change="validate" phx-submit="save" phx-target={@myself}>
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
          <.button type="button" variant="outline" phx-click={JS.patch(@patch_url)}>Cancel</.button>
          <.button type="submit" form={f} phx-disable-with="Saving...">Save</.button>
        </div>
      </.form>
    </div>
    """
  end
end
