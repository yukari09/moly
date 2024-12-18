defmodule Monorepo.Helper do
  def upload_image_by_url(image_url) do
    Enum.reduce_while(1..5, nil, fn _, _ ->
      {bucket, _, _, upload_bucket_path, domain_url} = s3_env(:image_dir)

      try do
        {:ok, %{status: 200, body: body}} =
          Finch.build("GET", image_url) |> Finch.request(Monorepo.Finch)

        %{status_code: 200} =
          ExAws.S3.put_object(bucket, upload_bucket_path, body) |> ExAws.request!()

        {:halt, domain_url}
      rescue
        _ -> {:cont, nil}
      end
    end)
  end

  def put_object_from_generated_url(url, body_or_path) do
    {bucket, _} = s3_env()

    body =
      if File.exists?(body_or_path) do
        File.read!(body_or_path)
      else
        body_or_path
      end

    upload_bucket_path =
      URI.parse(url)
      |> Map.get(:path)
      |> Path.relative()

    ExAws.S3.put_object(bucket, upload_bucket_path, body)
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  def generate_domain_url(type) when type in [nil, :image_dir, :video_dir] do
    s3_env(type)
    |> elem(4)
  end

  def s3_path_from_url(url) do
    {bucket, _} = s3_env()

    upload_bucket_path =
      URI.parse(url)
      |> Map.get(:path)
      |> Path.relative()

    "s3://#{bucket}/#{upload_bucket_path}"
  end

  def resize_s3_image_from_url(url, width, height) do
    new_img =
      s3_path_from_url(url)
      |> Imgproxy.new()
      |> Imgproxy.set_extension("webp")

    o = case [width, height] do
      [nil, nil] -> new_img
      [_, _] ->
        Imgproxy.resize(new_img, width, height, type: "fit")
    end

    to_string(o)
  end

  def generate_random_str(length \\ 12) when is_integer(length) and length > 0 do
    characters =
      Enum.concat([
        Enum.to_list(?a..?z),
        Enum.to_list(?A..?Z),
        [?_, ?-]
      ])

    for _ <- 1..length do
      Enum.random(characters)
    end
    |> List.to_string()
  end

  def get_youtube_id_from_url(url) do
    pattern =
      ~r/(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|v\/)|youtu\.be\/)([\w-]{11})/

    case Regex.run(pattern, url) do
      nil -> nil
      [_, id] -> id
    end
  end

  defp s3_env(type \\ nil) when type in [nil, :image_dir, :video_dir] do
    s3_conf = Application.get_env(:ex_aws, :s3)

    bucket = Keyword.fetch!(s3_conf, :bucket)
    domain = Keyword.fetch!(s3_conf, :domain)

    if type do
      bucket_dir = Keyword.fetch!(s3_conf, type)
      upload_bucket_path = "#{bucket_dir}/#{Ecto.UUID.generate()}"
      domain_url = Path.join("https://#{domain}", upload_bucket_path)
      {bucket, bucket_dir, domain, upload_bucket_path, domain_url}
    else
      {bucket, domain}
    end
  end
end
