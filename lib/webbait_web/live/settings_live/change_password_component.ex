defmodule WebBaitWeb.SettingsLive.ChangePasswordComponent do
  use WebBaitWeb, :live_component
  alias WebBait.Accounts
  alias WebBait.Accounts.User

  def update(assigns, socket) do
    changeset = Accounts.change_user_password(%User{}, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  def render(assigns) do
    ~H"""
      <div class="flex flex-row gap-2 w-full h-full justify-center items-center">
        <.form
          let={f}
          for={@changeset}
          id="room-form"
          phx-target={@myself}
          phx-change="validate"
          class="flex flex-col w-1/2 gap-4 p-4 border-gray-500 border-2 rounded shadow shadow-gray-500"
          phx-submit="save">

          <div class="flex flex-col gap-2">
            <%= label f, :current_password %>
            <%= password_input f, :current_password, class: "text-black", required: true, value: input_value(f, :current_password) %>
            <%= error_tag f, :current_password %>
          </div>


          <div class="flex flex-col gap-2">
            <%= label f, :password %>
            <%= password_input f, :password, class: "text-black", required: true %>
            <%= error_tag f, :password %>
          </div>

          <div>
            <%= submit "Change password", phx_disable_with: "Changing...", class: "bg-sky-700 hover:bg-sky-900 transition duration-300 p-2 rounded w-full text-white" %>
          </div>
        </.form>
      </div>
    """
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.update_user_password(socket.assigns.current_user, user_params["current_password"], user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password changed.")
         |> push_redirect(to: Routes.settings_index_path(socket, :index))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
