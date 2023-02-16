defmodule WebBait.Video.RoomPeer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_peers" do
    field :room_id, :string

    timestamps()
  end

  @doc false
  def changeset(room_peer, attrs) do
    room_peer
    |> cast(attrs, [:room_id])
    |> validate_required([:room_id])
    |> validate_length(:room_id, min: 4)
    |> unique_constraint(:room_id)
  end
end
