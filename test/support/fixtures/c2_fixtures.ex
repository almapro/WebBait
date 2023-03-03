defmodule WebBait.C2Fixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `WebBait.C2` context.
  """

  @doc """
  Generate a unique agent agentId.
  """
  def unique_agent_agentId, do: "some agentId#{System.unique_integer([:positive])}"

  @doc """
  Generate a agent.
  """
  def agent_fixture(attrs \\ %{}) do
    {:ok, agent} =
      attrs
      |> Enum.into(%{
        agentId: unique_agent_agentId(),
        domain: "some domain",
        url: "some url"
      })
      |> WebBait.C2.create_agent()

    agent
  end
end
