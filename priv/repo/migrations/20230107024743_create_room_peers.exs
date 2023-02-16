defmodule WebBait.Repo.Migrations.CreateRoomPeers do
  use Ecto.Migration

  def change do
    create table(:room_peers) do
      add :room_id, :string
      add :display_name, :string

      timestamps()
    end

    create unique_index(:room_peers, [:room_id])
  end
end
