defmodule MolyWeb.AdminCategoryLive.Form do
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
        socket =
          assign(socket, :form, form)
          |> put_flash(:error, "Error: #{JSON.encode!(form.errors)}")
        {:noreply, assign(socket, :form, form)}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        id="submenu-form"
        for={@form}
        class="space-y-4"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
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
            value={f[:slug].value}
            autocomplete="off"
            help_text="Input a slug"
          />
        </div>
        <div>
          <.inputs_for :let={term_taxonomy} field={f[:term_taxonomy]}>
            <.input field={term_taxonomy[:taxonomy]} value="category"  class="hidden" />
            <.select
              field={term_taxonomy[:parent_id]}
              options={@parent_categories}
              label="Parent Category"
              prompt="Select a parent category(option)"
            />
            <div :if={term_taxonomy[:taxonomy].value == "category"} class="mt-4">
            <.textarea field={term_taxonomy[:description]} placeholder="option" label={"Keyword"}/>
            </div>
          </.inputs_for>
        </div>
        <div>
          <.inputs_for :let={ff} field={f[:term_meta]}>
            <.checkbox field={ff[:fake]} label={"Show in navbar?"} name="" checked={ff[:term_value].value == "1"} phx-update="ignore" phx-click={JS.toggle_attribute({"value", "1", "0"}, to: "##{ff[:term_value].id}")}/>
            <.input field={ff[:term_key]} value="show_in_navbar" container_class="hidden" show_error={false}/>
            <.input field={ff[:term_value]} container_class="hidden" value={ff[:term_value].value || "0"} show_error={false}/>
          </.inputs_for>
        </div>
        <div class="flex justify-end gap-2">
          <.button type="button" variant="gray" phx-click={JS.patch(@patch_url)}>Cancel</.button>
          <.button type="submit" form={f} phx-disable-with="Saving...">Save</.button>
        </div>
      </.form>
    </div>
    """
  end
end
