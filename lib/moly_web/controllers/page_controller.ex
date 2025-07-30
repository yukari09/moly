defmodule MolyWeb.PageController do
  use MolyWeb, :controller

  def upload_file(conn, %{"image" => file}) do
    result =
      Moly.Helper.plug_upload_to_phoenix_liveview_upload_entry(file)
      |> Moly.Helper.create_media_post_by_entry(file.path, conn.assigns.current_user)
      |> case do
        :error -> %{success: 0}
        {:ok, media_attrs, _media_post} ->
          image_infor =
            Enum.find(media_attrs.metas, &(&1.meta_key == :attachment_metadata))
            |> Map.get(:meta_value)
            |> Jason.decode!()
          file = Map.get(image_infor, "file")
          %{
            success: 1,
            file: %{
              url: file,
              additional: image_infor
            }
          }
      end

    json conn, result
  end

  def page(conn, %{"gid" => guid} = params) do
    key = "pages:es:#{guid}"
    if params["preview"] do
      Moly.Utilities.cache_del(key)
    end
    full_guid = ~p"/page/#{guid}"
    [page_content, page_title, page_description] =
      Moly.Utilities.cache_get_or_put(key, fn ->
        page =
          Moly.Contents.PostEs.query_document_by_post_guid(full_guid)
          |> case do
            nil -> nil
            [_, [page | _]] -> page
          end

        [
          Moly.Helper.get_in_from_keys(page, [:source, "post_content"]),
          Moly.Helper.get_in_from_keys(page, [:source, "post_title"]),
          Moly.Helper.get_in_from_keys(page, [:source, "post_excerpt"]),
        ]
      end, :timer.hours(24))

    conn = put_layout(conn, false) |> put_root_layout({MolyWeb.Layouts, :root_page})

    render(conn, :page, [page_title: page_title, page_description: page_description, page_content: page_content])
  end

  def about(conn, _params) do
    render(conn, "about.html")
  end
  def contact(conn, _params) do
    render(conn, "contact.html")
  end
  def privacy_policy(conn, _params) do
    render(conn, "privacy_policy.html")
  end
  def terms_of_service(conn, _params) do
    render(conn, "terms_of_service.html")
  end



end
