defmodule TictactoeWeb.PageControllerTest do
  use TictactoeWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "TicTacToe"
  end
end
