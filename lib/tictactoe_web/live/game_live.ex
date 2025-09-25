defmodule TictactoeWeb.GameLive do
  use TictactoeWeb, :live_view

  def mount(%{"key" => key}, _session, socket) do
    # Generate a unique player ID for this session
    player_id = generate_player_id()

    # Subscribe to game updates
    Phoenix.PubSub.subscribe(Tictactoe.PubSub, "game:#{key}")

    # Try to join the game
    case TicTacToe.MultiplayerGame.join_player(key, player_id) do
      {:ok, player_symbol} ->
        # Get current game state
        case TicTacToe.MultiplayerGame.get_game_state(key) do
          {:ok, game_state} ->
            socket =
              socket
              |> assign(:page_title, "TicTacToe - #{key}")
              |> assign(:key, key)
              |> assign(:player_id, player_id)
              |> assign(:player_symbol, player_symbol)
              |> assign_game_state(game_state)

            {:ok, socket}

          {:error, reason} ->
            socket =
              socket
              |> put_flash(:error, "Failed to get game state: #{reason}")
              |> push_navigate(to: "/")

            {:ok, socket}
        end

      {:error, "Game is full"} ->
        socket =
          socket
          |> put_flash(:error, "This game is full. Please try creating a new game.")
          |> push_navigate(to: "/")

        {:ok, socket}

      {:error, reason} ->
        socket =
          socket
          |> put_flash(:error, "Failed to join game: #{reason}")
          |> push_navigate(to: "/")

        {:ok, socket}
    end
  end

  def handle_info({:game_updated, game_state}, socket) do
    {:noreply, assign_game_state(socket, game_state)}
  end

  def handle_event("make_move", %{"position" => position}, socket) do
    position = String.to_integer(position)

    case TicTacToe.MultiplayerGame.make_move(
           socket.assigns.key,
           socket.assigns.player_id,
           position
         ) do
      {:ok, _new_board} ->
        # State will be updated via PubSub message
        {:noreply, socket}

      {:error, message} ->
        socket = put_flash(socket, :error, message)
        {:noreply, socket}
    end
  end

  def handle_event("reset_game", _params, socket) do
    case TicTacToe.MultiplayerGame.reset_game(socket.assigns.key) do
      :ok ->
        socket = put_flash(socket, :info, "Game reset!")
        {:noreply, socket}

      {:error, reason} ->
        socket = put_flash(socket, :error, "Failed to reset game: #{reason}")
        {:noreply, socket}
    end
  end

  def handle_event("leave_game", _params, socket) do
    TicTacToe.MultiplayerGame.leave_game(socket.assigns.key, socket.assigns.player_id)
    {:noreply, push_navigate(socket, to: "/")}
  end

  def handle_event("copy_key", _params, socket) do
    socket = put_flash(socket, :info, "Game key copied to clipboard!")
    {:noreply, socket}
  end

  # Helper functions
  defp assign_game_state(socket, game_state) do
    socket
    |> assign(:game_board, game_state.game_board)
    |> assign(:current_player, game_state.current_player)
    |> assign(:winner, game_state.winner)
    |> assign(:game_over, game_state.winner != :none)
    |> assign(:game_started, game_state.game_started)
    |> assign(:player_count, game_state.player_count)
    |> assign(:players, game_state.players)
  end

  defp generate_player_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16()
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
    <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-8 px-4">
      <div class="max-w-4xl mx-auto">
        <!-- Header with Game Key -->
        <div class="text-center mb-8">
          <div class="flex items-center justify-between mb-4">
            <button
              phx-click="leave_game"
              class="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition-colors"
            >
              ← Leave Game
            </button>

            <div class="flex-1">
              <h1 class="text-4xl md:text-6xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-purple-600 mb-2">
                Tic Tac Toe
              </h1>
            </div>

            <div class="w-24"></div>
            <!-- Spacer for centering -->
          </div>
          
    <!-- Game Key Display -->
          <div class="bg-white rounded-xl shadow-lg p-4 mb-6 inline-block">
            <div class="text-sm text-gray-600 mb-1">Game Key:</div>
            <div class="flex items-center gap-2">
              <span class="text-3xl font-mono font-bold text-blue-600 tracking-widest">{@key}</span>
              <button
                phx-click="copy_key"
                onclick={"navigator.clipboard.writeText('#{@key}')"}
                class="ml-2 p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                title="Copy to clipboard"
              >
                📋
              </button>
            </div>
            <div class="text-xs text-gray-500 mt-1">Share this key with your friend!</div>
          </div>
        </div>
        
    <!-- Game Status -->
        <div class="text-center mb-8">
          <%= cond do %>
            <% not @game_started -> %>
              <div class="bg-yellow-50 border border-yellow-200 rounded-xl p-6 mb-6">
                <div class="text-2xl mb-2">⏳ Waiting for Player...</div>
                <div class="text-gray-600 mb-4">
                  Players: {@player_count}/2 | You are: {player_name(@player_symbol)}
                </div>
                <div class="text-sm text-gray-500">
                  Share the game key <strong>{@key}</strong> with a friend to start playing!
                </div>
              </div>
            <% @game_over -> %>
              <div class="mb-6">
                <%= cond do %>
                  <% @winner == :draw -> %>
                    <div class="text-3xl font-semibold text-amber-600 mb-2">It's a Draw! 🤝</div>
                  <% @winner in [:X, :O] -> %>
                    <div class="text-3xl font-semibold text-green-600 mb-2">
                      Player {player_name(@winner)} Wins! 🎉
                    </div>
                    <%= if @winner == @player_symbol do %>
                      <div class="text-xl text-green-500 font-medium">You won! 🏆</div>
                    <% else %>
                      <div class="text-xl text-red-500 font-medium">You lost! 😔</div>
                    <% end %>
                  <% true -> %>
                    <div></div>
                <% end %>
              </div>
            <% true -> %>
              <div class="text-2xl font-semibold text-gray-700 mb-6">
                <div class="mb-2">
                  Current Turn:
                  <span class={[
                    "px-4 py-2 rounded-full text-white font-bold text-lg ml-2",
                    @current_player == :X && "bg-blue-500",
                    @current_player == :O && "bg-red-500"
                  ]}>
                    {player_name(@current_player)}
                  </span>
                </div>
                <div class="text-lg">
                  You are: <span class="font-bold">{player_name(@player_symbol)}</span>
                  <%= if @current_player == @player_symbol do %>
                    <span class="text-green-600 ml-2">← Your turn!</span>
                  <% else %>
                    <span class="text-gray-500 ml-2">← Wait for opponent</span>
                  <% end %>
                </div>
              </div>
          <% end %>
        </div>
        
    <!-- Game Board -->
        <div class="bg-white rounded-2xl shadow-2xl p-8 mb-8 max-w-md mx-auto">
          <div class="grid grid-cols-3 gap-3">
            <%= for {cell, index} <- Enum.with_index(@game_board) do %>
              <button
                phx-click="make_move"
                phx-value-position={index}
                disabled={
                  not @game_started or @game_over or cell != :_ or @current_player != @player_symbol
                }
                class={[
                  "aspect-square text-5xl font-bold rounded-xl transition-all duration-200 border-2 flex items-center justify-center min-h-20",
                  cell == :_ and @game_started and not @game_over and
                    @current_player == @player_symbol &&
                    "bg-gray-50 border-gray-200 hover:bg-blue-50 hover:border-blue-300 hover:shadow-md cursor-pointer hover:scale-105",
                  cell == :_ and
                    (not @game_started or @game_over or @current_player != @player_symbol) &&
                    "bg-gray-100 border-gray-200 cursor-not-allowed",
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
        
    <!-- Game Controls -->
        <div class="text-center space-y-4">
          <%= if @game_started do %>
            <button
              phx-click="reset_game"
              class="px-8 py-3 bg-gradient-to-r from-purple-500 to-pink-500 text-white font-semibold rounded-xl shadow-lg hover:from-purple-600 hover:to-pink-600 hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200"
            >
              🔄 New Game
            </button>
          <% end %>

          <div class="text-sm text-gray-600 space-y-2">
            <%= if not @game_started do %>
              <p>Waiting for another player to join with key: <strong>{@key}</strong></p>
            <% else %>
              <p>Playing against your opponent in real-time!</p>
            <% end %>
            <p class="text-xs text-gray-500">
              Game updates happen automatically - no need to refresh!
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
