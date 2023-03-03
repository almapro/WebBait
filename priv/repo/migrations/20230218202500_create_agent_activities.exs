defmodule WebBait.Repo.Migrations.CreateAgentActivities do
  use Ecto.Migration

  def change do
    create table(:agent_activities) do
      add :ip, :string
      add :mac, :string, null: true
      add :userAgent, :string
      add :type, :string, null: false
      add :agent_id, references(:agents, on_delete: :delete_all)

      timestamps()
    end

    create index(:agent_activities, [:agent_id])
  end
end
