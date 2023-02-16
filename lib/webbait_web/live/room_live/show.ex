defmodule WebBaitWeb.RoomLive.Show do
  use WebBaitWeb, :live_view
  alias WebBaitWeb.RoomLive.ConnectionComponent
  alias WebBait.Accounts

  @impl true
  def mount(%{"id" => room_id}, %{ "user_token" => token } = _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebBait.PubSub, room_id)
      Phoenix.PubSub.broadcast(WebBait.PubSub, "liveview:" <> room_id, {"send peers"})
    end
    user = Accounts.get_user_by_session_token(token)
    name = "#{user.firstName} #{user.lastName}"
    {:ok,
     socket
     |> assign(:room_id, room_id)
     |> assign(:name, name)
     |> assign(:connected, false)
     |> assign(:peers, %{})
     |> assign(:current_user, user)
     |> assign(:my_peer_id, "")}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Room: " <> id)
     |> assign(:room_id, id)}
  end

  @impl true
  def handle_info({"channel peers", peers}, socket) do
    case socket.assigns.peers == peers do
      true ->
        {:noreply, socket}

      false ->
        case Enum.find(peers, fn {_, %{"username" => username}} ->
               username === socket.assigns.current_user.username
             end) do
          {peer_id, %{"peer_channel_pid" => peer_channel_pid}} ->
            send(peer_channel_pid, {:peers, peers})

            {:noreply,
             socket
             |> assign(:peers, peers)
             |> assign(:connected, true)
             |> assign(:my_peer_id, peer_id)}

          _ ->
            {:noreply,
             socket
             |> assign(:peers, peers)}
        end
    end
  end
end
