# 🎮 TicTacToe Multiplayer - Phoenix LiveView Game

A real-time multiplayer TicTacToe game built with Phoenix LiveView, featuring networked gameplay, lobby system, and beautiful UI with instant game state synchronization.

## ✨ Features

### 🌐 **Multiplayer Networking**
- **Real-time gameplay** over the network using Phoenix PubSub
- **4-letter game keys** for easy game sharing (e.g., PLAY, GAME, WXYZ)
- **Automatic player assignment** - first player is X, second player is O
- **Instant game state sync** - see opponent moves immediately
- **Connection status tracking** - know when players join/leave

### 🎯 **Lobby System**
- **Start new games** with randomly generated game keys
- **Join existing games** using shared 4-letter keys
- **Game validation** - prevents joining full or non-existent games
- **Player management** - tracks up to 2 players per game

### 🎨 **Beautiful Interface**
- **Modern UI** with Tailwind CSS and gradient backgrounds
- **Visual feedback** with emoji icons (❌ for X, ⭕ for O)
- **Responsive design** that works on desktop and mobile
- **Real-time status updates** showing turns and game state
- **Smooth animations** and hover effects

### 🔧 **Technical Excellence**
- **Fault-tolerant architecture** with OTP supervision trees
- **Game isolation** - each game runs in its own GenServer process
- **Automatic cleanup** - games are removed when players disconnect
- **Comprehensive testing** with LiveView integration tests

## 🚀 Getting Started

### Prerequisites

- **Elixir 1.15+** with OTP 26+
- **Phoenix 1.7+** 
- **Node.js 18+** for asset compilation

### Installation

1. **Clone and setup the project:**
```bash
git clone <repository-url>
cd tictactoe
mix deps.get
cd assets && npm install && cd ..
```

2. **Start the Phoenix server:**
```bash
mix phx.server
```

