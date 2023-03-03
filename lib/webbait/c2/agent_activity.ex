defmodule WebBait.C2.AgentActivity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "agent_activities" do
    field :ip, :string
    field :mac, :string
    field :userAgent, :string
    field :type, Ecto.Enum, values: [:create_agent, :generate_token, :socket_activity]
    field :agent_id, :id

    timestamps()
  end

  @doc false
  def changeset(agent_activity, attrs) do
    agent_activity
    |> cast(attrs, [:ip, :mac, :userAgent, :type])
    |> validate_required([:ip, :userAgent, :type])
  end
end
