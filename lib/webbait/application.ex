defmodule WebBait.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    config_common_dtls_key_cert()

    children = [
      # Start the Ecto repository
      WebBait.Repo,
      # Start the Telemetry supervisor
      WebBaitWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: WebBait.PubSub},
      # Start the Endpoint (http/https)
      WebBaitWeb.Endpoint,
      # Start a worker by calling: WebBait.Worker.start_link(arg)
      # {WebBait.Worker, arg}
      {Registry, keys: :unique, name: WebBait.Room.Registry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebBait.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WebBaitWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp config_common_dtls_key_cert() do
    {:ok, pid} = ExDTLS.start_link(client_mode: false, dtls_srtp: true)
    {:ok, pkey} = ExDTLS.get_pkey(pid)
    {:ok, cert} = ExDTLS.get_cert(pid)
    :ok = ExDTLS.stop(pid)
    Application.put_env(:webbait, :dtls_pkey, pkey)
    Application.put_env(:webbait, :dtls_cert, cert)
  end
end
