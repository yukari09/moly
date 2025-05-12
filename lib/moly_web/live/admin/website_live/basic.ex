defmodule MolyWeb.AdminWebsiteLive.Basic do
  use MolyWeb.Admin, :live_view

  @actor %{roles: [:admin]}

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

  def render(assigns) do
    ~H"""
      <.header
        title="WebSite Basic"
        size="md"
        description="Basic website setting."
      />
      <div class="space-y-4 divide-y divide-gray-100 my-8">
        <div :for={{_, form} <- @forms} class="py-4">
          <.form :let={f} for={form} phx-submit="save">
            <h3>{f[:name].value}</h3>
            <div class="mt-2">
              <input class="hidden" type="hidden"  name={f[:name].name} value={f[:name].value}/>
              <input class="hidden" type="hidden"  name={f[:slug].name} value={f[:slug].value}/>
              <input class="hidden" type="hidden"  name={f[:id].name} value={f[:id].value}/>
              <.inputs_for :let={ff} field={f[:term_meta]}>
                <.input :if={f[:slug].value  in ["website-name", "website-title", "website-blog-list-title"]} field={ff[:term_value]} class="max-w-sm"/>
                <.textarea :if={f[:slug].value not in ["website-name", "website-title", "website-blog-list-title"]} field={ff[:term_value]} class="max-w-sm"/>
                <input type="hidden" name={ff[:term_key].name} value={ff[:term_key].value} />
              </.inputs_for>
              <p class="mt-2 text-xs text-gray-500">{f[:term_taxonomy].value |> Moly.Helper.get_in_from_keys([0, :source, :data, :description])}</p>
            </div>
            <.button type="submit" class="mt-4" variant="gray" phx-disable="Saving">Change</.button>
          </.form>
        </div>
      </div>
    """
  end

  def prepare(socket) do
    slugs = ["website-name", "website-title", "website-description", "website-blog-list-title", "website-blog-list-description"]
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
