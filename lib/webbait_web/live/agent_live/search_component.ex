defmodule WebbaitWeb.AgentLive.SearchComponent do
  use WebBaitWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-1 rounded border border-gray-400 hover:border-gray-500 dark:border-gray-700 dark:bg-gray-700/30 dark:hover:border-gray-600">
      <i class="fa-solid fa-search m-auto px-2"></i>
      <.form
        let={f}
        id="search"
        for={:search}
        phx-target={@myself}
        phx-change="search">
        <%= text_input f, :search, class: "bg-transparent pl-0 border-0 focus:border-0 focus:outline-none focus:ring-0", placeholder: "Search..." %>
      </.form>
    </div>
    """
  end

  def handle_event("search", %{"search" => %{"search" => search}}, socket) do
    send(self(), {:search, %{"search" => search}})
    {:noreply, socket}
  end
end
