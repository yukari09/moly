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

  def format_number_readable(number) when is_integer(number) do
    format_number_readable(Integer.to_string(number))
  end

  def format_number_readable(number) when is_binary(number) and number != "" do
    {value, ""} = Integer.parse(number)
    format_value(value)
  end

  def format_number_readable(_), do: ""

  defp format_value(value) when value >= 1_000_000 do
    "#{div(value, 1000)}m"
  end

  defp format_value(value) when value >= 1000 do
    "#{div(value, 1000)}k"
  end

  defp format_value(value), do: Integer.to_string(value)

  def ago(nil), do: ""

  def ago(timestamp) when is_float(timestamp) do
    {:ok, ago} =
      timestamp
      |> trunc()
      |> Timex.from_unix()
      |> Timex.Format.DateTime.Formatters.Relative.format("{relative}")

    ago
  end

  def ago(year, month, day, hour, minute \\ 0, second \\ 0)
      when is_integer(year) and is_integer(month) and is_integer(hour) do
    {:ok, ago} =
      NaiveDateTime.new!(year, month, day, hour, minute, second)
      |> Timex.Format.DateTime.Formatters.Relative.format("{relative}")

    ago
  end

  def timestamp2datetime(timestamp) when is_float(timestamp) do
    trunc(timestamp)
    |> Timex.from_unix()
    |> Timex.format!("{h24}:{0m}  {D},{Mshort} {YYYY}")
  end

  def timestamp2datetime(_), do: ""

  def get_in(map, keys) do
    Enum.reduce_while(keys, map, fn key, map ->
      case Map.get(map, key) do
        nil -> {:halt, nil}
        value -> {:cont, value}
      end
    end)
  end

  def generate_random_id(length \\ 8) do
    charset = ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    for _ <- 1..length, into: "", do: <<Enum.random(charset)>>
  end


  def pagination_meta(total, page_size, page, show_item)
       when is_integer(total) and is_integer(page_size) and is_integer(page) and
              is_integer(show_item) do
    current_page = page
    total_pages = ceil(total / page_size)
    mid = floor(show_item / 2)
    start_page = current_page - mid
    start_page = (start_page <= 0 && 1) || start_page

    end_page = start_page + show_item - 1
    end_page = (end_page > total_pages && total_pages) || end_page

    start_row = (page - 1) * page_size + 1
    end_row = start_row + page_size - 1
    end_row = (total < end_row && total) || end_row

    %{
      is_first: current_page === 1,
      is_last: current_page === total_pages,
      prev: (current_page > 1 && current_page - 1) || nil,
      next: (total_pages > current_page && current_page + 1) || nil,
      page_range: start_page..end_page,
      current_page: current_page,
      ellipsis: total_pages - end_page > 2,
      page_size: page_size,
      start_row: start_row,
      end_row: end_row,
      total: total,
      total_pages: total_pages
    }
  end
end
