defmodule WebBaitWeb.PeerChannel do
  use Phoenix.Channel

  require Logger
  require Membrane.Logger

  @impl true
  def join("room:" <> room_id, %{"name" => name}, socket) do
    case :global.whereis_name(room_id) do
      :undefined -> WebBait.Room.start(room_id, name: {:global, room_id})
      pid -> {:ok, pid}
    end
    |> case do
      {:ok, room_pid} ->
        do_join(socket, name, room_pid, room_id)

      {:error, {:already_started, room_pid}} ->
        do_join(socket, name, room_pid, room_id)

      {:error, reason} ->
        Logger.error("""
        Failed to start room.
        Room: #{inspect(room_id)}
        Reason: #{inspect(reason)}
        """)

        {:error, %{reason: "failed to start room"}}
    end
  end

  defp do_join(socket, name, room_pid, room_id) do
    peer_id = "#{UUID.uuid4()}"
    # TODO handle crash of room?
    Process.monitor(room_pid)
    send(room_pid, {:add_peer_channel, self(), peer_id, name, socket})

    socket =
      Phoenix.Socket.assign(socket, %{
        room_id: room_id,
        room_pid: room_pid,
        peer_id: peer_id,
        name: name
      })

    {:ok, socket}
  end

  @impl true
  def handle_in("mediaEvent", %{"data" => event}, socket) do
    send(socket.assigns.room_pid, {:media_event, socket.assigns.peer_id, event})

    {:noreply, socket}
  end

  @impl true
  def handle_in("rejoin", _params, socket) do
    send(
      socket.assigns.room_pid,
      {:add_peer_channel, self(), socket.assigns.peer_id, socket.assigns.name, socket}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:media_event, event}, socket) do
    push(socket, "mediaEvent", %{data: event})

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:DOWN, _ref, :process, _pid, _reason},
        socket
      ) do
    {:stop, :normal, socket}
  end

  @impl true
  def handle_info("connect", socket) do
    push(socket, "connect", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_info("disconnect", socket) do
    push(socket, "disconnect", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_info("toggle-video", socket) do
    push(socket, "toggle-video", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_info("toggle-audio", socket) do
    push(socket, "toggle-audio", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:peers, peers}, socket) do
    list = Enum.into(peers, %{}, fn {peer_id, _} -> {peer_id, peer_id } end)
    push(socket, "peers", list)
    {:noreply, socket}
  end
end
