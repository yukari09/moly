defmodule Monorepo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MonorepoWeb.Telemetry,
      Monorepo.Repo,
      {DNSCluster, query: Application.get_env(:monorepo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Monorepo.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Monorepo.Finch},
      # Start a worker by calling: Monorepo.Worker.start_link(arg)
      # {Monorepo.Worker, arg},
      # Start to serve requests, typically the last entry
      MonorepoWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :monorepo]},
      {Cachex, [:cache]},
      {
        FLAME.Pool,
        name: Monorepo.SamplePool,
        min: 0,
        max: 32,
        max_concurrency: 8,
        idle_shutdown_after: 120_000,
        log: :debug
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Monorepo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MonorepoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
