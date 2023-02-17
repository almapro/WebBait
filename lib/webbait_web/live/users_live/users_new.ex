defmodule WebBaitWeb.UsersLive.UsersNewComponent do
  use WebBaitWeb, :live_component
  alias WebBait.Accounts
  alias WebBait.Accounts.User

  @impl true
  def update(assigns, socket) do
    changeset = Accounts.change_user_registration(%User{}, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
    <.modal title="Add a user" return_to={Routes.users_users_path(@socket, :index)}>
    <.form
      let={f}
      for={@changeset}
      id="user-form"
      phx-change="validate"
      phx-target={@myself}
      class="flex flex-col gap-4 w-full m-auto"
      phx-submit="save">

    <div class="flex flex-row gap-2">
      <div class="flex flex-col gap-2 w-full">
        <%= label f, :username %>
        <%= text_input f, :username, class: "text-black", required: true %>
        <%= error_tag f, :username %>
      </div>
      <div class="flex flex-col gap-2 w-full">
        <%= label f, :type %>
        <%= select f, :type, [{ "Admin", :admin }, { "User", :user }], class: "text-black", required: true %>
        <%= error_tag f, :type %>
      </div>
    </div>

    <div class="flex flex-row gap-2">
      <div class="flex flex-col gap-2 w-full">
        <%= label f, :firstName %>
        <%= text_input f, :firstName, class: "text-black", required: true %>
        <%= error_tag f, :firstName %>
      </div>

      <div class="flex flex-col gap-2 w-full">
        <%= label f, :lastName %>
        <%= text_input f, :lastName, class: "text-black", required: false %>
        <%= error_tag f, :lastName %>
      </div>
    </div>

    <div class="flex flex-row gap-2">
      <div class="flex flex-col gap-2 w-full">
        <%= label f, :email %>
        <%= email_input f, :email, class: "text-black", required: false %>
        <%= error_tag f, :email %>
      </div>

      <div class="flex flex-col gap-2 w-full">
        <%= label f, :password %>
        <%= password_input f, :password, class: "text-black", required: true %>
        <%= error_tag f, :password %>
      </div>
    </div>

    <div class="w-full flex flex-row-reverse">
      <%= submit "Add", phx_disable_with: "Adding...", class: "text-white bg-green-700 hover:bg-green-800 dark:bg-green-600 dark:hover:bg-green-700 transition duration-300 p-2 rounded w-20" %>
    </div>
    </.form>
    </.modal>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:success, "User added successfully.")
         |> push_redirect(to: Routes.users_users_path(socket, :index))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
