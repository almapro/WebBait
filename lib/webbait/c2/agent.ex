defmodule WebBait.C2.Agent do
  use Ecto.Schema
  import Ecto.Changeset
  alias WebBait.C2.{AgentToken,AgentActivity,AgentCommand}

  schema "agents" do
    field :agentId, :string
    field :domain, :string
    field :url, :string
    has_many :tokens, AgentToken
    has_many :activities, AgentActivity
    has_many :commands, AgentCommand

    timestamps()
  end

  @doc false
  def changeset(agent, attrs) do
    agent
    |> cast(attrs, [:agentId, :domain, :url])
    |> validate_required([:agentId, :domain, :url])
    |> unique_constraint(:agentId)
  end
end
