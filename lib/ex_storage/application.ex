defmodule ExStorage.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExStorageWeb.Telemetry,
      ExStorage.Repo,
      {DNSCluster, query: Application.get_env(:ex_storage, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ExStorage.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ExStorage.Finch},
      # Start a worker by calling: ExStorage.Worker.start_link(arg)
      # {ExStorage.Worker, arg},
      # Start to serve requests, typically the last entry
      ExStorageWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExStorage.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExStorageWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
