defmodule WebBaitWeb.AgentLive.TheaterModeComponent do
  use WebBaitWeb, :live_component

  @impl true
  def mount(socket) do
    {
      :ok,
      socket
      |> allow_upload(:file, accept: ~w(.jpg .png .jpeg), max_entries: 2)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form
      id="upload-form"
      class="flex flex-col justify-start gap-2"
      phx-target={@myself}
      phx-change="validate"
      phx-submit="save">
      <div class="relative bg-white rounded dark:bg-gray-700">
        <div class="p-2 flex flex-col gap-2" phx-drop-target={@uploads.file.ref}>
          <%= live_file_input @uploads.file %>
          <div class="flex flex-row gap-2 overflow-y-auto scrollbar-hide">
            <%= for entry <- @uploads.file.entries do %>
              <div class="relative flex flex-col gap-2 p-2 border-2 border-gray-200 rounded w-1/3 h-1/4">
                <div
                  phx-click="cancel-entry"
                  phx-value-ref={entry.ref}
                  phx-target={@myself}
                  class="cursor-pointer absolute top-2.5 right-2.5 flex rounded-full w-8 h-8 bg-red-500 transition duration-300 hover:bg-red-600">
                  <i class="fa-solid fa-xmark m-auto"></i>
                </div>
                <%= live_img_preview entry %>
                  <div class="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-500">
                    <div class="bg-blue-600 h-5 rounded-full" style={"width: #{entry.progress}%"}></div>
                  </div>
                </div>
              <% end %>
            </div>
            <%= for {_ref, msg} <- @uploads.file.errors do %>
              <p><%= pritty_error(msg) %></p>
            <% end %>
          </div>
          <div class="flex items-center p-2 space-x-2 border-t border-gray-200 rounded-b dark:border-gray-600">
            <%= submit "Send command", class: "p-2 w-fit rounded text-white bg-blue-700 hover:bg-blue-800", phx_disable_with: "Sending..." %>
          </div>
        </div>
      </form>
    """
  end

  @impl true
  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        dest = Path.join("priv/static/uploads", "#{entry.uuid}.#{ext(entry.client_type)}")
        File.cp!(path, dest)
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)

    IO.inspect(uploaded_files)
    {:noreply, socket}
  end

  def handle_event("cancel-entry", %{"ref" => ref}, socket) do
    {
      :noreply,
      socket
      |> cancel_upload(:file, ref)
      # |> push_event("validated", %{})
    }
  end

  def ext(client_type) do
    [ext | _] = MIME.extensions(client_type)
    ext
  end

  def pritty_error(:too_many_files), do: "You have selected too many files"
  def pritty_error(:too_large), do: "Too large"
  def pritty_error(:not_accepted), do: "You have selected an unacceptable file type"
end
