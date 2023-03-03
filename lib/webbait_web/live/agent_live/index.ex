defmodule WebBaitWeb.AgentLive.Index do
  use WebBaitWeb, :live_view

  alias WebBait.Presence
  alias WebBait.C2
  alias WebbaitWeb.AgentLive.SearchComponent

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebBait.PubSub, "agents")
      Phoenix.PubSub.subscribe(WebBait.PubSub, "agents:presence")

      Phoenix.PubSub.broadcast(WebBait.PubSub, "agents:presence", %{
        event: "presence_diff",
        payload: %{joins: Presence.list("agents:presence"), leaves: %{}}
      })
    end

    {:ok,
     socket
     |> assign(:search, "")
     |> assign(:agentsOnline, %{})
     |> assign(:agents, list_agents())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Agents")
    |> assign(:agent, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    agent = C2.get_agent!(id)
    {:ok, _} = C2.delete_agent(agent)

    {:noreply, assign(socket, :agents, list_agents())}
  end

  @impl true
  def handle_info("new agent", socket) do
    {:noreply, assign(socket, :agents, list_agents())}
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
    agentsOnline = socket.assigns.agentsOnline

    final_agentsOnlineList = for agent <- socket.assigns.agents do
      count =
        if Map.has_key?(agentsOnline, agent.agentId),
          do: Enum.at(Tuple.to_list(agentsOnline[agent.agentId]), 1),
          else: 0

      Map.put(agentsOnline, agent.agentId, WebBait.agentOnlineStatus(diff, agent.agentId, count))
    end
    agentsOnline = Enum.into(final_agentsOnlineList, %{}, fn i ->
      k = Enum.at(Map.keys(i), 0)
      v = i[k]
      {k, v}
    end)

    {
      :noreply,
      socket
      |> assign(:agentsOnline, agentsOnline)
    }
  end

  defp list_agents do
    C2.list_agents()
  end

  def nice_print_agent_status(agentId, agentsOnline) do
    if Map.has_key?(agentsOnline, agentId) do
      {online, count} = agentsOnline[agentId]
      WebBait.nice_print_status(online, count)
    else
      WebBait.nice_print_status(false, 0)
    end
  end
end
