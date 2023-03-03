defmodule WebBait.Presence do
  use Phoenix.Presence,
    otp_app: :webbait,
    pubsub_server: WebBait.PubSub
end
