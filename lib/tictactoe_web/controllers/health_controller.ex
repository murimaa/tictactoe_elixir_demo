defmodule TictactoeWeb.HealthController do
  use TictactoeWeb, :controller

  def health(conn, _params) do
    # Basic health check - can be extended with database checks, etc.
    health_status = %{
      status: "ok",
      timestamp: DateTime.utc_now(),
      version: Application.spec(:tictactoe, :vsn) |> to_string(),
      uptime: :erlang.statistics(:wall_clock) |> elem(0)
    }

    conn
    |> put_status(:ok)
    |> json(health_status)
  end
end
