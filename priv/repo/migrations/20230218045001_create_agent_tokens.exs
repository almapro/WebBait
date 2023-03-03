defmodule WebBait.Repo.Migrations.CreateAgentTokens do
  use Ecto.Migration

  def change do
    create table(:agent_tokens) do
      add :token, :string
      add :expiresAt, :utc_datetime
      add :used, :boolean, default: false, null: false
      add :agent_id, references(:agents, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:agent_tokens, [:token])
    create index(:agent_tokens, [:agent_id])
  end
end
