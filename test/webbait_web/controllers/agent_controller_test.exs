defmodule WebBaitWeb.AgentControllerTest do
  use WebBaitWeb.ConnCase

  import WebBait.C2Fixtures

  alias WebBait.C2.Agent

  @create_attrs %{
    agentId: "some agentId",
    domain: "some domain",
    url: "some url"
  }
  @update_attrs %{
    agentId: "some updated agentId",
    domain: "some updated domain",
    url: "some updated url"
  }
  @invalid_attrs %{agentId: nil, domain: nil, url: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all agents", %{conn: conn} do
      conn = get(conn, Routes.agent_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create agent" do
    test "renders agent when data is valid", %{conn: conn} do
      conn = post(conn, Routes.agent_path(conn, :create), agent: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.agent_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "agentId" => "some agentId",
               "domain" => "some domain",
               "url" => "some url"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.agent_path(conn, :create), agent: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update agent" do
    setup [:create_agent]

    test "renders agent when data is valid", %{conn: conn, agent: %Agent{id: id} = agent} do
      conn = put(conn, Routes.agent_path(conn, :update, agent), agent: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.agent_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "agentId" => "some updated agentId",
               "domain" => "some updated domain",
               "url" => "some updated url"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, agent: agent} do
      conn = put(conn, Routes.agent_path(conn, :update, agent), agent: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete agent" do
    setup [:create_agent]

    test "deletes chosen agent", %{conn: conn, agent: agent} do
      conn = delete(conn, Routes.agent_path(conn, :delete, agent))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.agent_path(conn, :show, agent))
      end
    end
  end

  defp create_agent(_) do
    agent = agent_fixture()
    %{agent: agent}
  end
end
