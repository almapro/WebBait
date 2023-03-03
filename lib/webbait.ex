defmodule WebBait do
      # Use all HTML functionality (forms, tags, etc)
  use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
  import Phoenix.LiveView.Helpers
  @moduledoc """
  WebBait keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def main_interface_ip(env_ip, iflist) do
    if Enum.count(iflist) > 0 && env_ip == {127, 0, 0, 1} && Mix.env() == :dev do
      {_, ifprop} = Enum.at(iflist, 0)
      ifprop[:addr]
    else
      env_ip
    end
  end

  def agentOnlineStatus(diff, agentId, count) do
    if Map.has_key?(diff.joins, agentId) do
      {true, count + Enum.count(diff.joins[agentId].metas)}
    else
      if Map.has_key?(diff.leaves, agentId) do
        devicesOnline = count - Enum.count(diff.leaves[agentId].metas)
        devicesOnline = if devicesOnline < 0, do: 0, else: devicesOnline
        {devicesOnline > 0, devicesOnline}
      else
        {false, 0}
      end
    end
  end

  def nice_print_status(online, count) do
    assigns = %{}
    if not online do
      ~H"<p class='inline-block text-red-500'>Offline</p>"
    else
      if count == 1 do
        ~H"<p class='inline-block text-green-500'>Online</p>"
      else
        ~H"""
        <p class='inline-block text-orange-400'>Online (<%= count %>)</p>
        """
      end
    end
  end
end
