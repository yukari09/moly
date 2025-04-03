defmodule Moly.Helper do
  @moduledoc """
  Helper functions.
  """

  require Logger

  @doc """
  Uploads a file to S3
  """
  def put_object_from_url(url, bucket_prefix \\ "") do
    body =
      Enum.reduce_while(1..5, nil, fn _, _ ->
        case Finch.build("GET", url) |> Finch.request(Moly.Finch) do
          {:ok, %{status: 200, body: body}} -> {:halt, body}
          _ -> {:cont, nil}
        end
      end)

    ext = Path.extname(url)
    filename = Ash.UUID.generate() <> ext
    put_object(filename, body, bucket_prefix)
  end

  # def put_object(%Phoenix.LiveView.UploadEntry{} = upload_entry, body_or_path, bucket_prefix \\ "") do
  #   entry_filename(upload_entry)
  #   |> put_object(body_or_path, bucket_prefix)
  # end

  def put_object(filename_or_entry, body_or_path, bucket_prefix \\ "")
      when is_map(filename_or_entry) or is_binary(filename_or_entry) do
    filename =
      case filename_or_entry do
        %Phoenix.LiveView.UploadEntry{} -> entry_filename(filename_or_entry)
        filename_or_entry -> filename_or_entry
      end

    filename = Path.join(bucket_prefix, filename)

    bucket = load_s3_config(:bucket)

    body =
      if File.exists?(body_or_path) do
        File.read!(body_or_path)
      else
        body_or_path
      end

    Logger.info("Uploading #{filename} to S3, file size: #{byte_size(body)}")

    Enum.reduce_while(1..5, nil, fn _, _ ->
      ExAws.S3.put_object(bucket, filename, body)
      |> ExAws.request()
      |> case do
        {:ok, _} -> {:halt, filename}
        _ -> {:cont, nil}
      end
    end)
  end

  def remove_object(filename) do
    bucket = load_s3_config(:bucket)

    Enum.reduce_while(1..5, nil, fn _, _ ->
      ExAws.S3.delete_object(bucket, filename)
      |> ExAws.request()
      |> case do
        {:ok, _} -> {:halt, filename}
        _ -> {:cont, nil}
      end
    end)
  end

  def presign_upload(%Phoenix.LiveView.UploadEntry{} = upload_entry, socket) do
    config = load_s3_config()
    bucket = Map.get(config, :bucket)
    key = entry_filename(upload_entry)

    {:ok, url} =
      ExAws.S3.presigned_url(config, :put, bucket, key,
        expires_in: 7200,
        query_params: [{"Content-Type", upload_entry.client_type}]
      )

    {:ok, %{uploader: "S3", key: key, url: url}, socket}
  end

  # def image_resize(filename, width \\ nil, height \\ nil) do
  #   new_img =
  #     Imgproxy.new("s3://#{s3_path(filename)}")
  #     |> Imgproxy.set_extension("webp")

  #   o =
  #     case [width, height] do
  #       [nil, nil] ->
  #         new_img

  #       [_, _] ->
  #         Imgproxy.resize(new_img, width, height, type: "fill")
  #     end

  #   to_string(o)
  # end

  # defp s3_path(filename), do: load_s3_config(:bucket) |> Path.join(filename)

  @doc """
    [imagor](https://github.com/cshum/imagor)
  """
  def image_resize(filename, width \\ nil, height \\ nil) do
    with {:ok, addr} = Application.fetch_env(:moly, :imagor_endpoint),
         {:ok, secret} = Application.fetch_env(:moly, :imagor_secret) do
      opts = ["smart", "filters:format(webp)", filename]

      path =
        if width && height do
          ["#{width}x#{height}" | opts]
        else
          opts
        end

      path = Enum.join(path, "/")
      hashstr = hash(path, secret)
      "#{addr}/#{hashstr}"
    end
  end

  defp hash(path, secret) do
    hash =
      :crypto.mac(:hmac, :sha, secret, path)
      |> Base.encode64()
      |> String.replace("+", "-")
      |> String.replace("/", "_")

    "#{hash}/#{path}"
  end

  # have some erros
  def s3_file_with_domain(filename),
    do: "#{load_s3_config(:domain_scheme)}://#{load_s3_config(:domain)}/#{filename}"

  def upload_entry_information(
        %Phoenix.LiveView.UploadEntry{client_type: mime_type} = entry,
        file_path
      ) do
    case ffprobe(file_path) do
      {:ok, data} ->
        video_stream = Enum.find(data["streams"], &(&1["codec_type"] == "video"))
        width = video_stream["width"]
        height = video_stream["height"]
        duration = format_duration(video_stream["duration"])

        case put_object(entry, file_path) do
          nil ->
            nil

          filename ->
            entry_information(mime_type, width, height, duration, filename)
            |> Map.put(:filesize, entry.client_size)
            |> Map.put(:filename, filename)
            |> Map.put(:mime_type, mime_type)
            |> Map.put(:width, width)
            |> Map.put(:height, height)
            |> Map.put(:type, Path.extname(entry.client_name))
        end

      _ ->
        :error
    end
  end

  def entry_information("image" <> _, width, height, _, filename) do
    original_ratio = width / height

    sizes =
      [
        full: width,
        thumbnail: 180,
        medium: 360,
        large: 1024,
        xlarge: 1280,
        xxlarge: 2048,
        huge: 4096
      ]
      |> Enum.filter(fn {_, width_size} -> width >= width_size end)
      |> Enum.reduce(%{}, fn {key, width_size}, acc ->
        height_size = round(width_size / original_ratio)

        Map.put(acc, key, %{
          file: image_resize(filename, width_size, height_size),
          width: width_size,
          height: height_size,
          mime_type: "image/webp"
        })
      end)

    %{file: image_resize(filename), sizes: sizes}
  end

  def entry_information("video" <> _, _, _, duration, filename) do
    %{file: s3_file_with_domain(filename), duration: duration}
  end

  def ffprobe(media_path) do
    FLAME.call(Moly.SamplePool, fn ->
      case System.cmd(
             "ffprobe",
             ~w(-v quiet -print_format json -show_format -show_streams -i #{media_path})
           ) do
        {output, 0} -> JSON.decode(output)
        _ -> {:error, nil}
      end
    end)
  end

  defp entry_filename(%Phoenix.LiveView.UploadEntry{} = upload_entry) do
    [upload_entry.client_type, upload_entry.uuid <> Path.extname(upload_entry.client_name)]
    |> Path.join()
  end

  defp load_s3_config(key \\ nil) do
    config = ExAws.Config.new(:s3)
    (key && Map.get(config, key)) || config
  end

  @doc """
  Generate random id
  """
  def generate_random_id(length \\ 8) do
    charset = ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    for _ <- 1..length, into: "", do: <<Enum.random(charset)>>
  end

  @doc """
  Generate random string
  """
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

  def get_youtube_id(url) do
    pattern =
      ~r/(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|v\/)|youtu\.be\/)([\w-]{11})/

    case Regex.run(pattern, url) do
      nil -> nil
      [_, id] -> id
    end
  end

  def string2slug(str) do
    str
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/[^\w-]/, "")
  end

  def extract_filename_without_extension(filename) do
    filename
    |> Path.basename()
    |> String.split(".")
    |> Enum.slice(0..-2//1)
    |> Enum.join(".")
  end

  def format_duration(duration) when is_binary(duration) do
    case String.contains?(duration, ".") do
      true ->
        duration
        |> String.to_float()
        |> Float.floor()
        |> trunc()

      false ->
        String.to_integer(duration)
    end
  end

  def format_duration(_), do: 0

  def is_video_mime_type(mime_type), do: String.contains?(mime_type, "video")
  def is_image_mime_type(mime_type), do: String.contains?(mime_type, "image")

  def convert_map(map) do
    map
    |> Enum.map(fn
      {k, v} when is_atom(k) -> {k, v}
      {k, v} -> {String.to_atom(k), v}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Format number to human readable
  """
  def format_number(value) when value >= 1_000_000 do
    "#{div(value, 1000)}M"
  end

  def format_number(value) when value >= 1000 do
    "#{div(value, 1000)}K"
  end

  def format_number(value), do: Integer.to_string(value)

  @doc """
  Format time ago
  """
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

  def get_in_from_keys(map_or_list, keys) do
    Enum.reduce_while(keys, map_or_list, fn key, acc ->
      value =
        cond do
          is_map(acc) -> Map.get(acc, key, nil)
          is_list(acc) && is_integer(key) -> Enum.at(acc, key)
          is_tuple(acc) && is_integer(key) -> elem(acc, key)
          true -> nil
        end

      if is_nil(value), do: {:halt, nil}, else: {:cont, value}
    end)
  end

  def is_url?(str) do
    regex =
      ~r/^(https?|ftp):\/\/([a-z0-9-]+\.)+[a-z]{2,6}(:\d+)?(\/[^\s]*)?(\?[^\s]*)?(#[^\s]*)?$/i

    Regex.match?(regex, str)
  end

  def bits_to_readable(bits) when is_binary(bits), do: bits_to_readable(String.to_integer(bits))

  def bits_to_readable(bits) when is_integer(bits) do
    cond do
      bits >= 1_000_000_000 -> "#{div(bits, 1_000_000_000)} GB"
      bits >= 1_000_000 -> "#{div(bits, 1_000_000)} MB"
      bits >= 1_000 -> "#{div(bits, 1_000)} KB"
      true -> "#{bits} B"
    end
  end

  def bits_to_readable(nil), do: 0

  def format_to_int(string, decimal_places) do
    case Float.parse(string) do
      {float_value, _} -> :erlang.float_to_binary(float_value, decimals: decimal_places)
      _ -> 0
    end
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
