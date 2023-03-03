defmodule WebBait.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Membrane.Logger

  @cert_file_path "priv/integrated_turn_cert.pem"

  @impl true
  def start(_type, _args) do
    config_common_dtls_key_cert()
    create_integrated_turn_cert_file()

    store_metrics = Application.fetch_env!(:webbait, :store_metrics)

    children =
      [
        {Membrane.TelemetryMetrics.Reporter, [metrics: Membrane.RTC.Engine.Metrics.metrics(), name: AgentRTC.Reporter]},
        # Start the Ecto repository
        WebBait.Repo,
        # Start the Telemetry supervisor
        WebBaitWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: WebBait.PubSub},
        WebBait.Presence,
        # Start the Endpoint (http/https)
        WebBaitWeb.Endpoint,
        # Start a worker by calling: WebBait.Worker.start_link(arg)
        # {WebBait.Worker, arg}
        {Registry, keys: :unique, name: WebBait.AgentRTC.Registry},
        {DynamicSupervisor, strategy: :one_for_one, name: WebBait.AgentRTC.MonitorSupervisor}
      ] ++
        if store_metrics do
          Application.ensure_all_started(:membrane_rtc_engine_timescaledb)

          scrape_interval = Application.fetch_env!(:webbait, :metrics_scrape_interval)

          [WebBait.Repo, {WebBait.MetricsPersistor, scrape_interval: scrape_interval}]
        else
          []
        end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    delete_cert_file()
    :ok
  end

  defp create_integrated_turn_cert_file() do
    cert_path = Application.fetch_env!(:webbait, :integrated_turn_cert)
    pkey_path = Application.fetch_env!(:webbait, :integrated_turn_pkey)

    if cert_path != nil and pkey_path != nil do
      cert = File.read!(cert_path)
      pkey = File.read!(pkey_path)

      File.touch!(@cert_file_path)
      File.chmod!(@cert_file_path, 0o600)
      File.write!(@cert_file_path, "#{cert}\n#{pkey}")

      Application.put_env(:webbait, :integrated_turn_cert_pkey, @cert_file_path)
    else
      Membrane.Logger.warn("""
      Integrated TURN certificate or private key path not specified.
      Integrated TURN will not handle TLS connections.
      """)
    end
  end

  defp delete_cert_file(), do: File.rm(@cert_file_path)

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
