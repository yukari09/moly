defmodule Moly.Utilities do
  @cache_name :cache
  def cache_del(key), do: Cachex.del(@cache_name, key)
  def cache_get!(key), do: Cachex.get!(@cache_name, key)
  def cache_inc(key, amount \\ 1, opts \\ []), do: Cachex.incr!(@cache_name, key, amount, opts)
  def cache_ttl(key), do: Cachex.ttl(@cache_name, key) |> elem(1)
  def cache_exists?(key), do: Cachex.exists?(@cache_name, key) |> elem(1)
  @spec cache_put(any(), any()) :: {:error, boolean()} | {:ok, boolean()}
  def cache_put(key, value, expire \\ 0), do: Cachex.put(@cache_name, key, value, expire: expire)
  def cache_get_or_put(key, get_cache_function \\ nil, expire \\ 0) do
    case cache_get!(key) do
      nil ->
        if is_function(get_cache_function) do
          value = apply(get_cache_function, [])
          cache_put(key, value, expire)
          value
        else
          nil
        end
      fetched_value -> fetched_value
    end
  end
  @doc """
  This function is used to hash a string to a short id.
  It replaces all [ and ] with -
  Example:
  "Hello [World]" -> "Hello-World"
  "Hello [World] [Test]" -> "Hello-World-Test"
  "Hello [World] [Test] [Test2]" -> "Hello-World-Test-Test2"
  "Hello [World] [Test] [Test2] [Test3]" -> "Hello-World-Test-Test2-Test3"
  """
  def hash_str_id(str), do: Regex.replace(~r/\[|\]/, str, "-")

  @doc """
  tag_strategy_name -> Tag Strategy Value
  """
  def key_to_name(key) do
    String.replace(key, "_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

end
