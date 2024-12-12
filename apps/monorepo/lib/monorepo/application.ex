defmodule Monorepo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Monorepo.Repo,
      {DNSCluster, query: Application.get_env(:monorepo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Monorepo.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Monorepo.Finch}
      # Start a worker by calling: Monorepo.Worker.start_link(arg)
      # {Monorepo.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Monorepo.Supervisor)
  end
end
