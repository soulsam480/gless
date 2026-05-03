import gleam/bool
import gleam/dict
import gleam/list
import gleam/option
import movement.{type Move}
import piece

pub type App {
  App(theme: String)
}

pub fn new_app(theme: String) -> App {
  App(theme:)
}

pub fn set_theme(_app: App, theme: String) -> App {
  App(theme:)
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
