defmodule WebBaitWeb.UsersLive.UsersDeleteComponent do
  use WebBaitWeb, :live_component
  alias WebBait.Repo
  alias WebBait.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
    <.modal title={"Delete user: #{@user_to_delete.username}"} return_to={Routes.users_users_path(@socket, :index)}>
    <div class="p-6 text-center">
    <svg aria-hidden="true" class="mx-auto mb-4 text-gray-400 w-14 h-14 dark:text-gray-200" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
    <h3 class="mb-5 text-lg font-normal text-gray-500 dark:text-gray-400">Are you sure you want to delete this user?</h3>
    <%= live_patch "Cancel", to: Routes.users_users_path(@socket, :index), class: "text-gray-500 bg-white hover:bg-gray-100 focus:ring-4 focus:outline-none focus:ring-gray-200 rounded border border-gray-200 text-sm font-medium px-5 py-2.5 hover:text-gray-900 focus:z-10 dark:bg-gray-700 dark:text-gray-300 dark:border-gray-500 dark:hover:text-white dark:hover:bg-gray-600 dark:focus:ring-gray-600 mr-2" %>
    <button
    phx-click="delete"
    phx-value-id={@user_to_delete.id}
    phx-target={@myself}
    type="button"
    class="text-white bg-red-600 hover:bg-red-800 focus:ring-4 focus:outline-none focus:ring-red-300 dark:focus:ring-red-800 font-medium rounded text-sm inline-flex items-center px-5 py-2.5 text-center">
    Delete
    </button>
    </div>
    </.modal>
    </div>
    """
  end

  @impl true
  def handle_event("delete", %{"id" => user_id}, socket) do
    my_username = socket.assigns.current_user.username
    user = Accounts.get_user!(user_id)

    if socket.assigns.current_user.type == :admin do
      case user.username do
        "admin" ->
          {:noreply,
           socket
           |> put_flash(:error, "Admin account cannot be deleted!")
           |> push_redirect(to: Routes.users_users_path(socket, :index))}

        ^my_username ->
          {:noreply,
           socket
           |> put_flash(:error, "Cannot delete yourself!")
           |> push_redirect(to: Routes.users_users_path(socket, :index))}

        _ ->
          Repo.delete(user)

          {:noreply,
           socket
           |> put_flash(:success, "User deleted successfully.")
           |> push_redirect(to: Routes.users_users_path(socket, :index))}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "Forbidden!")
       |> push_redirect(to: Routes.main_index_path(socket, :index))}
    end
  end
end

