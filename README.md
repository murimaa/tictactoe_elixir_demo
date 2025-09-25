# TicTacToe Phoenix LiveView Game

A real-time TicTacToe game built with Phoenix LiveView and Elixir, featuring a beautiful web interface with smooth interactions and game state management.

## Features

- **Real-time gameplay** with Phoenix LiveView
- **Beautiful UI** with Tailwind CSS styling
- **Game state management** using GenServer
- **Responsive design** that works on desktop and mobile
- **Visual feedback** with hover effects and animations
- **Game reset functionality** to start new games
- **Winner detection** and draw scenarios
- **Input validation** to prevent invalid moves

## Getting Started

### Prerequisites

- Elixir 1.15 or later
- Phoenix 1.7 or later
- Node.js and npm (for asset compilation)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd tictactoe
```

2. Install dependencies:
```bash
mix deps.get
```

3. Install Node.js dependencies:
```bash
cd assets && npm install && cd ..
```

4. Start the Phoenix server:
```bash
mix phx.server
```

5. Open your browser and navigate to [`localhost:4000`](http://localhost:4000)

## How to Play

1. **Starting the Game**: The game starts automatically with Player X's turn
2. **Making Moves**: Click on any empty cell to place your mark (X or O)
3. **Winning**: Get three marks in a row (horizontal, vertical, or diagonal)
4. **Draw**: If all cells are filled without a winner, the game ends in a draw
5. **New Game**: Click the "New Game" button to reset and start over

## Technical Architecture

### Game Logic (`TicTacToe.Game`)

The core game logic is implemented as a GenServer that maintains:
- **Game Board**: A list of 9 positions representing the 3x3 grid
- **Current Player**: Tracks whose turn it is (X or O)
- **Winner State**: Tracks if there's a winner or draw

Key functions:
- `make_move/2` - Attempts to place a mark at a specific position
- `get_game_state/0` - Returns the current game state
- `reset_game/0` - Resets the game to initial state

### LiveView Interface (`TictactoeWeb.GameLive`)

The web interface uses Phoenix LiveView for real-time updates:
- **Mount**: Initializes the view with current game state
- **Event Handling**: Processes player moves and game resets
- **Reactive UI**: Updates automatically when game state changes
- **Flash Messages**: Provides feedback for invalid moves

### Styling

The game uses Tailwind CSS for a modern, responsive design:
- **Gradient backgrounds** for visual appeal
- **Interactive buttons** with hover effects
- **Responsive grid layout** for the game board
- **Color-coded players** (blue for X, red for O)
- **Smooth transitions** and animations

## Project Structure

```
tictactoe/
├── lib/
│   ├── tictactoe/
│   │   ├── application.ex          # Application supervisor
│   │   └── game.ex                 # Game logic GenServer
│   └── tictactoe_web/
│       ├── live/
│       │   └── game_live.ex        # LiveView interface
│       ├── components/
│       │   ├── layouts.ex          # Layout components
│       │   └── core_components.ex  # Reusable components
│       └── router.ex               # Route definitions
├── test/
│   └── tictactoe_web/
│       └── live/
│           └── game_live_test.exs  # LiveView tests
├── assets/                         # Frontend assets
└── README.md
```

## Running Tests

Run the test suite to verify everything works correctly:

```bash
mix test
```

The tests cover:
- Initial game state display
- Player move validation
- Winner detection
- Game reset functionality
- Draw scenarios
- Invalid move handling

## Development

### Adding Features

To add new features:

1. **Game Logic**: Modify `TicTacToe.Game` for new game rules
2. **UI Changes**: Update `TictactoeWeb.GameLive` for interface changes
3. **Tests**: Add corresponding tests in `game_live_test.exs`

### Code Quality

Run the precommit checks to ensure code quality:

```bash
mix precommit
```

This will run:
- Code formatting
- Compilation checks
- Test suite
- Static analysis

## Game Rules

### Winning Conditions

A player wins by getting three marks in a row:

**Horizontal:**
- Top row: positions 0, 1, 2
- Middle row: positions 3, 4, 5
- Bottom row: positions 6, 7, 8

**Vertical:**
- Left column: positions 0, 3, 6
- Middle column: positions 1, 4, 7
- Right column: positions 2, 5, 8

**Diagonal:**
- Top-left to bottom-right: positions 0, 4, 8
- Top-right to bottom-left: positions 2, 4, 6

### Board Layout

```
 0 | 1 | 2 
-----------
 3 | 4 | 5 
-----------
 6 | 7 | 8 
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run `mix precommit` to ensure quality
6. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).

## Technology Stack

- **Backend**: Elixir with Phoenix Framework
- **Frontend**: Phoenix LiveView with Tailwind CSS
- **State Management**: GenServer (OTP)
- **Testing**: ExUnit with Phoenix.LiveViewTest
- **Build Tool**: Mix