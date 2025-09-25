defmodule TicTacToe.Game do
  use GenServer

  # Client API
  def start_link(_) do
    GenServer.start_link(
      __MODULE__,
      %{
        game_board: [:_, :_, :_, :_, :_, :_, :_, :_, :_],
        current_player: :X,
        winner: :none
      },
      name: __MODULE__
    )
  end

  def make_move(player, position) do
    GenServer.call(__MODULE__, {:make_move, player, position})
  end

  def get_game_state() do
    GenServer.call(__MODULE__, :get_game_state)
  end

  # Server Callbacks
  def init(initial_state) do
    {:ok, initial_state}
  end

  def handle_call(:get_game_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:make_move, player, position}, _from, state) do
    if state.winner in [:X, :O, :draw] do
      {:reply, {:error, "Game over, winner: #{state.winner}"}, state}
    else
      case current_player?(state, player) && valid_move?(state, position) do
        true ->
          new_game_board = List.replace_at(state.game_board, position, player)
          winner = check_winner(new_game_board)
          next_player = if player == :X, do: :O, else: :X

          new_state = %{
            state
            | game_board: new_game_board,
              current_player: next_player,
              winner: winner
          }

          {:reply, {:ok, new_game_board}, new_state}

        false ->
          {:reply, {:error, "Invalid move"}, state}
      end
    end
  end

  # Helper Functions
  defp valid_move?(state, position) do
    position >= 0 and position < 9 and Enum.at(state.game_board, position) == :_
  end

  defp current_player?(state, player) do
    state.current_player == player
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
end
