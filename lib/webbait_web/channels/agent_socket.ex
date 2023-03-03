defmodule WebBaitWeb.AgentSocket do
  import Ecto.Query, warn: false
  alias WebBait.C2
  use Phoenix.Socket

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels
  # Uncomment the following line to define a "room:*" topic
  # pointing to the `WebBaitWeb.RoomChannel`:
  #
  channel("agent:*", WebBaitWeb.AgentChannel)
  #
  # To create a channel file, use the mix task:
  #
  #     mix phx.gen.channel Room
  #
  # See the [`Channels guide`](https://hexdocs.pm/phoenix/channels.html)
  # for further details.

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"token" => token, "agentId" => agentId}, socket, %{
    peer_data: peer_data,
    user_agent: userAgent
  }) do
    ip = to_string(:inet_parse.ntoa(peer_data.address))
    case C2.socket_activity(token, agentId, ip, userAgent) do
      {:ok, agent, token} ->
        {
          :ok,
          socket
          |> assign(:agent, agent)
          |> assign(:token, token)
        }
      {:error, _} = response ->
        response
    end
  end

  @impl true
  def connect(%{"token" => token, "agentId" => agentId, "mac" => mac}, socket, %{
    peer_data: peer_data,
    user_agent: userAgent
  }) do
    ip = to_string(:inet_parse.ntoa(peer_data.address))
    case C2.socket_activity(token, agentId, ip, userAgent, mac) do
      {:ok, agent, token} ->
        {
          :ok,
          socket
          |> assign(:agent, agent)
          |> assign(:token, token)
        }
      {:error, _} = response ->
        response
    end
  end

  @impl true
  def connect(%{}, _socket, _connect_info) do
    {:error, %{"reason" => "No params has been passed"}}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.WebBaitWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
