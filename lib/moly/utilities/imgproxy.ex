defmodule Moly.Utilities.Imgproxy do
  @moduledoc """
  Generates a signed URL for imgproxy.
  """

  @base_url "http://192.168.6.8:8008"
  @key "31dde3553997eb7bd3ad1ce2700c2f2e32dc15fffcd19969399e65b7c7d47c81"
  @salt "38d48531bc85ac8273a0cb9f057223349141a53954937b97785b9cbf15ee34ee"

  @doc """
  Generates a signed URL for imgproxy.

  ## Parameters
    - key: The hex-encoded HMAC key (binary format)
    - salt: The hex-encoded salt (binary format)
    - path: The imgproxy URL path after the signature

  ## Example
      iex> Imgproxy.sign_url(@key, @salt, "/rs:fill:300:400:0/g:sm/aHR0cDovL2V4YW1w/bGUuY29tL2ltYWdl/cy9jdXJpb3NpdHku/anBn.png")
      "oKfUtW34Dvo2BGQehJFR4Nr0_rIjOtdtzJ3QFsUcXH8"
  """
  def sign_url(key_hex, salt_hex, path) do
    key = Base.decode16!(key_hex, case: :lower)
    salt = Base.decode16!(salt_hex, case: :lower)

    data = salt <> path
    signature = :crypto.mac(:hmac, :sha256, key, data) |> Base.url_encode64(padding: false)

    signature
  end

  @doc """
  Encodes a URL in Base64 URL-safe format.
  """
  def encode_url(url) do
    url
    |> Base.encode64()
    |> String.replace("+", "-")
    |> String.replace("/", "_")
    |> String.replace("=", "")
  end

  @doc """
  Builds a full imgproxy URL with signature for an S3 path.
  """
  def build_url(s3_path) do
    encoded_path = encode_url(s3_path)
    imgproxy_path = "/rs:fill:300:400:0/g:sm/#{encoded_path}"
    signature = sign_url(@key, @salt, imgproxy_path)
    "#{@base_url}/#{signature}#{imgproxy_path}"
  end
end
