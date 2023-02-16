defmodule WebBait.Repo do
  use Ecto.Repo,
    otp_app: :webbait,
    adapter: Ecto.Adapters.MyXQL
end
