defmodule WebBaitWeb.UsersLive.Users do
  use WebBaitWeb, :live_view
  alias WebBait.Repo
  alias WebBait.Accounts.User
  alias WebBait.Accounts
  alias WebBaitWeb.UsersLive.UsersNewComponent
  alias WebBaitWeb.UsersLive.UsersDeleteComponent

  @impl true
  def mount(_params, %{"user_token" => token} = _session, socket) do
    {:ok,
     socket
     |> assign(:current_user, Accounts.get_user_by_session_token(token))
     |> assign(:users, Repo.all(User))}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex flex-col gap-2 px-2">
        <div class="flex flex-row-reverse	">
          <%= live_patch to: Routes.users_users_path(@socket, :new), class: "inline-flex items-center justify-center w-1/2 px-3 py-2 text-sm font-medium text-center text-white rounded bg-green-700 hover:bg-green-800 sm:w-auto dark:bg-green-600 dark:hover:bg-green-700 gap-2" do %>
            <i class="fa-solid fa-plus"></i>
            Add user
          <% end %>
        </div>
        <div class="flex flex-col h-full">
          <div class="overflow-x-auto">
            <div class="inline-block min-w-full align-middle">
              <div class="overflow-hidden shadow">
                <table class="min-w-full divide-y divide-gray-200 table-fixed dark:divide-gray-600">
                  <thead class="bg-gray-100 dark:bg-gray-700">
                    <tr>
                      <th scope="col" class="p-4">#</th>
                      <th scope="col" class="p-4 text-xs font-medium text-left text-gray-500 uppercase dark:text-gray-400">Name</th>
                      <th scope="col" class="p-4 text-xs font-medium text-left text-gray-500 uppercase dark:text-gray-400">Username</th>
                      <th scope="col" class="p-4 text-xs font-medium text-left text-gray-500 uppercase dark:text-gray-400">Email</th>
                      <th scope="col" class="p-4 text-xs font-medium text-left text-gray-500 uppercase dark:text-gray-400">Actions</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200 dark:bg-gray-800 dark:divide-gray-700">
                    <%= for user <- @users do %>
                      <tr class="hover:bg-gray-100 dark:hover:bg-gray-700">
                        <td class="w-4 p-4"><%= user.id %></td>
                        <td class="flex items-center p-4 mr-12 space-x-6 whitespace-nowrap">
                          <div class="flex bg-gray-400 text-white dark:bg-gray-500 w-10 h-10 rounded-full"><b class="m-auto"><%= String.upcase("#{String.at(user.firstName, 0)}#{String.at("#{user.lastName}", 0)}") %></b></div>
                          <div class="text-sm font-normal text-gray-500 dark:text-gray-400">
                            <div class="text-base font-semibold text-gray-900 dark:text-white"><%= "#{user.firstName} #{user.lastName}" %></div>
                          </div>
                        </td>
                        <td class="p-4 space-x-2 whitespace-nowrap">
                            <div class="text-sm font-normal text-gray-500 dark:text-gray-400"><%= user.username %></div>
                          </td>
                        <td class="p-4 space-x-2 whitespace-nowrap">
                            <div class="text-sm font-normal text-gray-500 dark:text-gray-400"><%= user.email %></div>
                          </td>
                          <td class="w-10 p-4 space-x-2 whitespace-nowrap">
                            <%= if (user.username == "admin") do %>
                            <button disabled class="cursor-not-allowed bg-gray-500 inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white rounded gap-2">
                            <i class="fa-solid fa-trash"></i>
                            Delete user
                            </button>
                              <% else %>
                            <%= live_patch to: Routes.users_users_path(@socket, :delete, user.id), class: "bg-red-600 hover:bg-red-800 inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white rounded gap-2" do %>
                            <i class="fa-solid fa-trash"></i>
                            Delete user
                            <% end %>
                          <% end %>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
        <%= if (@live_action == :new) do %>
          <.live_component module={UsersNewComponent} id={:new} current_user={@current_user} />
        <% end %>
        <%= if (@live_action == :delete) do %>
          <.live_component module={UsersDeleteComponent} id={@user_to_delete.id} user_to_delete={@user_to_delete} current_user={@current_user} />
        <% end %>
      </div>
    """
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    if socket.assigns.current_user.type == :admin do
      socket
      |> assign(:page_title, "Users")
    else
      socket
      |> put_flash(:error, "Forbidden!")
      |> push_redirect(to: Routes.main_index_path(socket, :index))
    end
  end

  defp apply_action(socket, :new, _params) do
    if socket.assigns.current_user.type == :admin do
      socket
      |> assign(:page_title, "Add a user")
    else
      socket
      |> put_flash(:error, "Forbidden!")
      |> push_redirect(to: Routes.main_index_path(socket, :index))
    end
  end

  defp apply_action(socket, :delete, %{"id" => user_id} = _params) do
    my_username = socket.assigns.current_user.username
    user = Accounts.get_user!(user_id)

    if socket.assigns.current_user.type == :admin do
      case user.username do
        "admin" ->
          socket
          |> put_flash(:error, "Admin account cannot be deleted!")
          |> push_redirect(to: Routes.users_users_path(socket, :index))

        ^my_username ->
          socket
          |> put_flash(:error, "Cannot delete yourself!")
          |> push_redirect(to: Routes.users_users_path(socket, :index))

        _ ->
          socket
          |> assign(:user_to_delete, user)
          |> assign(:page_title, "Delete user: #{user.username}")
      end
    else
      socket
      |> put_flash(:error, "Forbidden!")
      |> push_redirect(to: Routes.main_index_path(socket, :index))
    end
  end
end

