defmodule WebBait.Repo.Migrations.CreateAgentCommands do
  use Ecto.Migration

  def change do
    create table(:agent_commands) do
      add :cmd, :string
      add :cmdId, :string
      add :received, :boolean, default: false, null: false
      add :agent_id, references(:agents, on_delete: :delete_all)

      timestamps()
    end

    create index(:agent_commands, [:agent_id])
  end
end
