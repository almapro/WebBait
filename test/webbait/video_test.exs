defmodule WebBait.VideoTest do
  use WebBait.DataCase

  alias WebBait.Video

  describe "room_peers" do
    alias WebBait.Video.RoomPeer

    import WebBait.VideoFixtures

    @invalid_attrs %{display_name: nil, room_id: nil}

    test "list_room_peers/0 returns all room_peers" do
      room_peer = room_peer_fixture()
      assert Video.list_room_peers() == [room_peer]
    end

    test "get_room_peer!/1 returns the room_peer with given id" do
      room_peer = room_peer_fixture()
      assert Video.get_room_peer!(room_peer.id) == room_peer
    end

    test "create_room_peer/1 with valid data creates a room_peer" do
      valid_attrs = %{display_name: "some display_name", room_id: "some room_id"}

      assert {:ok, %RoomPeer{} = room_peer} = Video.create_room_peer(valid_attrs)
      assert room_peer.display_name == "some display_name"
      assert room_peer.room_id == "some room_id"
    end

    test "create_room_peer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Video.create_room_peer(@invalid_attrs)
    end

    test "update_room_peer/2 with valid data updates the room_peer" do
      room_peer = room_peer_fixture()
      update_attrs = %{display_name: "some updated display_name", room_id: "some updated room_id"}

      assert {:ok, %RoomPeer{} = room_peer} = Video.update_room_peer(room_peer, update_attrs)
      assert room_peer.display_name == "some updated display_name"
      assert room_peer.room_id == "some updated room_id"
    end

    test "update_room_peer/2 with invalid data returns error changeset" do
      room_peer = room_peer_fixture()
      assert {:error, %Ecto.Changeset{}} = Video.update_room_peer(room_peer, @invalid_attrs)
      assert room_peer == Video.get_room_peer!(room_peer.id)
    end

    test "delete_room_peer/1 deletes the room_peer" do
      room_peer = room_peer_fixture()
      assert {:ok, %RoomPeer{}} = Video.delete_room_peer(room_peer)
      assert_raise Ecto.NoResultsError, fn -> Video.get_room_peer!(room_peer.id) end
    end

    test "change_room_peer/1 returns a room_peer changeset" do
      room_peer = room_peer_fixture()
      assert %Ecto.Changeset{} = Video.change_room_peer(room_peer)
    end
  end
end
