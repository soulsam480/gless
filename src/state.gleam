import gleam/option
import piece
import position

pub type Board {
  Board(
    pieces: List(piece.Piece),
    focused: option.Option(FocusState),
    starting: piece.Color,
  )
}

pub type FocusState {
  FocusState(piece: piece.Piece, moves: List(position.Move))
}

pub fn new() {
  Board(pieces: [], focused: option.None, starting: piece.White)
}

pub fn set_pieces(state: Board, pieces: List(piece.Piece)) -> Board {
  Board(..state, pieces: pieces)
}

pub fn set_focused(state: Board, focused: FocusState) -> Board {
  Board(..state, focused: option.Some(focused))
}

pub fn clear_focused(state: Board) -> Board {
  Board(..state, focused: option.None)
}
