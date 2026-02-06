defmodule Shepherd.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ShepherdWeb.Telemetry,
      Shepherd.Repo,
      {DNSCluster, query: Application.get_env(:shepherd, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Shepherd.PubSub},
      Shepherd.Presence,
      # Start to serve requests, typically the last entry
      ShepherdWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Shepherd.Supervisor]
    result = Supervisor.start_link(children, opts)

    # Attach metrics handlers after supervisor starts
    Shepherd.Metrics.Pipeline.attach_handlers()

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShepherdWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
