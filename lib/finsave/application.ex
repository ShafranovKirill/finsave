defmodule Finsave.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FinsaveWeb.Telemetry,
      Finsave.Repo,
      {DNSCluster, query: Application.get_env(:finsave, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Finsave.PubSub},
      # Start a worker by calling: Finsave.Worker.start_link(arg)
      # {Finsave.Worker, arg},
      # Start to serve requests, typically the last entry
      FinsaveWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Finsave.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FinsaveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
