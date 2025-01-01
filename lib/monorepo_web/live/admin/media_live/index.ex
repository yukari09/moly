defmodule MonorepoWeb.AdminMediaLive.Index do
  use MonorepoWeb.Admin

  require Logger

  @per_page "12"
  @model Monorepo.Contents.Post

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> allow_upload(
        :media,
        accept: ~w(.jpg .jpeg .png .webp .svg .mp4 .avif .webm),
        auto_upload: true,
        max_file_size: 50_000_000,
        progress: &handle_progress/3,
        max_entries: 120
      )
    }
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{params: _}} = socket) do
    socket =
      socket
      |> assign(initial_params(params))
      |> get_list_by_params(true)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    new_socket =
      socket
      |> assign(initial_params(params))
      |> get_list_by_params()
    {:noreply, new_socket}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    error_entries =
      Enum.reduce(socket.assigns.uploads.media.entries, [], fn entry, acc ->
        case upload_errors(socket.assigns.uploads.media, entry) do
          [] -> acc
          entry_errors ->
            errors =
              Enum.map(entry_errors, &upload_error_message(entry.client_name, &1))
            acc ++ [{entry, errors}]
        end
      end)

    socket = Enum.reduce(error_entries, socket, fn {entry, _}, socket -> cancel_upload(socket, :media, entry.ref) end)
    errors = Enum.reduce(error_entries, [], fn {_, errors}, acc -> acc ++ errors end)

    socket =
      if errors == [] do
        socket
      else
        put_flash(socket, :error, Enum.join(errors, "\n"))
      end

    {:noreply, socket}
  end


  def handle_event("media:delete:selected", %{"data-id" => data_id}, socket) do
    data_id = String.split(data_id, ",")

    current_user = socket.assigns.current_user

    socket =
      Enum.reduce(data_id, socket, fn id, socket ->
        start_async(socket, "delete_media_#{id}", fn -> Ash.get!(@model, id, actor: current_user) end)
      end)

    {:noreply, socket}
  end

  def handle_event("load-more", _params, socket) do
    page = is_integer(socket.assigns.page) && socket.assigns.page || String.to_integer(socket.assigns.page)
    page = page + 1
    socket =
      socket
      |> assign(:page, page)
      |> get_list_by_params()
    {:noreply, socket}
  end

  def handle_event("search-image", %{"q" => q}, socket) do
    socket =
      socket
      |> assign(:q, q)
      |> assign(:page, 1)
      |> get_list_by_params(true)
    {:noreply, socket}
  end



  def handle_progress(:media, entry, socket) do
    if entry.done? do
      consume_uploaded_entry(socket, entry, fn %{path: path} ->
        new_path = "#{path}-#{entry.uuid}"
        case File.rename(path, new_path) do
          :ok ->
            Task.async(fn ->
              {:media_upload, {entry, new_path}}
            end)
            {:ok, nil}
          {:error, reason} ->
            {:error, reason}
        end
      end)

      {:noreply, socket}
    else
      entry = Map.put(entry, :id, entry.uuid)
      socket = stream_insert(socket, :medias, entry, at: 0)
      {:noreply, socket}
    end
  end

  @impl true
  def handle_async("delete_media"<>_, {:ok, media}, socket) do
    :ok = Ash.destroy(media, action: :destroy_media, actor: socket.assigns.current_user)
    count_all = socket.assigns.count_all - 1
    count_videos = if is_video_mime_type(media.post_mime_type), do: socket.assigns.count_videos - 1, else: socket.assigns.count_videos
    count_images = if is_image_mime_type(media.post_mime_type), do: socket.assigns.count_images - 1, else: socket.assigns.count_images

    socket =
      stream_delete_by_dom_id(socket, :medias, "medias-#{media.id}")
      |> assign(count_all: count_all)
      |> assign(count_videos: count_videos)
      |> assign(count_images: count_images)
      |> push_event("actions:updateStatus", %{})

    {:noreply, socket}
  end

  @impl true
  def handle_info({_ref, {:media_upload, {entry, path}}}, socket) do
    %{mime_type: mime_type, file: file, filename: filename, filesize: filesize} = meta_data = upload_entry_information(entry, path)

    client_name_with_extension = extract_filename_without_extension(entry.client_name)

    metas =
      [
        %{meta_key: :attached_file, meta_value: filename},
        %{meta_key: :attachment_filesize, meta_value: "#{filesize}"},
        %{meta_key: :attachment_metadata, meta_value: Jason.encode!(meta_data)},
        %{meta_key: :attachment_image_alt, meta_value: client_name_with_extension},
        %{meta_key: :attachment_image_caption, meta_value: client_name_with_extension},
      ]

    attrs = %{
      post_title: client_name_with_extension,
      post_mime_type: mime_type,
      guid: file,
      post_content: "",
      metas: metas
    }

    {:ok, media} = Monorepo.Contents.create_media(attrs, actor: socket.assigns.current_user)
    media = media |> Ash.load!([:post_meta])

    count_all = socket.assigns.count_all + 1
    count_videos = if is_video_mime_type(media.post_mime_type), do: socket.assigns.count_videos + 1, else: socket.assigns.count_videos
    count_images = if is_image_mime_type(media.post_mime_type), do: socket.assigns.count_images + 1, else: socket.assigns.count_images

    socket =
      socket
      |> stream_delete_by_dom_id(:medias, "medias-#{entry.uuid}")
      |> stream_insert(:medias, media, at: 0)
      |> assign(count_all: count_all)
      |> assign(count_videos: count_videos)
      |> assign(count_images: count_images)

    File.rm(path)
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}


  defp get_list_by_params(socket, stream_force_reset \\ false) do
    %{page: page, per_page: per_page, q: q, media_type: media_type, order_by: order_by, current_user: current_user} = socket.assigns

    page = is_integer(page) && page || String.to_integer(page)
    per_page = is_integer(per_page) && per_page || String.to_integer(per_page)

    limit = per_page
    offset = (page - 1) * per_page

    opts = [
      actor: current_user,
      page: [limit: limit, offset: offset, count: true]
    ]

    data =
      if q == "" do
        @model
      else
        @model
        |> Ash.Query.filter(expr(contains(post_title, ^q)))
        |> Ash.Query.filter(post_type == :attachment)
      end

    count_images = Ash.Query.filter(data, expr(contains(post_mime_type, ^"image"))) |> Ash.count!([actor: current_user])
    count_videos = Ash.Query.filter(data, expr(contains(post_mime_type, ^"video"))) |> Ash.count!([actor: current_user])
    count_all =  Ash.count!(data, [actor: current_user])

    data =
      case order_by do
        "-"<>field ->
          sort = Keyword.put([], String.to_atom(field), :desc)
          Ash.Query.sort(data, sort)
        field ->
          sort = Keyword.put([], String.to_atom(field), :asc)
          Ash.Query.sort(data, sort)
      end

    data =
      case media_type do
        "image" -> Ash.Query.filter(data, expr(contains(post_mime_type, ^"image")))
        "video" -> Ash.Query.filter(data, expr(contains(post_mime_type, ^"video")))
        "" -> data
      end

    data =
      data
      |> Ash.read!(opts)
      |> Ash.load!([:post_meta])

    socket =
      if data.count > 0 do
        stream(socket, :medias, data.results, reset: stream_force_reset)
      else
        stream(socket, :medias, [], reset: true)
      end

    socket =
      socket
      |> assign(:params, %{page: page, per_page: per_page, q: q, media_type: media_type, order_by: order_by})
      |> assign(:count_all, count_all)
      |> assign(:data_count, data.count)
      |> assign(:count_images, count_images)
      |> assign(:count_videos, count_videos)
      |> assign(:end_of_timeline?, data.count < per_page)
      |> push_event("actions:updateStatus", %{})

    socket
  end

  defp upload_error_message(client_name, :too_large), do: "\"#{client_name}\" exceeds size limit. Choose smaller file."
  defp upload_error_message(client_name, :not_accepted), do: "\"#{client_name}\" is not an accepted file type. Try another format."
  defp upload_error_message(client_name, :too_many_files), do: "Too many files with \"#{client_name}\". Reduce and retry."

  defp is_uploading?(upload_config) do
    length(upload_config.entries) > 0 && Enum.any?(upload_config.entries, &(&1.valid?))
  end

  defp live_url(query_params) when is_map(query_params) do
    ~p"/admin/media?#{query_params}"
  end

  defp initial_params(params) do
    page = Map.get(params, "page", "1")
    per_page = Map.get(params, "per_page", @per_page)
    q = Map.get(params, "q", "")
    media_type = Map.get(params, "media_type", "")
    order_by = Map.get(params, "order_by", "-inserted_at")
    %{
      page: page,
      per_page: per_page,
      q: q,
      media_type: media_type,
      order_by: order_by
    }
  end
end
