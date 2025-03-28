defmodule MolyWeb.Affinew.SubmitLive do
  use MolyWeb, :live_view

  require Ash.Query

  import MolyWeb.TailwindUI
  import MolyWeb.Affinew.Query, only: [industries: 0, countries: 0]

  alias MolyWeb.Affinew.Links

  def mount(params, _session, socket) do
    {:ok, resource_socket(socket, params), layout: {MolyWeb.Layouts, :affinew}}
  end

  def handle_params(_, _uri, socket) do
    {:noreply, socket}
  end

  def handle_event("validate", _, socket) do
    socket = push_event(socket, "validateForm", %{})
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :media, ref)}
  end

  def handle_event("save", %{"form" => params}, socket) do
    post_meta = Map.get(params, "post_meta")

    new_post_meta =
      Enum.reduce(post_meta, [], fn
        {k, %{"0" => v0, "1" => v1, "2" => v2} = commission}, a1 ->
          reduce_map = [v0, v1, v2]
          reduce_map =
            if Map.has_key?(commission, "3") do
              v3 = Map.get(commission, "3")
              [v3 | reduce_map]
            else
              reduce_map
            end
          Enum.reduce(reduce_map, a1, fn %{
            "meta_key" => meta_key,
            "meta_value" => meta_value
            }, a2 ->
              if meta_value not in [nil, ""] do
                [%{"meta_key" => String.to_atom("#{meta_key}_#{k}"), "meta_value" => meta_value} | a2]
              else
                a2
              end
          end)

        {_, v}, a1 ->
          [v | a1]
      end)

    new_post_meta =
      post_media(socket, new_post_meta)
      |> Enum.with_index()
      |> Enum.reduce(%{}, &Map.put(&2, "#{elem(&1, 1)}", elem(&1, 0)))

    params = Map.put(params, "post_meta", new_post_meta)
    params = Map.put(params, "post_status", "pending")
    params = Map.put(params, "post_name", Moly.Helper.generate_random_str())

    post_excerpt =
      Floki.parse_document!(params["post_content"]) |> Floki.text() |> String.slice(0..255)

    params = Map.put(params, "post_excerpt", post_excerpt)
    params = Map.put(params, "post_date", DateTime.utc_now())

    post_tags =
      Map.get(params, "post_tags")
      |> String.split(",")
      |> Enum.map(fn name ->
        name = String.trim(name)
        slug = Moly.Helper.string2slug(name)

        %{
          "name" => name,
          "slug" => slug,
          "term_taxonomy" => [%{"taxonomy" => "affiliate_tag"}]
        }
      end)

    params = Map.put(params, "tags", post_tags)

    params = Map.put(params, "post_type", :affiliate)

    socket =
      case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
        {:ok, post} ->
          socket
          |> put_flash(:info, "Saved post for #{post.post_title}!")
          |> push_navigate(to: Links.view(post.post_name))

        {:error, form} ->
          flash_msg =
            Enum.map(form.errors, fn {field, {m, _}} -> "#{field}: #{m}" end)
            |> List.first()
            |> case do
              nil -> "Oops, some thing wrong."
              error_msg -> error_msg
            end

          socket
          # |> assign(form: form)
          |> put_flash(:error, flash_msg)
      end

    {:noreply, socket}
  end

  defp resource_socket(socket, params) do
    post_name = Map.get(params, "post_name")
    is_active_user = Moly.Utilities.Account.is_active_user(socket.assigns.current_user)

    post =
      if is_nil(post_name) do
        %Moly.Contents.Post{}
      else
        Ash.Query.filter(
          Moly.Contents.Post,
          post_name == ^post_name and author_id == ^socket.assigns.current_user.id
        )
        |> Ash.Query.load([:affiliate_categories, :post_tags, post_meta: :children])
        |> Ash.read_first!(actor: socket.assigns.current_user)
      end

    if is_active_user && post do
      form =
        if post_name do
          AshPhoenix.Form.for_update(post, :update_post,
            forms: [auto?: true],
            actor: set_current_user_as_owner(socket.assigns.current_user)
          )
        else
          AshPhoenix.Form.for_create(Moly.Contents.Post, :create_post,
            forms: [auto?: true],
            actor: set_current_user_as_owner(socket.assigns.current_user)
          )
        end
        |> to_form()


      commissions = post_meta_commssion(post)

      assign(socket,
        countries: countries(),
        industries: industries(),
        form: form,
        post: post,
        commissions: commissions
      )
      |> allow_upload(:media,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 4_000_000
      )
      |> assign(:is_active_user, is_active_user)
    else
      push_navigate(socket, to: ~p"/user/verify-email")
    end
  end

  defp set_current_user_as_owner(current_user),
    do: %{current_user | roles: [:owner | current_user.roles]}

  defp post_media(socket, new_post_meta) do
    actor = set_current_user_as_owner(socket.assigns.current_user)

    uploaded_files =
      consume_uploaded_entries(socket, :media, fn %{path: path}, entry ->
        media_info = Moly.Helper.upload_entry_information(entry, path)

        case media_info do
          :error ->
            {:error, "Error uploading file \"#{entry.client_name}\""}

          %{mime_type: mime_type, file: file, filename: filename, filesize: filesize} = meta_data ->
            client_name_with_extension =
              Moly.Helper.extract_filename_without_extension(entry.client_name)

            metas =
              [
                %{meta_key: :attached_file, meta_value: filename},
                %{meta_key: :attachment_filesize, meta_value: "#{filesize}"},
                %{meta_key: :attachment_metadata, meta_value: JSON.encode!(meta_data)},
                %{meta_key: :attachment_image_alt, meta_value: client_name_with_extension},
                %{meta_key: :attachment_image_caption, meta_value: client_name_with_extension}
              ]

            attrs = %{
              post_title: client_name_with_extension,
              post_mime_type: mime_type,
              guid: file,
              post_content: "",
              metas: metas
            }

            Moly.Contents.create_media(attrs, actor: actor)
        end
      end)

    meida_ids = Enum.map(uploaded_files, & &1.id) |> Enum.join(",")
    feture_id = List.first(uploaded_files) |> Map.get(:id)

    [
      %{
        "meta_key" => "attachment_affiliate_media",
        "meta_value" => meida_ids
      },
      %{
        "meta_key" => "attachment_affiliate_media_feature",
        "meta_value" => feture_id
      }
    ] ++ new_post_meta
  end

  defp post_meta_commssion(%Moly.Contents.Post{} = post) do
    post_meta_value(post, :commssion)
    |> case do
      nil ->
        [add_commssion()]

      commssion_items ->
        commssion_items
        |> Enum.group_by(fn %{meta_key: meta_key} ->
          to_string(meta_key) |> String.split("_") |> tl()
        end)
    end
  end

  defp add_commssion() do
    [
      %Moly.Contents.PostMeta{meta_key: :commission_type, meta_value: "bounty"},
      %Moly.Contents.PostMeta{meta_key: :commission_amount, meta_value: nil},
      %Moly.Contents.PostMeta{meta_key: :commission_unit, meta_value: "%"},
      %Moly.Contents.PostMeta{meta_key: :commission_notes, meta_value: nil}
    ]
  end

  defp field_subfix(field_name, i, j), do: "[#{13 + i}][#{j}][#{field_name}]"

  defp post_meta_value(%Moly.Contents.Post{post_meta: post_meta}, meta_key)
       when is_list(post_meta) and is_atom(meta_key) do
    filter_result =
      Enum.filter(post_meta, fn %{meta_key: meta_key2} ->
        meta_key1 = to_string(meta_key)
        meta_key2 = to_string(meta_key2)
        String.contains?(meta_key2, meta_key1)
      end)

    if Enum.count(filter_result) === 0 do
      Moly.Helper.get_in_from_keys(filter_result, [0, :meta_value])
    else
      filter_result
    end
  end

  defp post_meta_value(_, _), do: nil

  defp commission_value(commission, meta_key) do
    Enum.filter(commission, &(&1.meta_key == meta_key))
    |> List.first()
    |> case do
      nil -> nil
      %{meta_value: meta_value} -> meta_value
    end
  end
end
