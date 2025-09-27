defmodule TictactoeWeb.LobbyLive do
  use TictactoeWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "TicTacToe Lobby")
      |> assign(:join_key, "")
      |> assign(:loading, false)

    {:ok, socket}
  end

  def handle_event("create_game", _params, socket) do
    socket = assign(socket, :loading, true)
    random_key = generate_random_key()

    case TicTacToe.GameSupervisor.start_game(random_key) do
      {:ok, _pid} ->
        {:noreply, push_navigate(socket, to: "/game/#{random_key}")}

      {:error, reason} ->
        socket =
          socket
          |> assign(:loading, false)
          |> put_flash(:error, "Failed to create game: #{reason}")

        {:noreply, socket}
    end
  end

  def handle_event("join_game", %{"join_key" => join_key}, socket) do
    key = String.upcase(String.trim(join_key))

    cond do
      String.length(key) != 4 ->
        socket = put_flash(socket, :error, "Game key must be exactly 4 letters")
        {:noreply, socket}

      not String.match?(key, ~r/^[A-Z]{4}$/) ->
        socket = put_flash(socket, :error, "Game key must contain only letters")
        {:noreply, socket}

      true ->
        socket = assign(socket, :loading, true)

        case TicTacToe.GameSupervisor.start_game(key) do
          {:error, {:already_started, _pid}} ->
            # We expect the game to be already started
            {:noreply, push_navigate(socket, to: "/game/#{key}")}

          {:error, :game_not_found} ->
            socket =
              socket
              |> assign(:loading, false)
              |> put_flash(:error, "Game not found. Please check the key and try again.")

            {:noreply, socket}

          {:error, :game_full} ->
            socket =
              socket
              |> assign(:loading, false)
              |> put_flash(:error, "Game is full. This game already has 2 players.")

            {:noreply, socket}

          {:error, reason} ->
            socket =
              socket
              |> assign(:loading, false)
              |> put_flash(:error, "Failed to join game: #{reason}")

            {:noreply, socket}
        end
    end
  end

  def handle_event("update_join_key", %{"join_key" => join_key}, socket) do
    # Limit to 4 characters and convert to uppercase
    cleaned_key =
      join_key
      |> String.upcase()
      |> String.replace(~r/[^A-Z]/, "")
      |> String.slice(0, 4)

    {:noreply, assign(socket, :join_key, cleaned_key)}
  end

  defp generate_random_key() do
    # Generate a random 4-letter key using uppercase letters
    letters = ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    1..4
    |> Enum.map(fn _ -> Enum.random(letters) end)
    |> List.to_string()
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-indigo-100 flex items-center justify-center px-4">
        <div class="max-w-md w-full space-y-8">
          <!-- Header -->
          <div class="text-center">
            <h1 class="text-6xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-purple-600 to-blue-600 mb-4">
              🎮 TicTacToe
            </h1>
            <p class="text-xl text-gray-600 mb-8">
              Play with friends over the network!
            </p>
          </div>
          
    <!-- Game Options Card -->
          <div class="bg-white rounded-2xl shadow-2xl p-8 space-y-6">
            <!-- Create New Game -->
            <div class="text-center">
              <h2 class="text-2xl font-semibold text-gray-800 mb-4">Start a New Game</h2>
              <p class="text-gray-600 mb-6">
                Create a new game and share the key with your friend
              </p>

              <button
                phx-click="create_game"
                disabled={@loading}
                class={[
                  "w-full px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-200 transform",
                  @loading && "opacity-50 cursor-not-allowed",
                  not @loading &&
                    "bg-gradient-to-r from-green-500 to-emerald-500 text-white shadow-lg hover:from-green-600 hover:to-emerald-600 hover:shadow-xl hover:-translate-y-0.5"
                ]}
              >
                <%= if @loading do %>
                  <div class="flex items-center justify-center">
                    <svg
                      class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        class="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        stroke-width="4"
                      >
                      </circle>
                      <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      >
                      </path>
                    </svg>
                    Creating Game...
                  </div>
                <% else %>
                  🚀 Create New Game
                <% end %>
              </button>
            </div>
            
    <!-- Divider -->
            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-gray-300"></div>
              </div>
              <div class="relative flex justify-center text-sm">
                <span class="px-4 bg-white text-gray-500 font-medium">or</span>
              </div>
            </div>
            
    <!-- Join Existing Game -->
            <div class="text-center">
              <h2 class="text-2xl font-semibold text-gray-800 mb-4">Join a Game</h2>
              <p class="text-gray-600 mb-6">
                Enter the 4-letter game key to join your friend's game
              </p>

              <.form for={%{}} phx-submit="join_game" id="join-game-form" class="space-y-4">
                <div>
                  <label for="join_key" class="block text-sm font-medium text-gray-700 mb-2">
                    Game Key
                  </label>
                  <.input
                    type="text"
                    id="join_key"
                    name="join_key"
                    value={@join_key}
                    phx-change="update_join_key"
                    placeholder="ABCD"
                    maxlength="4"
                    class="w-full px-4 py-3 text-center text-2xl font-mono font-bold uppercase border-2 border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent tracking-widest"
                    autocomplete="off"
                  />
                  <p class="text-sm text-gray-500 mt-2">
                    Enter exactly 4 letters (e.g., PLAY, GAME, WXYZ)
                  </p>
                </div>

                <button
                  type="submit"
                  disabled={@loading or String.length(@join_key) != 4}
                  class={[
                    "w-full px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-200 transform",
                    (@loading or String.length(@join_key) != 4) &&
                      "opacity-50 cursor-not-allowed bg-gray-400 text-white",
                    not @loading and String.length(@join_key) == 4 &&
                      "bg-gradient-to-r from-blue-500 to-indigo-500 text-white shadow-lg hover:from-blue-600 hover:to-indigo-600 hover:shadow-xl hover:-translate-y-0.5"
                  ]}
                >
                  <%= if @loading do %>
                    <div class="flex items-center justify-center">
                      <svg
                        class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <circle
                          class="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          stroke-width="4"
                        >
                        </circle>
                        <path
                          class="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        >
                        </path>
                      </svg>
                      Joining Game...
                    </div>
                  <% else %>
                    🎯 Join Game
                  <% end %>
                </button>
              </.form>
            </div>
          </div>
          
    <!-- Instructions -->
          <div class="text-center text-gray-600">
            <div class="bg-blue-50 rounded-lg p-4 border border-blue-200">
              <h3 class="font-semibold text-blue-800 mb-2">How it works:</h3>
              <div class="text-sm text-blue-700 space-y-1">
                <p>🎮 <strong>Create:</strong> Start a new game and get a 4-letter key</p>
                <p>📤 <strong>Share:</strong> Send the key to your friend</p>
                <p>🎯 <strong>Play:</strong> Your friend joins using the key</p>
                <p>⚡ <strong>Real-time:</strong> See moves instantly!</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
