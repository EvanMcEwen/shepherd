defmodule ShepherdWeb.HealthController do
  use ShepherdWeb, :controller

  alias Shepherd.Presence

  def index(conn, _params) do
    json(conn, %{
      status: "ok",
      online_devices: Presence.online_count()
    })
  end
end
