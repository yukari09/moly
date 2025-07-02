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
