defmodule TictactoeWeb.Plugs.InitializePlayerId do
  @moduledoc """
  Plug to initialize a persistent player_id in the session.

  This ensures that each user gets a unique player_id that persists
  across browser refreshes and navigation within the same session.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, "player_id") do
      nil ->
        player_id = generate_player_id()
        put_session(conn, "player_id", player_id)

      _existing_player_id ->
        conn
    end
  end

  defp generate_player_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16()
  end
end
