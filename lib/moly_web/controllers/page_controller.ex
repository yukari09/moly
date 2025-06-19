defmodule MolyWeb.PageController do
  use MolyWeb, :controller

  def upload_file(conn, %{"image" => file}) do
    result =
      Moly.Helper.plug_upload_to_phoenix_liveview_upload_entry(file)
      |> Moly.Helper.create_media_post_by_entry(file.path, conn.assigns.current_user)
      |> case do
        :error -> %{success: 0}
        media_attrs ->
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

  def download_file(conn, %{"url" => url, "filename" => filename}) do
    case Finch.build(:get, url) |> Finch.request(Moly.Finch) do
      {:ok, %Finch.Response{status: 200, body: body, headers: headers}} ->
        content_type =
          headers
          |> Enum.find(fn {key, _} -> String.downcase(key) == "content-type" end)
          |> case do
            {_, type} -> type
            nil -> "image/webp"
          end

        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
        |> send_resp(200, body)

      _ ->
        conn
        |> put_status(:not_found)
        |> text("File not found")
    end
  end

  def about(conn, _params) do
    render(conn, "about.html", page_title: "About Us")
  end
  def contact(conn, _params) do
    render(conn, "contact.html", page_title: "Contact Us")
  end
  def privacy_policy(conn, _params) do
    render(conn, "privacy_policy.html", page_title: "Privacy Policy")
  end
  def terms_of_service(conn, _params) do
    render(conn, "terms_of_service.html", page_title: "Terms of Service")
  end



end
