defmodule MolyWeb.AdminWebsiteLive.Appearance do
alias MolyWeb.DaisyUi
  use MolyWeb.Admin, :live_view

  def mount(_params, _session, socket) do
    socket = prepare(socket)
    {:ok, socket}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("remove", %{"slug" => slug}, socket) do
    {:noreply, remove_term_meta(socket, slug)}
  end

  def handle_event("save-theme", %{"form" => form}, socket) do
    socket =
      case AshPhoenix.Form.submit(socket.assigns.theme_form, params: form, action_opts: [actor: socket.assigns.current_user]) do
        {:ok, _changeset} ->
          push_navigate(socket, to: ~p"/admin/website/appearance")
        {:error, form} ->
          assign(socket, :theme_form, form)
      end
    {:noreply, socket}
  end

  def handle_progress(slug_subfix, entry, socket) do
    slug = "website-#{slug_subfix}"
    image_config = %{
      "website-logo" => [nil, nil, "webp"],
      "website-favicon"  => [60, 60, "png"],
      "website-auth-background" => [nil, nil, "webp"]
    }
    socket =
      if entry.done? do
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          socket = remove_term_meta(socket, slug)
          [w, h, f] = Map.get(image_config, slug)
          image_url = Moly.Helper.put_object(entry, path, "website") |> Moly.Helper.image_resize(w, h , f)
          term = Map.get(socket.assigns.appearance_items, slug)
          {:ok, record} = Ash.update(term, %{term_meta: [%{term_key: :name, term_value: image_url}]}, actor: socket.assigns.current_user)
          appearance_items = Map.put(socket.assigns.appearance_items, slug, record)
          socket = assign(socket, :appearance_items, appearance_items)
          {:ok, socket}
        end)
      else
        socket
      end
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <.header
        title="Appearance"
        size="md"
        description="Appearance website setting."
      />
      <div class="my-8">
        <div class="pb-4 divide-y space-y-4 divide-gray-100">
          <.form for={@theme_form} :let={f} class="pb-4" phx-submit="save-theme">
            <h3 class="font-medium">Theme</h3>
            <div class="mt-4">
            <input type="hidden" name={f[:name].name} value={"WebSite Theme"} />
            <input type="hidden" name={f[:slug].name} value={"website-theme"} />
            <.inputs_for :let={term_taxonomy} field={f[:term_taxonomy]}>
              <input type="hidden" name={term_taxonomy[:taxonomy].name} value="website" />
              <input type="hidden" name={term_taxonomy[:description].name} value="DaisyUI theme" />
            </.inputs_for>
            <.inputs_for :let={term_meta} field={f[:term_meta]}>
              <input type="hidden" name={term_meta[:term_key].name} value="name" />
              <div class="md:max-w-2/3">
                <.select field={term_meta[:term_value]} label="Theme" options={%{"light" => "Light", "purple" => "Purple", "red" => "Red", "green" => "Green", "orange" => "Orange", "yellow" => "Yellow", "cyan" => "Cyan"}} />
                <p class="text-sm mt-2 text-gray-500">DaisyUi theme definite on app.css</p>
              </div>
            </.inputs_for>
            <.button class="mt-4 block" variant="gray" type="submit" phx-disable="Changing">Change</.button>
            </div>
          </.form>
          <.form for={nil} phx-submit="save" class="py-4" phx-change="validate" :for={"website-"<>name = slug <- @slugs}>
            <h3 class="font-medium">{String.replace(name, "-", " ") |> String.capitalize()}</h3>
            <div class="mt-4" :if={!Moly.Helper.get_in_from_keys(@appearance_items, [slug, :term_meta, 0, :term_value])}>
              <.live_file_input upload={Map.get(@uploads, String.to_atom(name))} class="hidden" />
              <div :for={entry <- Moly.Helper.get_in_from_keys(@uploads, [String.to_atom(name), :entries])}>
                <.live_img_preview class={@slug_class[slug]} entry={entry} />
              </div>
              <.button class="mt-4 !px-0" variant="gray" phx-value-slug={slug} phx-disable="Saving">
                <label class="px-4 py-2" for={Moly.Helper.get_in_from_keys(@uploads, [String.to_atom(name), :ref])}>Add New</label>
              </.button>
            </div>
            <div class="mt-4" :if={Moly.Helper.get_in_from_keys(@appearance_items, [slug, :term_meta, 0, :term_value])}>
              <div class="min-h-10">
                <img class={@slug_class[slug]} src={Moly.Helper.get_in_from_keys(@appearance_items, [slug, :term_meta, 0, :term_value])} />
              </div>
              <.button class="mt-4" variant="gray" phx-click="remove" phx-value-slug={slug} phx-disable="Removing">Removal</.button>
            </div>
          </.form>
        </div>
      </div>
    """
  end

  defp remove_term_meta(socket, slug) do
    entry = Map.get(socket.assigns.appearance_items, slug)
    Enum.map(entry.term_meta, &(Ash.destroy(&1, actor: socket.assigns.current_user)))
    entry = Map.put(entry, :term_meta, [])
    items = socket.assigns.appearance_items
    new_items = Map.put(items, slug, entry)
    assign(socket, :appearance_items, new_items)
  end

  defp prepare(socket) do

    slugs = ["website-logo","website-favicon","website-auth-background"]
    slug_class = %{"website-logo" => "w-auto h-16","website-favicon" => "size-10","website-auth-background" => "h-48 w-auto"}

    appearance_items =
      Moly.Utilities.Term.get_terms_data_by_slug(slugs)
      |> Enum.reduce(%{}, fn v, acc -> Map.put(acc, "#{v.slug}", v)  end)

    theme_form =
      Moly.Utilities.Term.get_terms_data_by_slug(["website-theme"])
      |> case do
        [theme | _] ->
          AshPhoenix.Form.for_update(theme, :update, forms: term_from(theme))
        _ ->
          AshPhoenix.Form.for_create(Moly.Terms.Term, :create, forms: term_from())
      end

    socket
    |> allow_upload(:favicon, accept: ~w(.png), max_entries: 1, auto_upload: true, progress: &handle_progress/3)
    |> allow_upload(:logo, accept: ~w(.png .jpg .jpeg .webp), max_entries: 1, auto_upload: true, progress: &handle_progress/3)
    |> allow_upload(:"auth-background", accept: ~w(.png .jpg .jpeg .webp), max_entries: 1, auto_upload: true, progress: &handle_progress/3)
    |> assign(:appearance_items, appearance_items)
    |> assign(:slugs, slugs)
    |> assign(:slug_class, slug_class)
    |> assign(:theme_form, theme_form)
  end

  defp term_from(data \\ nil) do
    [
      term_taxonomy: [
        type: :list,
        resource: Moly.Terms.TermTaxonomy,
        update_action: :update,
        create_action: :create,
        data: data && data.term_taxonomy || [%Moly.Terms.TermTaxonomy{taxonomy: "website", description: "DaisyUI theme"}]
      ],
      term_meta: [
        type: :list,
        resource: Moly.Terms.TermMeta,
        update_action: :update,
        create_action: :create,
        data: data && data.term_meta || [%Moly.Terms.TermMeta{term_key: "name", term_value: "light"}]
      ]
    ]
  end




end