3. **Open your browser:**
   - Navigate to [localhost:4000](http://localhost:4000)
   - You'll see the lobby with options to create or join games

## 🎲 How to Play

### Creating a New Game

1. **Click "🚀 Create New Game"** on the lobby page
2. **Share the 4-letter key** that appears (e.g., `PLAY`)
3. **Wait for a friend** to join using your key
4. **Start playing** once both players are connected!

### Joining an Existing Game

1. **Get the game key** from your friend (4 letters)
2. **Enter the key** in the "Join a Game" field
3. **Click "🎯 Join Game"** to connect
4. **Start playing** immediately!

### Game Rules

- **X always goes first** (the game creator)
- **O goes second** (the player who joins)
- **Take turns** clicking empty cells to place your mark
- **Win by getting 3 in a row** (horizontal, vertical, or diagonal)
- **Draw** if all 9 cells are filled without a winner
- **Reset anytime** with the "🔄 New Game" button

## 🏗️ Technical Architecture

### Core Components

#### **GameRegistry** (`TicTacToe.GameRegistry`)
- Manages active games with unique 4-letter keys
- Handles game creation and player joining
- Automatically cleans up terminated games
- Prevents duplicate keys and manages game capacity

#### **GameSupervisor** (`TicTacToe.GameSupervisor`) 
- Dynamic supervisor for game processes
- Each game runs as an isolated GenServer
- Fault-tolerant - crashed games don't affect others
- Supports unlimited concurrent games

#### **MultiplayerGame** (`TicTacToe.MultiplayerGame`)
- Individual game logic with multiplayer support
- Tracks 2 players with unique session IDs
- Validates moves and enforces turn order
- Broadcasts state changes via PubSub

#### **LobbyLive** (`TictactoeWeb.LobbyLive`)
- Landing page with create/join options
- Game key validation and formatting
- Error handling for invalid games
- Smooth navigation to active games

#### **GameLive** (`TictactoeWeb.GameLive`)
- Real-time game interface
- PubSub subscription for state updates
- Player-specific UI (your turn indicators)
- Game key display and clipboard copying

### Data Flow

```
1. Player A creates game → GameRegistry generates key → GameSupervisor starts process
2. Player B joins with key → GameRegistry validates → Both connect to same process
3. Players make moves → MultiplayerGame validates → PubSub broadcasts updates
4. Both players see changes instantly via LiveView updates
```

## 📁 Project Structure

```
tictactoe/
├── lib/
│   ├── tictactoe/
│   │   ├── application.ex          # App supervision tree
│   │   ├── game_registry.ex        # Game key management
│   │   ├── game_supervisor.ex      # Dynamic game supervision
│   │   ├── multiplayer_game.ex     # Core multiplayer logic
│   │   └── game.ex                 # Original single-player (unused)
│   └── tictactoe_web/
│       ├── live/
│       │   ├── lobby_live.ex       # Game lobby interface
│       │   └── game_live.ex        # Multiplayer game interface
│       ├── components/
│       │   ├── layouts.ex          # Layout components
│       │   └── core_components.ex  # Reusable UI components
│       └── router.ex               # Route definitions
├── test/
│   └── tictactoe_web/
│       └── live/
│           └── lobby_live_test.exs # LiveView tests
├── assets/                         # Frontend assets (CSS/JS)
└── README.md                       # This file
```

## 🧪 Running Tests

Run the comprehensive test suite:

```bash
mix test
```

Run tests with coverage:

```bash
mix test --cover
```

Run specific test files:

```bash
mix test test/tictactoe_web/live/lobby_live_test.exs
```

The tests cover:
- ✅ Game creation and joining
- ✅ Input validation and sanitization  
- ✅ Error handling for edge cases
- ✅ UI interactions and state updates
- ✅ Multiplayer game logic
- ✅ PubSub message handling

## 🛠️ Development

### Code Quality

Run all quality checks:

```bash
mix precommit
```

This runs:
- **Formatting**: `mix format --check-formatted`
- **Compilation**: `mix compile --warnings-as-errors` 
- **Tests**: `mix test`
- **Static Analysis**: `mix credo --strict`

### Adding Features

1. **Game Logic**: Modify `MultiplayerGame` for rule changes
2. **UI Changes**: Update `LobbyLive` or `GameLive` 
3. **Registry**: Extend `GameRegistry` for new game management features
4. **Tests**: Add corresponding tests for new functionality

### Development Server

Start server with live reloading:

```bash
mix phx.server
```

Or in IEx for debugging:

```bash
iex -S mix phx.server
```

## 🎯 Game Mechanics

### Board Layout
```
 0 | 1 | 2 
-----------
 3 | 4 | 5 
-----------
 6 | 7 | 8 
```

### Winning Combinations

**Horizontal Wins:**
- Top: [0, 1, 2]
- Middle: [3, 4, 5] 
- Bottom: [6, 7, 8]

**Vertical Wins:**
- Left: [0, 3, 6]
- Center: [1, 4, 7]
- Right: [2, 5, 8]

**Diagonal Wins:**
- Main: [0, 4, 8]
- Anti: [2, 4, 6]

### Game States

- **`:none`** - Game in progress
- **`:X`** - X player wins
- **`:O`** - O player wins  
- **`:draw`** - All cells filled, no winner

## 🌐 Network Features

### Real-time Updates

All game events are broadcast instantly:
- **Player joins/leaves**
- **Moves made**
- **Game state changes**
- **Game resets**

### Connection Handling

- **Automatic reconnection** on network interruptions
- **State synchronization** when reconnecting
- **Graceful player disconnection** handling

### Security

- **Session-based player IDs** prevent impersonation
- **Move validation** prevents cheating
- **Game isolation** prevents cross-game interference

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** and add tests
4. **Run quality checks**: `mix precommit` 
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Contribution Guidelines

- ✅ Write tests for all new features
- ✅ Follow Elixir/Phoenix conventions
- ✅ Update documentation for API changes
- ✅ Ensure all tests pass
- ✅ Use descriptive commit messages

## 📜 License

This project is open source and available under the [MIT License](LICENSE).

## 🚀 Technology Stack

- **Backend**: Elixir with Phoenix Framework 1.7+
- **Frontend**: Phoenix LiveView with Tailwind CSS 
- **Real-time**: Phoenix PubSub for live updates
- **State Management**: OTP GenServers and Supervisors
- **Testing**: ExUnit with Phoenix.LiveViewTest
- **Build Tool**: Mix with Elixir 1.15+

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/discussions)  
- **Documentation**: [HexDocs](https://hexdocs.pm/phoenix/overview.html)

---

**Ready to play?** Start the server and visit [localhost:4000](http://localhost:4000) to begin! 🎮