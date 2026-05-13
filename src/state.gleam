import dom
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/time/timestamp
import movement.{type Move}
import piece

pub type App {
  App(theme: String, game: option.Option(GameState))
}

pub fn new_app(theme: String) -> App {
  App(theme:, game: option.None)
}

pub fn set_theme(app: App, theme: String) -> App {
  App(..app, theme:)
}

pub fn set_game_state(app: App, game: GameState) -> App {
  App(..app, game: option.Some(game))
}

pub type Board {
  Board(
    pieces: List(piece.Piece),
    visible_pieces: dict.Dict(String, piece.Piece),
    possible_moves: dict.Dict(piece.Piece, List(Move)),
    focused: option.Option(FocusState),
    starting: piece.Color,
  )
}

pub type FocusState {
  FocusState(piece: piece.Piece, moves: List(Move))
}

pub fn new() {
  Board(
    pieces: [],
    visible_pieces: dict.new(),
    possible_moves: dict.new(),
    focused: option.None,
    starting: piece.White,
  )
}

pub fn set_pieces(state: Board, pieces: List(piece.Piece)) -> Board {
  Board(
    ..state,
    pieces: pieces,
    visible_pieces: list.fold(pieces, dict.new(), fn(acc, current) {
      use <- bool.guard(current.flags.taken, acc)
      dict.insert(acc, current.pos, current)
    }),
  )
}

pub fn set_possible_moves(
  state: Board,
  possible_moves: dict.Dict(piece.Piece, List(Move)),
) -> Board {
  Board(..state, possible_moves: possible_moves)
}

pub fn set_focused(state: Board, focused: FocusState) -> Board {
  Board(..state, focused: option.Some(focused))
}

pub fn clear_focused(state: Board) -> Board {
  Board(..state, focused: option.None)
}

pub fn map(state: Board, f: fn(Board) -> Board) -> Board {
  f(state)
}

/// GAME STATE
pub type Game {
  Game(
    black_plyer: String,
    white_player: String,
    started_at: Float,
    ended_at: option.Option(Float),
    duration_seconds: Int,
    won: option.Option(piece.Color),
  )
}

pub type GameState {
  GameState(
    game: Game,
    current: piece.Color,
    white_left: Int,
    black_left: Int,
    white_timer: Int,
    black_timer: Int,
  )
}

pub fn new_game(black_plyer: String, white_player: String) -> Game {
  Game(
    black_plyer:,
    white_player:,
    started_at: timestamp.system_time() |> timestamp.to_unix_seconds,
    ended_at: option.None,
    duration_seconds: 0,
    won: option.None,
  )
}

pub fn for_duration(game: Game, duration_seconds: Int) -> Game {
  Game(..game, duration_seconds:)
}

pub fn set_won(game: Game, color: piece.Color) -> Game {
  Game(..game, won: option.Some(color))
}

pub fn end(game: Game) -> Game {
  Game(
    ..game,
    ended_at: option.Some(timestamp.system_time() |> timestamp.to_unix_seconds),
  )
}

pub fn start(game: Game) -> Game {
  Game(..game, started_at: timestamp.system_time() |> timestamp.to_unix_seconds)
}

pub fn setup_game(game: Game) -> GameState {
  GameState(
    game:,
    current: piece.White,
    white_left: game.duration_seconds,
    black_left: game.duration_seconds,
    white_timer: 0,
    black_timer: 0,
  )
}

pub fn set_game(state: GameState, game: Game) -> GameState {
  GameState(..state, game:)
}

pub fn time_player(
  state: GameState,
  player: piece.Color,
  run: fn(fn(GameState) -> GameState) -> Nil,
) -> GameState {
  let prev_id = case player {
    piece.White -> state.black_timer
    piece.Black -> state.white_timer
  }

  let state = case prev_id != 0 {
    True -> {
      dom.clear_interval(prev_id)

      GameState(..state, white_timer: 0, black_timer: 0)
    }
    _ -> state
  }

  let id =
    dom.set_interval(
      fn() {
        run(fn(state) {
          case player {
            piece.White -> {
              let left = state.white_left |> int.subtract(1) |> int.max(0)

              GameState(..state, white_left: left)
            }

            piece.Black -> {
              let left = state.black_left |> int.subtract(1) |> int.max(0)

              GameState(..state, black_left: left)
            }
          }
        })
      },
      1000,
    )

  case player {
    piece.White -> GameState(..state, current: player, white_timer: id)
    piece.Black -> GameState(..state, current: player, black_timer: id)
  }
}
