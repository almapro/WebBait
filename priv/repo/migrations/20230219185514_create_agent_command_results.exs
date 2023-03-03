defmodule WebBait.Repo.Migrations.CreateAgentCommandResults do
  use Ecto.Migration

  def change do
    create table(:agent_command_results) do
      add :result, :string
      add :agent_command_id, references(:agent_commands, on_delete: :delete_all)

      timestamps()
    end

    create index(:agent_command_results, [:agent_command_id])
  end
end
