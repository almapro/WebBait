defmodule WebBait.C2Test do
  use WebBait.DataCase

  alias WebBait.C2

  describe "agents" do
    alias WebBait.C2.Agent

    import WebBait.C2Fixtures

    @invalid_attrs %{agentId: nil, domain: nil, url: nil}

    test "list_agents/0 returns all agents" do
      agent = agent_fixture()
      assert C2.list_agents() == [agent]
    end

    test "get_agent!/1 returns the agent with given id" do
      agent = agent_fixture()
      assert C2.get_agent!(agent.id) == agent
    end

    test "create_agent/1 with valid data creates a agent" do
      valid_attrs = %{agentId: "some agentId", domain: "some domain", url: "some url"}

      assert {:ok, %Agent{} = agent} = C2.create_agent(valid_attrs)
      assert agent.agentId == "some agentId"
      assert agent.domain == "some domain"
      assert agent.url == "some url"
    end

    test "create_agent/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = C2.create_agent(@invalid_attrs)
    end

    test "update_agent/2 with valid data updates the agent" do
      agent = agent_fixture()
      update_attrs = %{agentId: "some updated agentId", domain: "some updated domain", url: "some updated url"}

      assert {:ok, %Agent{} = agent} = C2.update_agent(agent, update_attrs)
      assert agent.agentId == "some updated agentId"
      assert agent.domain == "some updated domain"
      assert agent.url == "some updated url"
    end

    test "update_agent/2 with invalid data returns error changeset" do
      agent = agent_fixture()
      assert {:error, %Ecto.Changeset{}} = C2.update_agent(agent, @invalid_attrs)
      assert agent == C2.get_agent!(agent.id)
    end

    test "delete_agent/1 deletes the agent" do
      agent = agent_fixture()
      assert {:ok, %Agent{}} = C2.delete_agent(agent)
      assert_raise Ecto.NoResultsError, fn -> C2.get_agent!(agent.id) end
    end

    test "change_agent/1 returns a agent changeset" do
      agent = agent_fixture()
      assert %Ecto.Changeset{} = C2.change_agent(agent)
    end
  end
end
