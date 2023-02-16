defmodule WebBait.VideoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `WebBait.Video` context.
  """

  @doc """
  Generate a unique room_peer room_id.
  """
  def unique_room_peer_room_id, do: "some room_id#{System.unique_integer([:positive])}"

  @doc """
  Generate a room_peer.
  """
  def room_peer_fixture(attrs \\ %{}) do
    {:ok, room_peer} =
      attrs
      |> Enum.into(%{
        display_name: "some display_name",
        room_id: unique_room_peer_room_id()
      })
      |> WebBait.Video.create_room_peer()

    room_peer
  end
end
