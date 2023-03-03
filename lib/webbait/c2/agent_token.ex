defmodule WebBait.C2.AgentToken do
  use Ecto.Schema
  import Ecto.Changeset

  schema "agent_tokens" do
    field :token, :string
    field :expiresAt, :utc_datetime
    field :used, :boolean, default: false
    field :agent_id, :id

    timestamps()
  end

  @doc false
  def changeset(agent_token, attrs) do
    agent_token
    |> cast(attrs, [:token, :expiresAt, :used])
    |> validate_required([:token])
    |> unique_constraint(:token)
  end
end
