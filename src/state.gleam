import piece

pub type Board {
  Board(pieces: List(piece.Piece), starting: piece.Color)
}
