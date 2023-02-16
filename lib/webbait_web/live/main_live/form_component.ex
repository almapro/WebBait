defmodule WebBaitWeb.MainLive.FormComponent do
  use WebBaitWeb, :live_component
  alias WebBait.Video
  alias WebBait.Video.RoomPeer

  @impl true
  def update(assigns, socket) do
    changeset = Video.change_room_peer(%RoomPeer{}, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"room_peer" => room_peer_params}, socket) do
    changeset =
      %RoomPeer{}
      |> Video.change_room_peer(room_peer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"room_peer" => room_peer_params}, socket) do
    IO.inspect(room_peer_params)
    {:noreply,
      socket
      |>push_redirect(to: Routes.room_show_path(socket, :show, room_peer_params["room_id"], room_peer_params["display_name"]))
    }
  end
end
