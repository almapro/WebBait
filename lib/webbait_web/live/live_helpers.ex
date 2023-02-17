defmodule WebBaitWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.main_index_path(@socket, :index)}>
        <.live_component
          module={WebBaitWeb.MainLive.FormComponent}
          id={@main.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={Routes.main_index_path(@socket, :index)}
          main: @main
        />
      </.modal>
  """
  def modal(assigns) do
    assigns = assign_new(assigns, :return_to, fn -> nil end)
    assigns = assign_new(assigns, :title, fn -> nil end)

    ~H"""
    <div id="modal" class="phx-modal fade-in" phx-remove={hide_modal()}>
      <div
        id="modal-content"
        class="phx-modal-content flex flex-col gap-2 rounded !border-transparent dark:bg-gray-700 fade-in-scale"
        phx-click-away={JS.dispatch("click", to: "#close")}
        phx-window-keydown={JS.dispatch("click", to: "#close")}
        phx-key="escape"
      >
        <div class="flex flex-row-reverse">
          <%= live_patch to: "#{if @return_to, do: @return_to, else: "/"}", id: "close", class: "flex h-8 w-8 p-2 rounded hover:bg-black/30", phx_click: hide_modal() do %>
            <i class="fa-solid fa-xmark m-auto"></i>
          <% end %>
          <%= if @title do %>
            <div class="h-8 grow text-lg font-bold"><%= @title %></div>
          <% end %>
        </div>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end
end
