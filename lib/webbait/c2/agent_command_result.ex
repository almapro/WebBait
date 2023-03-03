defmodule WebBait.C2.AgentCommandResult do
  use Ecto.Schema
  import Ecto.Changeset

  schema "agent_command_results" do
    field :result, :string
    field :agent_command_id, :id

    timestamps()
  end

  @doc false
  def changeset(agent_command_result, attrs) do
    agent_command_result
    |> cast(attrs, [:result])
    |> validate_required([:result])
  end
end
