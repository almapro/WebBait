defmodule WebBaitWeb.AgentLive.Commands do
  use WebBaitWeb, :live_view

  alias WebBait.Presence
  alias WebBait.C2
  alias WebbaitWeb.AgentLive.SearchComponent
  alias WebbaitWeb.AgentLive.OnlineStatusComponent

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebBait.PubSub, "agents:" <> id)
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
     |> assign(:agent, C2.get_agent!(id))
     |> assign(:commands, C2.get_agent_commands(id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    C2.delete_agent_command(id)
    handle_command_return(socket)
  end

  def handle_command_return(socket) do
    {
      :noreply,
      socket
      |> assign(:commands, C2.get_agent_commands(socket.assigns.agent.id))
    }
  end

  defp page_title(:index), do: "Agent's commands"

  def nice_print_command(command, socket, agent) do
    assigns = %{}

    case command do
      "set-template " <> template ->
        "Set template (#{String.upcase(String.first(template))}#{String.slice(template, 1, String.length(template) - 1)})"

      "initiate-webrtc" ->
        ~H"""
          <%= live_redirect "Initiate WebRTC", to: Routes.agent_webrtc_path(socket, :index, agent.id), class: "cursor-pointer p-2 text-sm rounded text-center bg-gray-200 hover:bg-gray-300 dark:bg-gray-600 dark:hover:bg-gray-800" %>
        """

      :socket_command ->
        "Socket command"

      _ ->
        command
    end
  end

  def nice_print_result(result) do
    case result do
      "template-set" ->
        "Template has been set"

      _ ->
        result
    end
  end

  @impl true
  def handle_info("commands", socket) do
    {:noreply, assign(socket, :commands, C2.get_agent_commands(socket.assigns.agent.id))}
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
