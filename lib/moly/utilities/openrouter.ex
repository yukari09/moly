defmodule Moly.Utilities.OpenRouter do
  @moduledoc """
  OpenRouter API client using Finch library
  """

  require Logger

  @base_url "https://openrouter.ai/api/v1"

  defp get_api_key do
    Application.get_env(:moly, :openrouter_api_key)
  end

  @doc """
  Make a chat completion request to OpenRouter
  """
  @spec chat_completion(list(), keyword()) :: {:ok, map()} | {:error, any()}
  def chat_completion(messages, opts \\ []) do
    chat_completion(get_api_key(), messages, opts)
  end

  @spec chat_completion(String.t(), list(), keyword()) :: {:ok, map()} | {:error, any()}
  def chat_completion(api_key, messages, opts) when is_binary(api_key) do
    model = Keyword.get(opts, :model, "openai/gpt-3.5-turbo")
    max_tokens = Keyword.get(opts, :max_tokens, 10000)
    temperature = Keyword.get(opts, :temperature, 0.7)

    body = %{
      model: model,
      messages: messages,
      max_tokens: max_tokens,
      temperature: temperature
    }

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    json_body = JSON.encode!(body)

    case Finch.build(:post, "#{@base_url}/chat/completions", headers, json_body)
         |> Finch.request(Moly.Finch, []) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        case JSON.decode(response_body) do
          {:ok, parsed} -> {:ok, parsed}
          {:error, error} -> {:error, {:json_decode_error, error}}
        end
      {:ok, %Finch.Response{status: status, body: body}} ->
        Logger.error("HTTP Error: #{status}, #{body}")
        {:error, {status, body}}
      {:error, error} ->
        Logger.error("Request Error: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Get available models from OpenRouter
  """
  @spec get_models() :: {:ok, list()} | {:error, any()}
  def get_models do
    get_models(get_api_key())
  end

  @spec get_models(String.t()) :: {:ok, list()} | {:error, any()}
  def get_models(api_key) when is_binary(api_key) do
    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    case Finch.build(:get, "#{@base_url}/models", headers)
         |> Finch.request(Moly.Finch) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        case JSON.decode(response_body) do
          {:ok, %{"data" => models}} -> {:ok, models}
          {:ok, parsed} -> {:ok, parsed}
          {:error, error} -> {:error, {:json_decode_error, error}}
        end
      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, {status, body}}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Get account balance and usage from OpenRouter
  """
  @spec get_balance() :: {:ok, map()} | {:error, any()}
  def get_balance do
    get_balance(get_api_key())
  end

  @spec get_balance(String.t()) :: {:ok, map()} | {:error, any()}
  def get_balance(api_key) when is_binary(api_key) do
    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    case Finch.build(:get, "#{@base_url}/auth/key", headers)
         |> Finch.request(Moly.Finch) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        case JSON.decode(response_body) do
          {:ok, parsed} -> {:ok, parsed}
          {:error, error} -> {:error, {:json_decode_error, error}}
        end
      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, {status, body}}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Stream chat completion from OpenRouter
  """
  @spec stream_chat_completion(list(), keyword()) :: {:ok, pid()} | {:error, any()}
  def stream_chat_completion(messages, opts \\ []) do
    stream_chat_completion(get_api_key(), messages, opts)
  end

  @spec stream_chat_completion(String.t(), list(), keyword()) :: {:ok, pid()} | {:error, any()}
  def stream_chat_completion(api_key, messages, opts) when is_binary(api_key) do
    model = Keyword.get(opts, :model, "openai/gpt-3.5-turbo")
    max_tokens = Keyword.get(opts, :max_tokens, 1000)
    temperature = Keyword.get(opts, :temperature, 0.7)
    callback = Keyword.get(opts, :callback, fn _chunk -> :ok end)

    body = %{
      model: model,
      messages: messages,
      max_tokens: max_tokens,
      temperature: temperature,
      stream: true
    }

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"},
      {"HTTP-Referer", "https://your-app.com"},
      {"X-Title", "Moly App"}
    ]

    json_body = JSON.encode!(body)

    # Start streaming request
    case Finch.build(:post, "#{@base_url}/chat/completions", headers, json_body)
         |> Finch.stream(Moly.Finch, [], fn
           {:status, status}, acc ->
             Map.put(acc, :status, status)
           {:headers, headers}, acc ->
             Map.put(acc, :headers, headers)
           {:data, data}, acc ->
             parse_and_handle_sse_chunk(data, callback)
             acc
         end, %{}) do
      {:ok, _acc} -> {:ok, :streaming_complete}
      {:error, error} -> {:error, error}
    end
  end

  # Private function to parse and handle Server-Sent Events chunks
  defp parse_and_handle_sse_chunk(data, callback) do
    data
    |> String.split("\n")
    |> Enum.each(fn line ->
      case String.trim(line) do
        "data: [DONE]" ->
          callback.({:done})
        "data: " <> json_str ->
          case JSON.decode(json_str) do
            {:ok, parsed} -> callback.({:data, parsed})
            {:error, _} -> :ok
          end
        _ -> :ok
      end
    end)
  end

  @doc """
  Helper function to create a simple message format
  """
  @spec create_message(String.t(), String.t()) :: map()
  def create_message(role, content) when role in ["system", "user", "assistant"] do
    %{role: role, content: content}
  end

  @doc """
  Helper function to create a conversation with system prompt
  """
  @spec create_conversation(String.t(), String.t()) :: list()
  def create_conversation(system_prompt, user_message) do
    [
      create_message("system", system_prompt),
      create_message("user", user_message)
    ]
  end



end
