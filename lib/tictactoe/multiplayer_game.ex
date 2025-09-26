defmodule TicTacToe.MultiplayerGame do
  use GenServer

  @moduledoc """
  A multiplayer TicTacToe game that supports exactly 2 players.
  Each game instance is identified by a unique key and uses PubSub
  for real-time updates to all connected clients.
  """

  # Client API
  def start_link(key) do
    GenServer.start_link(
      __MODULE__,
      %{
        key: key,
        game_board: [:_, :_, :_, :_, :_, :_, :_, :_, :_],
        current_player: :X,
        winner: :none,
        # %{player_id => :X or :O}
        players: %{},
        player_count: 0,
        game_started: false
      },
      name: via_tuple(key)
    )
  end

  def join_player(key, player_id) do
    GenServer.call(via_tuple(key), {:join_player, player_id})
  end

  def make_move(key, player_id, position) do
    GenServer.call(via_tuple(key), {:make_move, player_id, position})
  end

  def get_game_state(key) do
    GenServer.call(via_tuple(key), :get_game_state)
  end

  def reset_game(key) do
    GenServer.call(via_tuple(key), :reset_game)
  end

  def leave_game(key, player_id) do
    GenServer.call(via_tuple(key), {:leave_game, player_id})
  end

  # Helper to create a via_tuple for registry lookups
  defp via_tuple(name) do
    {:via, Registry, {TicTacToe.Registry, name}}
  end

  # Server Callbacks
  def init(initial_state) do
    # Register this process termination with the registry
    # Process.flag(:trap_exit, true)
    {:ok, initial_state}
  end

  def handle_call(:get_game_state, _from, state) do
    {:reply, {:ok, format_state_for_client(state)}, state}
  end

  def handle_call({:join_player, player_id}, _from, state) do
    cond do
      Map.has_key?(state.players, player_id) ->
        # Player already in game, just return their assignment
        player_symbol = state.players[player_id]
        {:reply, {:ok, player_symbol}, state}

      state.player_count >= 2 ->
        {:reply, {:error, "Game is full"}, state}

      true ->
        # Assign player symbol based on join order
        player_symbol =
          cond do
            state.player_count == 0 ->
              :X

            true ->
              # Take the symbol that is not already taken
              ([:X, :O] -- Map.values(state.players)) |> hd()
          end

        new_state = %{
          state
          | players: Map.put(state.players, player_id, player_symbol),
            player_count: state.player_count + 1,
            game_started: state.player_count + 1 == 2
        }

        broadcast_state_update(new_state)
        {:reply, {:ok, player_symbol}, new_state}
    end
  end

  def handle_call({:leave_game, player_id}, _from, state) do
    if Map.has_key?(state.players, player_id) do
      new_state = %{
        state
        | players: Map.delete(state.players, player_id),
          player_count: state.player_count - 1,
          game_started: false
      }

      broadcast_state_update(new_state)
      {:reply, :ok, new_state}
    else
      {:reply, {:error, "Player not in game"}, state}
    end
  end

  def handle_call({:make_move, player_symbol, position}, _from, state) do
    cond do
      not state.game_started ->
        {:reply, {:error, "Game not started - waiting for second player"}, state}

      state.winner in [:X, :O, :draw] ->
        {:reply, {:error, "Game over, winner: #{state.winner}"}, state}

      player_symbol != state.current_player ->
        {:reply, {:error, "Not your turn"}, state}

      not valid_move?(state, position) ->
        {:reply, {:error, "Invalid move"}, state}

      true ->
        # Valid move - update game state
        new_game_board = List.replace_at(state.game_board, position, player_symbol)
        winner = check_winner(new_game_board)
        next_player = if player_symbol == :X, do: :O, else: :X

        new_state = %{
          state
          | game_board: new_game_board,
            current_player: next_player,
            winner: winner
        }

        broadcast_state_update(new_state)
        {:reply, {:ok, new_game_board}, new_state}
    end
  end

  def handle_call(:reset_game, _from, state) do
    new_state = %{
      state
      | game_board: [:_, :_, :_, :_, :_, :_, :_, :_, :_],
        current_player: :X,
        winner: :none
    }

    broadcast_state_update(new_state)
    {:reply, :ok, new_state}
  end

  # Private helper functions

  defp valid_move?(state, position) do
    position >= 0 and position < 9 and Enum.at(state.game_board, position) == :_
  end

  defp check_winner(game_board) do
    winning_combinations = [
      # Horizontal
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      # Vertical
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      # Diagonal
      [0, 4, 8],
      [2, 4, 6]
    ]

    winner = Enum.find_value(winning_combinations, &check_combination(game_board, &1))

    cond do
      winner -> winner
      is_board_full?(game_board) -> :draw
      true -> :none
    end
  end

  defp check_combination(game_board, combination) do
    [a, b, c] = Enum.map(combination, fn i -> Enum.at(game_board, i) end)

    if a != :_ and a == b and b == c do
      a
    else
      nil
    end
  end

  defp is_board_full?(game_board) do
    Enum.all?(game_board, &(&1 != :_))
  end

  defp broadcast_state_update(state) do
    Phoenix.PubSub.broadcast(
      Tictactoe.PubSub,
      "game:#{state.key}",
      {:game_updated, format_state_for_client(state)}
    )
  end

  defp format_state_for_client(state) do
    %{
      key: state.key,
      game_board: state.game_board,
      current_player: state.current_player,
      winner: state.winner,
      players: state.players,
      player_count: state.player_count,
      game_started: state.game_started
    }
  end
end
