defmodule WebBaitWeb.RoomLive.ConnectionComponent do
  use WebBaitWeb, :live_component
  alias Phoenix.LiveView.JS

  def connectDisconnect(js \\ %JS{}) do
    js
    |> JS.dispatch("webrtc:connectDisconnect")
  end

  def render(assigns) do
    ~H"""
    <div id="room" class="grid grid-rows-[calc(100%-3rem)_3rem] h-full overflow-hidden" data-room-id={@room_id}>
      <section class="flex flex-col h-full">
        <header class="p-4">
          <h3 class="text-2xl font-semibold mb-2">Room: <%= @room_id %></h3>
          <div class="text-xl font-medium flex flex-col gap-2">
            <%= for {peer_id, %{"name" => name, "connected" => connected}} <- @peers do %>
              <div id={peer_id} class="grid grid-cols-4 grid-cols-[.1fr_.3fr_.3fr_.3fr] gap-4">
              <p class="my-auto">Peer: <%= URI.decode(name) %><%= if (@my_peer_id == peer_id) do %><p>(You)</p><% end %></p>
              <%= if (@my_peer_id != peer_id) do %>
                <button class="bg-sky-700 p-2 rounded transition duration-300 hover:bg-sky-900 text-white" phx-click="commandPeerToConnectOrDisconnect" phx-value-peer_id={peer_id} phx-target={@myself}>Command to <%= if (connected) do "disconnect" else"connect" end %></button>
                <button class={"p-2 rounded#{if (connected) do " bg-sky-700 transition duration-300 hover:bg-sky-900 text-white" else " bg-gray-500 cursor-not-allowed" end}"} disabled={!connected} phx-click="toggle-video" phx-value-peer_id={peer_id} phx-target={@myself}>Toggle video</button>
                <button class={"p-2 rounded#{if (connected) do " bg-sky-700 transition duration-300 hover:bg-sky-900 text-white" else " bg-gray-500 cursor-not-allowed" end}"} disabled={!connected} phx-click="toggle-audio" phx-value-peer_id={peer_id} phx-target={@myself}>Toggle audio</button>
              <% end %>
            </div>
          <% end %>
        </div>
        <div id="participants-list" class="text-xl font-medium flex flex-col gap-2"> </div>
      </header>
      <div id="videochat-error" class="VideoChatError" style="display: none;"> </div>
      <div id="videochat" class="p-2 overflow-y-auto h-full">
        <template id="video-feed-template">
          <div name="video-feed" class="relative bg-gray-900 shadow rounded-md overflow-hidden h-1/4 w-1/4 ratio-video">
            <audio></audio>
            <video class="w-full"></video>
            <div name="video-label" class="absolute text-shadow-lg bottom-0 left-0 p-2">Placeholder</div>
          </div>
        </template>
        <div class="flex flex-col justify-center items-center h-full">
          <div id="videos-grid" class="flex flex-row flex-wrap gap-2 w-full h-full">
            <%= for {peer_id, %{"name" => name} } <- @peers do %>
              <div
                id={"feed-#{if (peer_id === @my_peer_id) do "local-peer" else peer_id end}"}
                name="video-feed"
                class="relative bg-black/30 rounded-md overflow-hidden basis-full md:basis-1/2 lg:basis-1/3 w-full h-full aspect-auto md:aspect-video border-gray-500 border">
                <audio muted={if (peer_id === @my_peer_id) do true else false end} autoplay={true} id={"audio-#{peer_id}"}></audio>
                <video muted={true} autoplay={true} playsInline={true} id={"video-#{peer_id}"} class="w-full h-full"></video>
                <div id={"label-#{peer_id}"} name="video-label" class="absolute bottom-0 p-2 bg-gradient-to-t from-black to-transparent text-white w-full text-left">
                  <%= if (peer_id === @my_peer_id) do "(You)" else URI.decode(name) end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </section>
    <div id="controls" class="flex justify-center gap-2 h-full py-2">
      <button
        data-tooltip-target="connect-toggle-tooltip"
        class="w-1/6 rounded text-white bg-sky-700 hover:bg-sky-900"
        phx-click={connectDisconnect()}>
        <%= if (@connected) do %>
          <i class='fa fa-right-from-bracket m-auto'></i>
        <% else %>
          <i class='fa fa-right-to-bracket m-auto'></i>
        <% end %>
      </button>
      <div id="connect-toggle-tooltip" role="tooltip" class="absolute z-10 invisible inline-block px-3 py-2 text-sm font-medium text-white transition-opacity duration-300 bg-gray-900 rounded-lg shadow-sm opacity-0 tooltip dark:bg-gray-700">
        <%= if (@connected) do "Disconnect" else "Connect" end %>
        <div class="tooltip-arrow" data-popper-arrow></div>
      </div>
      <button
        disabled={!@connected}
        data-tooltip-target="video-toggle-tooltip"
        class="w-1/6 rounded text-white bg-sky-700 hover:bg-sky-900"
        phx-click="toggle-video"
        phx-value-peer_id={@my_peer_id}
        phx-target={@myself}>
        <i class="fa fa-camera m-auto"></i>
      </button>
      <div id="video-toggle-tooltip" role="tooltip" class="absolute z-10 invisible inline-block px-3 py-2 text-sm font-medium text-white transition-opacity duration-300 bg-gray-900 rounded-lg shadow-sm opacity-0 tooltip dark:bg-gray-700">
        Toggle Video
        <div class="tooltip-arrow" data-popper-arrow></div>
      </div>
      <button
        disabled={!@connected}
        data-tooltip-target="audio-toggle-tooltip"
        class="w-1/6 rounded text-white bg-sky-700 hover:bg-sky-900"
        phx-click="toggle-audio"
        phx-value-peer_id={@my_peer_id}
        phx-target={@myself}>
        <i class="fa fa-microphone m-auto"></i>
      </button>
      <div id="audio-toggle-tooltip" role="tooltip" class="absolute z-10 invisible inline-block px-3 py-2 text-sm font-medium text-white transition-opacity duration-300 bg-gray-900 rounded-lg shadow-sm opacity-0 tooltip dark:bg-gray-700">
        Toggle audio
        <div class="tooltip-arrow" data-popper-arrow></div>
      </div>
    </div>
    </div>
    """
  end

  def handle_event("commandPeerToConnectOrDisconnect", %{"peer_id" => peer_id}, socket) do
    case Enum.find(socket.assigns.peers, fn {p_id, _} -> p_id == peer_id end) do
      {_, %{"peer_channel_pid" => peer_channel_pid, "connected" => connected}} ->
        send(
          peer_channel_pid,
          if connected do
            "disconnect"
          else
            "connect"
          end
        )
    end

    {:noreply, socket}
  end

  def handle_event("toggle-video", %{"peer_id" => peer_id}, socket) do
    case Enum.find(socket.assigns.peers, fn {p_id, _} -> p_id == peer_id end) do
      {_, %{"peer_channel_pid" => peer_channel_pid}} ->
        send(
          peer_channel_pid,
          "toggle-video"
        )
    end

    {:noreply, socket}
  end

  def handle_event("toggle-audio", %{"peer_id" => peer_id}, socket) do
    case Enum.find(socket.assigns.peers, fn {p_id, _} -> p_id == peer_id end) do
      {_, %{"peer_channel_pid" => peer_channel_pid}} ->
        send(
          peer_channel_pid,
          "toggle-audio"
        )
    end

    {:noreply, socket}
  end
end
