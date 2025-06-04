defmodule MolyWeb.AdminPageLive.Create do
  use MolyWeb.Admin, :live_view

  def mount(%{"preview_id" => preview_id, "layout" => layout}, _session, socket) do
    Phoenix.PubSub.subscribe(Moly.PubSub, "#{pubsub_channel(preview_id)}")
    layout = if layout == "false", do: false, else: {MolyWeb.Layouts, :app}
    preview_content = get_or_put_preview_content_cache(preview_id)

    {:ok, socket,
     layout: layout, temporary_assigns: [preview_content: preview_content, preview_id: preview_id]}
  end

  def mount(_params, _session, socket) do
    editor_id = Moly.Helper.generate_random_id()
    preview_id = Moly.Helper.generate_random_id()
    textarea_id = Moly.Helper.generate_random_id()
    modal_id = Moly.Helper.generate_random_id()

    socket =
      assign(socket, :layout, false)
      |> assign(:form_data, %{layout: ~c'false'})
      |> assign(:invaild_form_data, true)

    {
      :ok,
      socket,
      temporary_assigns: [
        editor_id: editor_id,
        preview_id: preview_id,
        textarea_id: textarea_id,
        modal_id: modal_id
      ],
      layout: false
    }
  end

  def handle_event("initiate_editor", _, socket) do
    socket =
      push_event(
        socket,
        "page:create:editor",
        %{
          preview_id: socket.assigns.preview_id,
          editor_id: socket.assigns.editor_id,
          textarea_id: socket.assigns.textarea_id
        }
      )

    {:noreply, socket}
  end

  def handle_event("change-preview", %{"layout" => layout} = params, socket) do
    socket =
      assign(socket, :layout, layout)
      |> broadcast()
      |> params_to_form_data(params)

    {:noreply, socket}
  end

  def handle_event("change-preview", %{"content" => content} = params, socket) do
    get_or_put_preview_content_cache(socket.assigns.preview_id, content)

    socket =
      broadcast(socket)
      |> params_to_form_data(params)

    {:noreply, socket}
  end

  def handle_event("change-preview", %{"post_title" => _} = params, socket) do
    socket = socket |> params_to_form_data(params)
    {:noreply, socket}
  end

  def handle_event("navigate-preview", _params, socket) do
    socket = push_event(socket, "blank_link", %{url: live_view_url(socket)})
    {:noreply, socket}
  end

  def handle_event("submit", _, socket) do
    socket =
      case AshPhoenix.Form.submit(socket.assigns.form) do
        {:ok, _form} ->
          socket
          |> push_navigate(to: ~p"/admin/pages")

        {:error, _record} ->
          socket
          |> put_flash(:error, "An error occurred on the server, please try again later...")
      end

    {:noreply, socket}
  end

  def handle_info(%{new_link: new_link}, socket) do
    {:noreply, push_navigate(socket, to: new_link)}
  end

  defp get_or_put_preview_content_cache(preview_id, preview_content_value \\ nil) do
    key = "admin:pages:preview:#{preview_id}"

    if preview_content_value,
      do: Cachex.put!(:cache, key, preview_content_value, expire: :timer.minutes(15)),
      else: Cachex.get!(:cache, key)
  end

  defp pubsub_channel(preview_id), do: "#{MolyWeb.Admin.topic(:page)}:#{preview_id}"

  defp broadcast(socket) do
    pubsub_channel = pubsub_channel(socket.assigns.preview_id)
    Phoenix.PubSub.broadcast(Moly.PubSub, pubsub_channel, %{new_link: live_view_url(socket)})
    socket
  end

  defp live_view_url(socket) do
    url_params = %{layout: socket.assigns.layout, preview_id: socket.assigns.preview_id}
    ~p"/admin/page/preview?#{url_params}"
  end

  defp params_to_form_data(socket, params) do
    form_data = socket.assigns.form_data
    check_fields = [:post_title, :content, :layout]

    form_data =
      Enum.reduce(check_fields, form_data, fn field, acc ->
        field_value = Map.get(params, to_string(field))
        field_value = if field_value, do: field_value, else: Map.get(form_data, field)
        Map.put(acc, field, field_value)
      end)

    invaild_form_data = Enum.any?(check_fields, &(Map.get(form_data, &1) in [false, nil, ""]))

    form_data =
      if invaild_form_data do
        form_data
      else
        new_form_data =
          %{
            post_status: :draft,
            post_content: form_data.content,
            post_type: :page,
            post_date: DateTime.utc_now(),
            post_meta: [%{meta_key: :page_layout, meta_value: form_data.layout != "false"}]
          }

        Map.merge(form_data, new_form_data)
      end

    socket = assign(socket, form_data: form_data, invaild_form_data: invaild_form_data)

    if invaild_form_data do
      socket
    else
      form =
        AshPhoenix.Form.for_create(Moly.Contents.Post, :create_post,
          forms: [auto?: true],
          actor: socket.assigns.current_user
        )
        |> to_form()
        |> AshPhoenix.Form.validate(form_data)

      assign(socket, :form, form)
    end
  end
end
