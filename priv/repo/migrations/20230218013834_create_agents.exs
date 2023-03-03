defmodule WebBait.Repo.Migrations.CreateAgents do
  use Ecto.Migration

  def change do
    create table(:agents) do
      add :agentId, :string
      add :domain, :string
      add :url, :string

      timestamps()
    end

    create unique_index(:agents, [:agentId])
  end
end
