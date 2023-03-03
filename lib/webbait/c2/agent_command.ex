defmodule WebBait.C2.AgentCommand do
  use Ecto.Schema
  import Ecto.Changeset

  schema "agent_commands" do
    field :cmd, :string
    field :cmdId, :string
    field :received, :boolean, default: false
    field :agent_id, :id
    has_one :result, WebBait.C2.AgentCommandResult

    timestamps()
  end

  @doc false
  def changeset(agent_command, attrs) do
    agent_command
    |> cast(attrs, [:cmd, :cmdId, :received])
    |> validate_required([:cmd, :cmdId])
  end
end
