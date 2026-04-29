import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import piece

pub const x_axis = ["a", "b", "c", "d", "e", "f", "g", "h"]

pub const y_axis = ["8", "7", "6", "5", "4", "3", "2", "1"]

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
  Move(positions: List(String), final: String, take: option.Option(piece.Piece))
}

type Context {
  Context(
    piece: piece.Piece,
    pieces: List(piece.Piece),
    occupancy: dict.Dict(String, piece.Piece),
  )
}

pub fn possible(
  moves_for piece: piece.Piece,
  with_other pieces: List(piece.Piece),
) -> List(Move) {
  let occupancy_map = make_occupancy(pieces)

  let ctx = Context(piece:, pieces:, occupancy: occupancy_map)

  case piece.kind {
    piece.King -> king_moves(ctx)
    piece.Pawn(_) -> pawn_moves(ctx)
    piece.BishopL | piece.BishopR -> bishop_moves(ctx)
    piece.RookL | piece.RookR -> rook_moves(ctx)
    piece.Queen -> queen_moves(ctx)
    piece.KnightL | piece.KnightR -> knight_moves(ctx)
  }
}

pub fn run(
  with move: Move,
  on piece: piece.Piece,
  with_other pieces: List(piece.Piece),
) -> List(piece.Piece) {
  list.fold(pieces, [], fn(acc, curr) {
    use <- bool.guard(option.is_some(move.take) && move.final == curr.pos, acc)

    use <- bool.guard(
      piece.to_string(curr) != piece.to_string(piece),
      list.prepend(acc, curr),
    )

    list.prepend(acc, piece.Piece(..curr, pos: move.final))
  })
}

// TODO: checkmate
// castling

// moves
// one in all directions
fn king_moves(ctx: Context) -> List(Move) {
  [
    Up(1),
    Down(1),
    Left(1),
    Right(1),
    TopRight(1),
    TopLeft(1),
    BottomRight(1),
    BottomLeft(1),
  ]
  |> list.fold([], fn(acc, command) {
    accumulate_moves(acc, command, ctx, always_move, always_take_opponent)
  })
}

fn queen_moves(ctx: Context) {
  [
    Right(7),
    Left(7),
    Up(7),
    Down(7),
    TopRight(7),
    TopLeft(7),
    BottomRight(7),
    BottomLeft(7),
  ]
  |> list.flat_map(expand)
  |> list.fold([], fn(acc, command) {
    accumulate_moves(acc, command, ctx, always_move, always_take_opponent)
  })
}

// moves
// 1. first => 2/1
// 2. rest => 1
// 3. diagonal => when occupied by opponent
fn pawn_moves(ctx: Context) -> List(Move) {
  let piece = ctx.piece
  let pos = parse(piece.pos)

  // pawn can move 1/2 places if it's not moved yet
  case pos.1 == 2 || pos.1 == 7 {
    True -> [
      pawn_forward_command(piece, 2),
      pawn_forward_command(piece, 1),
    ]
    False -> [pawn_forward_command(piece, 1)]
  }
  |> list.append(pawn_take_command(piece))
  |> list.fold([], fn(acc, command) {
    use command, piece, occupant <- accumulate_moves(
      acc,
      command,
      ctx,
      move: fn(command, occupant) {
        case command {
          Up(_) | Down(_) | Left(_) | Right(_) -> True
          _ -> {
            option.map(occupant, fn(oc) { oc.color != piece.color })
            |> option.unwrap(False)
          }
        }
      },
    )

    case command {
      Up(_) | Down(_) | Left(_) | Right(_) -> Stop
      _ -> always_take_opponent(command, piece, occupant)
    }
  })
}

fn bishop_moves(ctx: Context) {
  [
    TopRight(7),
    TopLeft(7),
    BottomRight(7),
    BottomLeft(7),
  ]
  |> list.flat_map(expand)
  |> list.fold([], fn(acc, command) {
    accumulate_moves(acc, command, ctx, always_move, always_take_opponent)
  })
}

fn rook_moves(ctx: Context) {
  [
    Right(7),
    Left(7),
    Up(7),
    Down(7),
  ]
  |> list.flat_map(expand)
  |> list.fold([], fn(acc, command) {
    accumulate_moves(acc, command, ctx, always_move, always_take_opponent)
  })
}

