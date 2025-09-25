defmodule TicTacToe.GameRegistry do
  use GenServer

  @moduledoc """
  Registry for managing multiple TicTacToe game instances.
  Each game is identified by a unique 4-letter key.
  """

  # Client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Creates a new game with a random 4-letter key.
  Returns {:ok, key} if successful, {:error, reason} if not.
  """
  def create_game() do
    GenServer.call(__MODULE__, :create_game)
  end

  @doc """
  Joins an existing game with the given key.
  Returns {:ok, game_pid} if successful, {:error, reason} if not.
  """
  def join_game(key) do
    GenServer.call(__MODULE__, {:join_game, key})
  end

  @doc """
  Gets the PID of a game by its key.
  Returns {:ok, pid} if found, {:error, :not_found} if not.
  """
  def get_game(key) do
    GenServer.call(__MODULE__, {:get_game, key})
  end

  @doc """
  Lists all active games with their keys and player counts.
  """
  def list_games() do
    GenServer.call(__MODULE__, :list_games)
  end

  @doc """
  Removes a game from the registry (called when game process terminates).
  """
  def remove_game(key) do
    GenServer.cast(__MODULE__, {:remove_game, key})
  end

  # Server Callbacks
  def init(_) do
    # Monitor game processes so we can clean up when they terminate
    Process.flag(:trap_exit, true)
    {:ok, %{}}
  end

  def handle_call(:create_game, _from, state) do
    key = generate_unique_key(state)

    case start_game_process(key) do
      {:ok, pid} ->
        # Monitor the game process
        Process.monitor(pid)
        new_state = Map.put(state, key, %{pid: pid, players: 1, created_at: DateTime.utc_now()})
        {:reply, {:ok, key}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:join_game, key}, _from, state) do
    case Map.get(state, key) do
      nil ->
        {:reply, {:error, :game_not_found}, state}

      %{pid: _pid, players: players} when players >= 2 ->
        {:reply, {:error, :game_full}, state}

      %{pid: pid, players: players} = game_info ->
        # Update player count
        updated_game = %{game_info | players: players + 1}
        new_state = Map.put(state, key, updated_game)
        {:reply, {:ok, pid}, new_state}
    end
  end

  def handle_call({:get_game, key}, _from, state) do
    case Map.get(state, key) do
      nil -> {:reply, {:error, :not_found}, state}
      %{pid: pid} -> {:reply, {:ok, pid}, state}
    end
  end

  def handle_call(:list_games, _from, state) do
    games =
      Enum.map(state, fn {key, %{players: players, created_at: created_at}} ->
        %{key: key, players: players, created_at: created_at}
      end)

    {:reply, games, state}
  end

  def handle_cast({:remove_game, key}, state) do
    {:noreply, Map.delete(state, key)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Find and remove the game that terminated
    key_to_remove =
      Enum.find_value(state, fn {key, %{pid: game_pid}} ->
        if game_pid == pid, do: key, else: nil
      end)

    new_state =
      if key_to_remove do
        Map.delete(state, key_to_remove)
      else
        state
      end

    {:noreply, new_state}
  end

  # Private helper functions
  defp generate_unique_key(state) do
    key = generate_random_key()

    if Map.has_key?(state, key) do
      generate_unique_key(state)
    else
      key
    end
  end

  defp generate_random_key() do
    # Generate a random 4-letter key using uppercase letters
    letters = ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    1..4
    |> Enum.map(fn _ -> Enum.random(letters) end)
    |> List.to_string()
  end

  defp start_game_process(key) do
    # Start a new game process under the DynamicSupervisor
    case DynamicSupervisor.start_child(
           TicTacToe.GameSupervisor,
           {TicTacToe.MultiplayerGame, key}
         ) do
      {:ok, pid} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end
end
