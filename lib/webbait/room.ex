defmodule WebBait.Room do
  @moduledoc false

  use GenServer

  alias Membrane.RTC.Engine
  alias Membrane.RTC.Engine.Message
  alias Membrane.RTC.Engine.Endpoint.WebRTC
  require Membrane.Logger
  require Logger

  def start(init_arg, opts) do
    GenServer.start(__MODULE__, init_arg, opts)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @impl true
  def init(room_id) do
    Membrane.Logger.info("Spawning room proces: #{inspect(self())}")
    Phoenix.PubSub.subscribe(WebBait.PubSub, "liveview:" <> room_id)

    # When running via docker without using host network we
    # have to listen at 0.0.0.0 but our packets still need
    # valid IP address in their headers. We store it under `mock_ip`.
    {:ok, iflist} = :inet.getifaddrs()
    iflist =
      Enum.filter(iflist, fn {ifname, ifprops} ->
        ifname != 'lo' && !String.match?(to_string(ifname), ~r/docker[\d]+/) &&
          ifprops[:addr]
      end)
    {_, ifprops} = Enum.at(iflist, 0)
    e_ip = Application.fetch_env!(:webbait, :external_ip)
    mock_ip = if Enum.count(iflist) > 0 && e_ip == { 127, 0, 0, 1 } && Mix.env() == :dev, do: ifprops[:addr], else: e_ip
    external_ip = if Mix.env() == :prod, do: {0, 0, 0, 0}, else: mock_ip
    msg_to_print = "Listening on IP => #{Enum.join(Tuple.to_list(external_ip), ".")}"
    if Mix.env() == :dev, do: IO.puts("\n\r#{String.duplicate("#", String.length(msg_to_print) + 4)}\n\r# #{msg_to_print} #\n\r#{String.duplicate("#", String.length(msg_to_print) + 4)}\n\r")
    port_range = Application.fetch_env!(:webbait, :port_range)

    rtc_engine_options = [
      id: room_id
    ]

    integrated_turn_options = [
      ip: external_ip,
      mock_ip: mock_ip,
      ports_range: port_range
    ]

    network_options = [
      integrated_turn_options: integrated_turn_options,
      dtls_pkey: Application.get_env(:webbait, :dtls_pkey),
      dtls_cert: Application.get_env(:webbait, :dtls_cert)
    ]

    {:ok, pid} = Membrane.RTC.Engine.start(rtc_engine_options, [])
    Engine.register(pid, self())
    Process.monitor(pid)

    {:ok,
      %{rtc_engine: pid, peer_channels: %{}, network_options: network_options, room_id: room_id}}
  end

  @impl true
  def handle_info({:add_peer_channel, peer_channel_pid, peer_id, name, username, socket}, state) do
    state =
      put_in(state, [:peer_channels, peer_id], %{
        "peer_channel_pid" => peer_channel_pid,
        "name" => name,
        "username" => username,
        "socket" => socket,
        "connected" => false,
        "videoSent" => false,
        "audioSent" => false
      })

    Process.monitor(peer_channel_pid)

    Phoenix.PubSub.broadcast(
      WebBait.PubSub,
      state.room_id,
      {"channel peers", state.peer_channels}
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(%Message.MediaEvent{to: :broadcast, data: data}, state) do
    for {_peer_id, %{"peer_channel_pid" => pid}} <- state.peer_channels,
      do: send(pid, {:media_event, data})

    {:noreply, state}
  end

  @impl true
  def handle_info(%Message.MediaEvent{to: to, data: data}, state) do
    if state.peer_channels[to] != nil do
      send(state.peer_channels[to]["peer_channel_pid"], {:media_event, data})
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(%Message.NewPeer{rtc_engine: rtc_engine, peer: peer}, state) do
    Membrane.Logger.info("New peer: #{inspect(peer)}. Accepting.")
    # get node the peer with peer_id is running on
    %{"peer_channel_pid" => peer_channel_pid, "name" => name, "username" => username, "socket" => socket} =
      Map.get(state.peer_channels, peer.id)

    peer_node = node(peer_channel_pid)

    handshake_opts =
      if state.network_options[:dtls_pkey] &&
        state.network_options[:dtls_cert] do
        [
          client_mode: false,
          dtls_srtp: true,
          pkey: state.network_options[:dtls_pkey],
          cert: state.network_options[:dtls_cert]
        ]
      else
        [
          client_mode: false,
          dtls_srtp: true
        ]
      end

    endpoint = %WebRTC{
      rtc_engine: rtc_engine,
      ice_name: peer.id,
      extensions: %{},
      owner: self(),
      integrated_turn_options: state.network_options[:integrated_turn_options],
      handshake_opts: handshake_opts,
      log_metadata: [peer_id: peer.id]
    }

    Engine.accept_peer(rtc_engine, peer.id)

    :ok =
      Engine.add_endpoint(rtc_engine, endpoint,
        peer_id: peer.id,
        node: peer_node
      )

    state =
      put_in(state, [:peer_channels, peer.id], %{
        "peer_channel_pid" => peer_channel_pid,
        "name" => name,
        "username" => username,
        "socket" => socket,
        "connected" => true,
        "videoSent" => false,
        "audioSent" => false
      })

    Phoenix.PubSub.broadcast(
      WebBait.PubSub,
      state.room_id,
      {"channel peers", state.peer_channels}
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(%Message.PeerLeft{peer: peer}, state) do
    Membrane.Logger.info("Peer #{inspect(peer.id)} left RTC Engine")

    %{"peer_channel_pid" => peer_channel_pid, "name" => name, "username" => username, "socket" => socket} =
      Map.get(state.peer_channels, peer.id)

    state =
      put_in(state, [:peer_channels, peer.id], %{
        "peer_channel_pid" => peer_channel_pid,
        "name" => name,
        "username" => username,
        "socket" => socket,
        "connected" => false,
        "videoSent" => false,
        "audioSent" => false
      })

    Phoenix.PubSub.broadcast(
      WebBait.PubSub,
      state.room_id,
      {"channel peers", state.peer_channels}
    )

    {:noreply, state}
  end

  @impl true
  def handle_info({:media_event, from, event} = msg, state) do
    {:ok, decoded_event} = Jason.decode(event)
    Engine.receive_media_event(state.rtc_engine, msg)

    if decoded_event["data"]["type"] == "sdpOffer" do
      sdp = decoded_event["data"]["data"]["sdpOffer"]["sdp"]
      sdp_parts = String.split(sdp, ~r{(\r\n|\r|\n)})
      video_str = Enum.find(sdp_parts, Enum.random(sdp_parts), fn p -> String.match?(p, ~r/m=video/) end)
      audio_str = Enum.find(sdp_parts, Enum.random(sdp_parts), fn p -> String.match?(p, ~r/m=audio/) end)
      IO.inspect("==================== [event]")
      IO.inspect(sdp_parts)
      IO.inspect(video_str)
      IO.inspect(audio_str)
      IO.inspect("====================")
      audio = String.match?(sdp, ~r/m=audio/)
      video = String.match?(sdp, ~r/m=video/)
      Membrane.Logger.info("audio => #{audio}")
      Membrane.Logger.info("video => #{video}")

      %{
        "peer_channel_pid" => peer_channel_pid,
        "name" => name,
        "username" => username,
        "socket" => socket,
        "connected" => connected,
        "videoSent" => videoSent,
        "audioSent" => audioSent
      } = Map.get(state.peer_channels, from)

      state =
        put_in(state, [:peer_channels, from], %{
          "peer_channel_pid" => peer_channel_pid,
          "name" => name,
        "username" => username,
          "socket" => socket,
          "connected" => connected,
          "videoSent" => video || videoSent,
          "audioSent" => audio || audioSent
        })

      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        state.room_id,
        {"channel peers", state.peer_channels}
      )

      {:noreply, state}
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    if pid == state.rtc_engine do
      {:stop, :normal, state}
    else
      {peer_id, _peer_channel_id} =
        state.peer_channels
        |> Enum.find(fn {_peer_id, %{"peer_channel_pid" => peer_channel_pid}} ->
          peer_channel_pid == pid
        end)

      Engine.remove_peer(state.rtc_engine, peer_id)
      {_elem, state} = pop_in(state, [:peer_channels, peer_id])

      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        state.room_id,
        {"channel peers", state.peer_channels}
      )
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({"send peers"}, state) do
    Phoenix.PubSub.broadcast(
      WebBait.PubSub,
      state.room_id,
      {"channel peers", state.peer_channels}
    )

    {:noreply, state}
  end
end
