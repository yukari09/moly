defmodule MolyWeb.AdminWebsiteLive.SocialLinks do
  use MolyWeb.Admin, :live_view

  def mount(_params, _session, socket) do
    socket = prepare(socket)
    {:ok, socket}
  end

  def handle_event("save", %{"form" => form}, socket) do
    id = Map.get(form, "id")
    form_entry = Map.get(socket.assigns.forms, id)
    socket =
      if form_entry do
        {:ok, changeset} = AshPhoenix.Form.submit(form_entry, params: form, action_opts: [actor: socket.assigns.current_user])
        assign_form = Map.put(socket.assigns.forms, id, term_to_form(changeset))
        assign(socket, :forms, assign_form)
      else
        socket
      end
    {:noreply, socket}
  end

  @impl true
  def handle_event("add-form", %{"path" => "term_meta-"<>form_id}, socket) do
    old_form = socket.assigns.forms[form_id]
    new_form = AshPhoenix.Form.add_form(old_form, "form[term_meta]" , params: %{})
    forms = Map.put(socket.assigns.forms, form_id, new_form)
    socket = assign(socket, :forms, forms)
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove-form", %{"path" => fake_path}, socket) do
    [real_path, form_id] = String.split(fake_path, "--")
    old_form = socket.assigns.forms[form_id]
    new_form = AshPhoenix.Form.remove_form(old_form, real_path)
    forms = Map.put(socket.assigns.forms, form_id, new_form)
    socket = assign(socket, :forms, forms)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <.header
        title="Social Links"
        size="md"
        description="Social links setting."
      />
      <div class="space-y-4 divide-y divide-gray-100 my-8">
        <div :for={{form_id, form} <- @forms} class="py-4">
          <.form :let={f} for={form} phx-submit="save">
            <%!-- <h3 class="font-medium">{f[:name].value}</h3> --%>
            <div class=" border-b border-gray-200 py-4 space-y-4 min-h-96">
              <input class="hidden" type="hidden"  name={f[:name].name} value={f[:name].value}/>
              <input class="hidden" type="hidden"  name={f[:slug].name} value={f[:slug].value}/>
              <input class="hidden" type="hidden"  name={f[:id].name} value={f[:id].value}/>
              <.inputs_for :let={ff} field={f[:term_meta]}>
               <div class="flex items-center gap-2">
                <%!-- <.input field={ff[:term_key]} name={ff[:term_key].name} value={ff[:term_key].value} class="max-w-md"/> --%>
                <.select field={ff[:term_key]} class="max-w-md" options={[Facebook: "Facebook", X: "X", Instagram: "Instagram", Linkedin: "LinkedIn", Youtube: "YouTube", Tiktok: "TikTok"]} label={nil} />
                <.input field={ff[:term_value]} name={ff[:term_value].name} value={ff[:term_value].value} container_class="flex-1 max-w-md" show_error={false}/>
                <.button
                  variant="gray"
                  size="sm"
                  class="mb-0"
                  type="button"
                  phx-click="remove-form"
                  phx-value-path={"#{ff.name}--#{form_id}"}
                >
                  <.icon name="hero-minus" class="size-4" />
                </.button>
              </div>
              </.inputs_for>
              <%!-- <p class="mt-2 text-xs text-gray-500">{f[:term_taxonomy].value |> Moly.Helper.get_in_from_keys([0, :source, :data, :description])}</p> --%>
            </div>
            <div class="flex items-center mt-4 gap-2">
              <.button type="submit" variant="primary" phx-disable="Saving">Save</.button>
              <.button
                variant="gray"
                type="button"
                phx-click="add-form"
                phx-value-path={"term_meta-#{form_id}"}
              >
                <.icon name="hero-plus" class="size-4" /> Add Link
              </.button>
            </div>
          </.form>
        </div>
      </div>
    """
  end


  def prepare(socket) do
    slugs = ["website-social-links"]
    forms =
      Moly.Utilities.Term.get_terms_data_by_slug(slugs)
      |> Enum.reduce(%{}, fn v, acc -> Map.put(acc, "#{v.id}", term_to_form(v))  end)
    socket
    |> assign(:forms, forms)
  end

  defp term_to_form(data) do
    AshPhoenix.Form.for_update(data, :update, forms: [
      term_taxonomy: [
        type: :list,
        resource: Moly.Terms.TermTaxonomy,
        update_action: :update,
        create_action: :create,
        data: data.term_taxonomy
      ],
      term_meta: [
        type: :list,
        resource: Moly.Terms.TermMeta,
        update_action: :update,
        create_action: :create,
        data: data.term_meta
      ]
    ])
  end
end
