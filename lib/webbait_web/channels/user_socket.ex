defmodule WebBaitWeb.UserSocket do
  alias WebBait.Accounts
  use Phoenix.Socket

  channel "room:*", WebBaitWeb.PeerChannel
  channel "agent:*", WebBaitWeb.AgentChannel
  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels
  # Uncomment the following line to define a "room:*" topic
  # pointing to the `WebBaitWeb.RoomChannel`:
  #
  # channel "room:*", WebBaitWeb.RoomChannel
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
 
  # def connect(_params, socket, _connect_info) do
  #   {:ok, socket}
  # end
 
  @impl true
  def connect(%{"token" => token} = _params, socket, _connect_info) do
    {:ok, decoded_token} = Base.decode64(token)
    user = Accounts.get_user_by_session_token(decoded_token)
    {:ok,
      assign(socket, :current_user, user)}
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
