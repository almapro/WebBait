defmodule WebBaitWeb.SettingsLive.Index do
  use WebBaitWeb, :live_view
  alias WebBait.Accounts

  @impl true
  def mount(_params, %{ "user_token" => token } = _session, socket) do
    {:ok, assign(socket, :current_user, Accounts.get_user_by_session_token(token))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Settings")
  end
end
