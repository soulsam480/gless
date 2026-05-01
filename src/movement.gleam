import gleam/option.{type Option}
import piece

pub type MoveCommand {
  Up(step: Int)
  Down(step: Int)
  Left(step: Int)
  Right(step: Int)
  TopLeft(step: Int)
  TopRight(step: Int)
  BottomLeft(step: Int)
  BottomRight(step: Int)
}

pub type Move {
  Move(
    positions: List(String),
    final: String,
    take: Option(piece.Piece),
    /// sub moves this move influences
    sub: Option(SubMove),
  )
}

pub type SubMove {
  SubMove(piece: piece.Piece, move: Move)
}

pub type Check {
  Check(from: piece.Piece, move: Move)
}
