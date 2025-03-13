defmodule Moly.Utilities do
  def cache_get_or_put(key, get_cache_function \\ nil, expire \\ 0) do
    Cachex.get!(:cache, key)
    |> case do
      nil ->
        if is_function(get_cache_function) do
          value = get_cache_function.()
          Cachex.put(:cache, key, value, expire: expire)
          value
        else
          nil
        end

      fetched_value ->
        fetched_value
    end
  end
end
