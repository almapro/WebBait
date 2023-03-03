defmodule WebBaitWeb.AgentView do
  use WebBaitWeb, :view

  def render("agent.json", %{agentId: agentId, token: token}) do
    %{
      agentId: agentId,
      token: token
    }
  end

  def render("token.json", %{token: token}) do
    %{
      token: token
    }
  end

  def render("not_found.json", _) do
    %{
      error: "agent not found"
    }
  end
end
