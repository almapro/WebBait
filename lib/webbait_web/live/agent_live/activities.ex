defmodule WebBaitWeb.AgentLive.Activities do
  use WebBaitWeb, :live_view

  alias WebBait.Presence
  alias WebBait.C2
  alias WebbaitWeb.AgentLive.SearchComponent
  alias WebbaitWeb.AgentLive.OnlineStatusComponent

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebBait.PubSub, "activities:" <> id)
      Phoenix.PubSub.subscribe(WebBait.PubSub, "agents:presence")

      Phoenix.PubSub.broadcast(WebBait.PubSub, "agents:presence", %{
        event: "presence_diff",
        payload: %{joins: Presence.list("agents:presence"), leaves: %{}}
      })
    end

    agent = C2.get_agent!(id)

    {:ok,
     socket
     |> assign(:agent, agent)
     |> assign(:agentId, agent.agentId)
     |> assign(:count, 0)
     |> assign(:online, false)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:search, "")
     |> assign(:activities, C2.get_agent_activities(id))}
  end

  defp page_title(:index), do: "Agent's activities"

  @impl true
  def handle_info("new activity", socket) do
    {:noreply, assign(socket, :activities, C2.get_agent_activities(socket.assigns.agent.id))}
  end

  @impl true
  def handle_info({:search, %{"search" => search}}, socket) do
    {
      :noreply,
      socket
      |> assign(:search, search)
    }
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    {online, count} =
      WebBait.agentOnlineStatus(diff, socket.assigns.agent.agentId, socket.assigns.count)

    {
      :noreply,
      socket
      |> assign(:online, online)
      |> assign(:count, count)
    }
  end
end