fn knight_moves(ctx: Context) {
  [
    [Up(2), Right(1)],
    [Up(2), Left(1)],
    [Down(2), Right(1)],
    [Down(2), Left(1)],
    [Left(2), Down(1)],
    [Left(2), Up(1)],
    [Right(2), Down(1)],
    [Right(2), Up(1)],
  ]
  |> list.fold([], fn(outer, commands) {
    // after each possible move,
    // move the current piece to that position
    // and then try the next command
    let child_moves =
      list.fold(commands, [], fn(acc, command) {
        accumulate_moves(
          acc,
          command,
          acc
            |> list.last
            |> result.map(fn(move) {
              Context(..ctx, piece: piece.Piece(..ctx.piece, pos: move.final))
            })
            |> result.unwrap(ctx),
          always_move,
          always_take_regardless,
        )
      })

    // assert that for a knight to move the L command is possible
    use <- bool.guard(list.length(child_moves) != 2, outer)

    // for the final move, take eevery possible move
    // and merge the positions. the final position is the
    // last position in the list of positions
    let final_move =
      list.fold(child_moves, Move([], "", option.None), fn(final, current) {
        let merged_pos = list.append(final.positions, current.positions)

        Move(
          merged_pos,
          list.last(merged_pos) |> result.unwrap(current.final),
          current.take,
        )
      })

    // again assert that the take on the final position is not of same color
    use <- bool.guard(
      final_move.take
        |> option.map(fn(p) { p.color == ctx.piece.color })
        |> option.unwrap(False),
      outer,
    )

    [final_move, ..outer]
  })
}

type TakeResult {
  Jump
  Take
  Stop
}

type CheckResult {
  Pass(positions: List(String), take: option.Option(piece.Piece))
  Fail
}

fn new_or_append(
  check_result: CheckResult,
  pos: String,
  occupant: option.Option(piece.Piece),
) -> CheckResult {
  case check_result {
    Pass(current, _) -> Pass(list.append(current, [pos]), occupant)
    _ -> Pass([pos], occupant)
  }
}

/// here we do few things
/// 1. expand a command with more than one steps
/// 2. then for each command move the piece and check if it has reached boundary
/// 3. then check if we have an occupant on the next position
/// 4. based on take_when, we know if we can cross this or take this
fn accumulate_moves(
  accumulator: List(Move),
  command: MoveCommand,
  ctx: Context,
  move movable_when: fn(MoveCommand, option.Option(piece.Piece)) -> Bool,
  take take_when: fn(MoveCommand, piece.Piece, piece.Piece) -> TakeResult,
) -> List(Move) {
  let piece = ctx.piece

  let outcome =
    list.fold_until(expand(command), Fail, fn(acc, command_part) {
      {
        use result_pos <- result.try(move_with(piece, command_part))
        use <- bool.guard(reached_boundary(result_pos), Error(Nil))

        case dict.get(ctx.occupancy, serialize(result_pos)) {
          Ok(occupant) -> {
            use <- bool.guard(
              !movable_when(command, option.Some(occupant)),
              list.Stop(Fail),
            )

            use <- bool.guard(
              take_when(command, piece, occupant) == Stop,
              list.Stop(Fail),
            )

            use <- bool.guard(
              take_when(command, piece, occupant) == Jump,
              list.Continue(new_or_append(
                acc,
                result_pos |> serialize,
                option.Some(occupant),
              )),
            )

            list.Stop(new_or_append(
              acc,
              result_pos |> serialize,
              option.Some(occupant),
            ))
          }
          _ -> {
            use <- bool.guard(
              !movable_when(command, option.None),
              list.Stop(Fail),
            )

            list.Continue(new_or_append(
              acc,
              result_pos |> serialize,
              option.None,
            ))
          }
        }
        |> Ok
      }
      |> result.unwrap(list.Stop(Fail))
    })

  case outcome {
    Fail -> accumulator
    Pass(pos, take) -> {
      // NOTE: reverse the positions to make them incremental in order
      [Move(pos, list.last(pos) |> result.unwrap(""), take:), ..accumulator]
      |> list.reverse
    }
  }
}

