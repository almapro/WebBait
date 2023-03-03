defmodule WebBaitWeb.AgentController do
  use WebBaitWeb, :controller

  alias WebBait.C2

  action_fallback(WebBaitWeb.FallbackController)

  def create(conn, params) do
    IO.inspect(conn)

    case C2.create_agent(conn, params) do
      {:ok, agentId, token} ->
        conn
        |> put_status(:created)
        |> render("agent.json", agentId: agentId, token: token)
    end
  end

  def token(conn, params) do
    case C2.generate_token(conn, params) do
      {:ok, token} ->
        conn
        |> put_status(:created)
        |> render("token.json", token: token)

      {:error, :agent_not_found} ->
        conn
        |> put_status(:not_found)
        |> render("not_found.json", agent_not_found: "agent_not_found")
    end
  end
end
