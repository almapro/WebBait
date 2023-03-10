defmodule WebBaitWeb.AgentLiveTest do
  use WebBaitWeb.ConnCase

  import Phoenix.LiveViewTest
  import WebBait.C2Fixtures

  @create_attrs %{agentId: "some agentId", domain: "some domain", url: "some url"}
  @update_attrs %{agentId: "some updated agentId", domain: "some updated domain", url: "some updated url"}
  @invalid_attrs %{agentId: nil, domain: nil, url: nil}

  defp create_agent(_) do
    agent = agent_fixture()
    %{agent: agent}
  end

  describe "Index" do
    setup [:create_agent]

    test "lists all agents", %{conn: conn, agent: agent} do
      {:ok, _index_live, html} = live(conn, Routes.agent_index_path(conn, :index))

      assert html =~ "Listing Agents"
      assert html =~ agent.agentId
    end

    test "saves new agent", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.agent_index_path(conn, :index))

      assert index_live |> element("a", "New Agent") |> render_click() =~
               "New Agent"

      assert_patch(index_live, Routes.agent_index_path(conn, :new))

      assert index_live
             |> form("#agent-form", agent: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#agent-form", agent: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.agent_index_path(conn, :index))

      assert html =~ "Agent created successfully"
      assert html =~ "some agentId"
    end

    test "updates agent in listing", %{conn: conn, agent: agent} do
      {:ok, index_live, _html} = live(conn, Routes.agent_index_path(conn, :index))

      assert index_live |> element("#agent-#{agent.id} a", "Edit") |> render_click() =~
               "Edit Agent"

      assert_patch(index_live, Routes.agent_index_path(conn, :edit, agent))

      assert index_live
             |> form("#agent-form", agent: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#agent-form", agent: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.agent_index_path(conn, :index))

      assert html =~ "Agent updated successfully"
      assert html =~ "some updated agentId"
    end

    test "deletes agent in listing", %{conn: conn, agent: agent} do
      {:ok, index_live, _html} = live(conn, Routes.agent_index_path(conn, :index))

      assert index_live |> element("#agent-#{agent.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#agent-#{agent.id}")
    end
  end

  describe "Show" do
    setup [:create_agent]

    test "displays agent", %{conn: conn, agent: agent} do
      {:ok, _show_live, html} = live(conn, Routes.agent_show_path(conn, :show, agent))

      assert html =~ "Show Agent"
      assert html =~ agent.agentId
    end

    test "updates agent within modal", %{conn: conn, agent: agent} do
      {:ok, show_live, _html} = live(conn, Routes.agent_show_path(conn, :show, agent))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Agent"

      assert_patch(show_live, Routes.agent_show_path(conn, :edit, agent))

      assert show_live
             |> form("#agent-form", agent: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#agent-form", agent: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.agent_show_path(conn, :show, agent))

      assert html =~ "Agent updated successfully"
      assert html =~ "some updated agentId"
    end
  end
end
