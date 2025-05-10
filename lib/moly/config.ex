defmodule Moly.Config do
  use GenServer

  # dynamically set or get config

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(initial_config) do
    {:ok, initial_config}
  end

  def set(app, key, value) do
    GenServer.cast(__MODULE__, {:set, app, key, value})
  end

  def get(app, key) do
    GenServer.call(__MODULE__, {:get, app, key})
  end

  def handle_cast({:set, app, key, value}, _state) do
    {:noreply, Application.put_env(app, key, value)}
  end

  def handle_call({:get, app, key}, _from, state) do
    {:reply, Application.get_env(app, key), state}
  end
end
