defmodule TicTacToe.GameSupervisor do
  use DynamicSupervisor

  @moduledoc """
  Dynamic supervisor for managing individual TicTacToe game processes.
  Each game is a separate GenServer process supervised by this supervisor.
  """

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start a new game process under this supervisor.
  """
  def start_game(key) do
    child_spec = {TicTacToe.MultiplayerGame, key}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Terminate a game process.
  """
  def terminate_game(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  @doc """
  Get all supervised game processes.
  """
  def which_children do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