/// move a piece from it's current position to next one with a command
fn move_with(
  piece: piece.Piece,
  command: MoveCommand,
) -> Result(#(String, Int), Nil) {
  let pos = parse(piece.pos)

  let file_to_rank = make_file_to_rank()
  let rank_to_file = make_rank_to_file()

  case command {
    Down(step) | Up(step) -> {
      #(pos.0, case command {
        Up(_) -> pos.1 + step
        _ -> pos.1 - step
      })
      |> Ok
    }

    Left(step) | Right(step) -> {
      dict.get(file_to_rank, pos.0)
      |> result.map(fn(rank) {
        case command {
          Right(_) -> rank + step
          _ -> rank - step
        }
      })
      |> result.try(dict.get(rank_to_file, _))
      |> result.map(fn(file) { #(file, pos.1) })
    }

    TopLeft(step) | TopRight(step) -> {
      let rank = pos.1 + step

      dict.get(file_to_rank, pos.0)
      |> result.map(fn(r) {
        case command {
          TopRight(_) -> r + step
          _ -> r - step
        }
      })
      |> result.try(dict.get(rank_to_file, _))
      |> result.map(fn(file) { #(file, rank) })
    }

    BottomLeft(step) | BottomRight(step) -> {
      let rank = pos.1 - step

      dict.get(file_to_rank, pos.0)
      |> result.map(fn(r) {
        case command {
          BottomRight(_) -> r + step
          _ -> r - step
        }
      })
      |> result.try(dict.get(rank_to_file, _))
      |> result.map(fn(file) { #(file, rank) })
    }
  }
}

/// expand a command with more than one steps to
/// singular ones. this way we can see if a move
/// can be stopped by an occupant
fn expand(command: MoveCommand) -> List(MoveCommand) {
  {
    use <- bool.guard(command.step == 1, [command])
    use acc, curr <- int.range(1, command.step + 1, [])

    list.prepend(acc, case command {
      Up(_) -> Up(curr)
      Down(_) -> Down(curr)
      Left(_) -> Left(curr)
      Right(_) -> Right(curr)
      TopLeft(_) -> TopLeft(curr)
      TopRight(_) -> TopRight(curr)
      BottomLeft(_) -> BottomLeft(curr)
      BottomRight(_) -> BottomRight(curr)
    })
  }
  // NOTE: reverse the command to make them incremental
  // in order
  |> list.reverse
}

fn parse(pos: String) {
  let parts = string.split(pos, "")
  let assert Ok(file) = parts |> list.first
  let assert Ok(rank) = parts |> list.last |> result.try(int.parse)
  #(file, rank)
}

fn serialize(pos: #(String, Int)) -> String {
  pos.0 <> int.to_string(pos.1)
}

fn reached_boundary(pos: #(String, Int)) -> Bool {
  !{ pos.1 >= 1 && pos.1 <= 8 } || !list.contains(x_axis, pos.0)
}

fn make_occupancy(pieces: List(piece.Piece)) -> dict.Dict(String, piece.Piece) {
  list.fold(pieces, dict.new(), fn(acc, curr) {
    dict.insert(acc, curr.pos, curr)
  })
}

fn make_rank_to_file() {
  dict.from_list([
    #(1, "a"),
    #(2, "b"),
    #(3, "c"),
    #(4, "d"),
    #(5, "e"),
    #(6, "f"),
    #(7, "g"),
    #(8, "h"),
  ])
}

fn make_file_to_rank() {
  dict.fold(make_rank_to_file(), dict.new(), fn(acc, key, value) {
    dict.insert(acc, value, key)
  })
}

fn pawn_forward_command(piece: piece.Piece, step: Int) -> MoveCommand {
  case piece.color == piece.White {
    True -> Up(step)
    False -> Down(step)
  }
}

fn pawn_take_command(piece: piece.Piece) -> List(MoveCommand) {
  case piece.color == piece.White {
    True -> [TopLeft(1), TopRight(1)]
    False -> [BottomLeft(1), BottomRight(1)]
  }
}

fn always_move(
  _command: MoveCommand,
  _occupant: option.Option(piece.Piece),
) -> Bool {
  True
}

fn always_take_opponent(
  _command: MoveCommand,
  piece: piece.Piece,
  occupant: piece.Piece,
) {
  use <- bool.guard(piece.color != occupant.color, Take)
  Stop
}

fn always_take_regardless(
  _command: MoveCommand,
  _piece: piece.Piece,
  _occupant: piece.Piece,
) {
  Jump
}
