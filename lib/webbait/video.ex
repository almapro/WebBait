defmodule WebBait.Video do
  @moduledoc """
  The Video context.
  """

  import Ecto.Query, warn: false
  alias WebBait.Repo

  alias WebBait.Video.RoomPeer

  @doc """
  Returns the list of room_peers.

  ## Examples

      iex> list_room_peers()
      [%RoomPeer{}, ...]

  """
  def list_room_peers do
    Repo.all(RoomPeer)
  end

  @doc """
  Gets a single room_peer.

  Raises `Ecto.NoResultsError` if the Room peer does not exist.

  ## Examples

      iex> get_room_peer!(123)
      %RoomPeer{}

      iex> get_room_peer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room_peer!(id), do: Repo.get!(RoomPeer, id)

  @doc """
  Creates a room_peer.

  ## Examples

      iex> create_room_peer(%{field: value})
      {:ok, %RoomPeer{}}

      iex> create_room_peer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room_peer(attrs \\ %{}) do
    %RoomPeer{}
    |> RoomPeer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room_peer.

  ## Examples

      iex> update_room_peer(room_peer, %{field: new_value})
      {:ok, %RoomPeer{}}

      iex> update_room_peer(room_peer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room_peer(%RoomPeer{} = room_peer, attrs) do
    room_peer
    |> RoomPeer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room_peer.

  ## Examples

      iex> delete_room_peer(room_peer)
      {:ok, %RoomPeer{}}

      iex> delete_room_peer(room_peer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room_peer(%RoomPeer{} = room_peer) do
    Repo.delete(room_peer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room_peer changes.

  ## Examples

      iex> change_room_peer(room_peer)
      %Ecto.Changeset{data: %RoomPeer{}}

  """
  def change_room_peer(%RoomPeer{} = room_peer, attrs \\ %{}) do
    RoomPeer.changeset(room_peer, attrs)
  end
end
