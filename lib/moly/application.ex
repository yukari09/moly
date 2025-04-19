defmodule Moly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MolyWeb.Telemetry,
      Moly.Repo,
      {DNSCluster, query: Application.get_env(:moly, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:moly, Oban)},
      {Phoenix.PubSub, name: Moly.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Moly.Finch},
      # Start a worker by calling: Moly.Worker.start_link(arg)
      # {Moly.Worker, arg},
      # Start to serve requests, typically the last entry
      MolyWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :moly]},
      {Cachex, [:cache]},
      {Moly.Cluster, []},
      {
        FLAME.Pool,
        name: Moly.SamplePool,
        min: 0,
        max: 32,
        max_concurrency: 8,
        idle_shutdown_after: 120_000,
        log: :debug
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Moly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MolyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
