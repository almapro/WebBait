defmodule WebBait.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false, size: 160
      add :firstName, :string, null: false, size: 160
      add :lastName, :string, null: true, size: 160
      add :email, :string, null: true, size: 160
      add :type, :string, null: false
      add :hashed_password, :string, null: false
      timestamps()
    end

    create unique_index(:users, [:username])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false, size: 32
      add :context, :string, null: false
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
