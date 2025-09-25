defmodule TictactoeWeb.GameLive do
  use TictactoeWeb, :live_view

  def mount(_params, _session, socket) do
    game_state = TicTacToe.Game.get_game_state()

    socket =
      socket
      |> assign(:page_title, "Tic Tac Toe")
      |> assign(:game_board, game_state.game_board)
      |> assign(:current_player, game_state.current_player)
      |> assign(:winner, game_state.winner)
      |> assign(:game_over, game_state.winner != :none)

    {:ok, socket}
  end

  def handle_event("make_move", %{"position" => position}, socket) do
    position = String.to_integer(position)

    case TicTacToe.Game.make_move(socket.assigns.current_player, position) do
      {:ok, _new_board} ->
        # Refresh the game state after successful move
        game_state = TicTacToe.Game.get_game_state()

        socket =
          socket
          |> assign(:game_board, game_state.game_board)
          |> assign(:current_player, game_state.current_player)
          |> assign(:winner, game_state.winner)
          |> assign(:game_over, game_state.winner != :none)

        {:noreply, socket}

      {:error, message} ->
        socket = put_flash(socket, :error, message)
        {:noreply, socket}
    end
  end

  def handle_event("reset_game", _params, socket) do
    # Reset the game state
    TicTacToe.Game.reset_game()

    game_state = TicTacToe.Game.get_game_state()

    socket =
      socket
      |> assign(:game_board, game_state.game_board)
      |> assign(:current_player, game_state.current_player)
      |> assign(:winner, game_state.winner)
      |> assign(:game_over, game_state.winner != :none)
      |> put_flash(:info, "New game started!")

    {:noreply, socket}
  end

  # Helper function to display player marks with emojis
  defp player_display(:X), do: "❌"
  defp player_display(:O), do: "⭕"
  defp player_display(_), do: ""

  # Helper function to get player name with emoji
  defp player_name(:X), do: "❌ X"
  defp player_name(:O), do: "⭕ O"

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-12 px-4">
      <Layouts.flash_group flash={@flash} />
      <div class="max-w-2xl mx-auto">
        <div class="text-center mb-8">
          <h1 class="text-6xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-purple-600 mb-4">
            Tic Tac Toe
          </h1>

          <%= if @game_over do %>
            <div class="mb-6">
              <%= cond do %>
                <% @winner == :draw -> %>
                  <div class="text-3xl font-semibold text-amber-600 mb-2">It's a Draw! 🤝</div>
                <% @winner in [:X, :O] -> %>
                  <div class="text-3xl font-semibold text-green-600 mb-2">
                    Player {player_name(@winner)} Wins! 🎉
                  </div>
                <% true -> %>
                  <div></div>
              <% end %>
            </div>
          <% else %>
            <div class="text-2xl font-semibold text-gray-700 mb-6">
              Current Player:
              <span class={[
                "px-4 py-2 rounded-full text-white font-bold text-lg",
                @current_player == :X && "bg-blue-500",
                @current_player == :O && "bg-red-500"
              ]}>
                {player_name(@current_player)}
              </span>
            </div>
          <% end %>
        </div>

        <div class="bg-white rounded-2xl shadow-2xl p-8 mb-8">
          <div class="grid grid-cols-3 gap-3 max-w-md mx-auto">
            <%= for {cell, index} <- Enum.with_index(@game_board) do %>
              <button
                phx-click="make_move"
                phx-value-position={index}
                disabled={@game_over or cell != :_}
                class={[
                  "aspect-square text-5xl font-bold rounded-xl transition-all duration-200 border-2 flex items-center justify-center min-h-20",
                  cell == :_ and not @game_over &&
                    "bg-gray-50 border-gray-200 hover:bg-blue-50 hover:border-blue-300 hover:shadow-md cursor-pointer hover:scale-105",
                  cell == :_ and @game_over && "bg-gray-100 border-gray-200 cursor-not-allowed",
                  cell == :X && "bg-blue-50 border-blue-300 shadow-md",
                  cell == :O && "bg-red-50 border-red-300 shadow-md",
                  cell != :_ && "cursor-not-allowed"
                ]}
              >
                <span class="select-none">
                  {player_display(cell)}
                </span>
              </button>
            <% end %>
          </div>
        </div>

        <div class="text-center">
          <button
            phx-click="reset_game"
            class="px-8 py-3 bg-gradient-to-r from-purple-500 to-pink-500 text-white font-semibold rounded-xl shadow-lg hover:from-purple-600 hover:to-pink-600 hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200"
          >
            New Game
          </button>
        </div>

        <div class="mt-8 text-center text-gray-600">
          <p class="text-sm">Click on any empty cell to make your move!</p>
        </div>
      </div>
    </div>
    """
  end
end
