import constants
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import movement.{
  type Move, type MoveCommand, BottomLeft, BottomRight, Down, Left, Move, Right,
  TopLeft, TopRight, Up,
}
import piece

type Context {
  Context(
    piece: piece.Piece,
    pieces: List(piece.Piece),
    occupancy: dict.Dict(String, piece.Piece),
    checks: dict.Dict(piece.Piece, List(movement.Check)),
    file_to_rank: dict.Dict(String, Int),
    rank_to_file: dict.Dict(Int, String),
  )
}

pub fn possible(
  moves_for piece: piece.Piece,
  with_other pieces: List(piece.Piece),
  with_occupied occupancy: dict.Dict(String, piece.Piece),
  with_checks checks: dict.Dict(piece.Piece, List(movement.Check)),
) -> List(Move) {
  let ctx =
    Context(
      piece:,
      pieces:,
      occupancy:,
      checks:,
      file_to_rank: constants.make_file_to_rank(),
      rank_to_file: constants.make_rank_to_file(),
    )

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
    // delete taken piece
    use <- bool.guard(
      option.is_some(move.take) && move.final == curr.pos,
      acc |> list.prepend(piece.Piece(..curr, flags: piece.taken(piece.flags))),
    )

    // keep every other piece
    use <- bool.guard(
      piece.to_string(curr) != piece.to_string(piece),
      list.prepend(acc, curr),
    )

    // move current piece to the final position
    list.prepend(
      acc,
      piece.Piece(..curr, pos: move.final, flags: piece.moved(piece.flags)),
    )
  })
}

pub fn find_checks(
  possible_moves: dict.Dict(piece.Piece, List(Move)),
) -> dict.Dict(piece.Piece, List(movement.Check)) {
  dict.fold(possible_moves, dict.new(), fn(acc, piece, moves) {
    let moves_with_king_takes =
      moves
      |> list.filter_map(fn(move) {
        use <- bool.guard(
          option.map(move.take, fn(p) { p.kind == piece.King })
            |> option.unwrap(False)
            |> bool.negate,
          Error(Nil),
        )

        movement.Check(from: piece, move:) |> Ok
      })

    use <- bool.guard(moves_with_king_takes == [], acc)

    moves_with_king_takes
    |> list.group(fn(a) {
      let assert option.Some(b) = a.move.take

      b
    })
    |> dict.merge(acc)
  })
}

// TODO: checkmate
// castling

// moves
// one in all directions
fn king_moves(ctx: Context) -> List(Move) {
  {
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
    |> list.fold(new_move_accumulator(), fn(acc, command) {
      accumulate_moves(acc, command, ctx, always_move, always_take_opponent)
    })
  }.moves
}

fn queen_moves(ctx: Context) {
  {
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
    |> list.fold(new_move_accumulator(), fn(acc, command) {
      accumulate_moves(acc, command, ctx, always_move, always_take_opponent)
    })
  }.moves
}

// moves
// 1. first => 2/1
// 2. rest => 1
// 3. diagonal => when occupied by opponent
fn pawn_moves(ctx: Context) -> List(Move) {
  let piece = ctx.piece
  let pos = parse(piece.pos)

  // pawn can move 1/2 places if it's not moved yet
  {
    case pos.1 == 2 || pos.1 == 7 {
      True -> [
        pawn_forward_command(piece, 2),
        pawn_forward_command(piece, 1),
      ]
      False -> [pawn_forward_command(piece, 1)]
    }
    |> list.append(pawn_take_command(piece))
    |> list.fold(new_move_accumulator(), fn(acc, command) {
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
  }.moves
}

fn bishop_moves(ctx: Context) {
  {
    [
      TopRight(7),
      TopLeft(7),
      BottomRight(7),
      BottomLeft(7),
    ]
    |> list.flat_map(expand)
    |> list.fold(new_move_accumulator(), fn(acc, command) {
      accumulate_moves(acc, command, ctx, always_move, always_take_opponent)
    })
  }.moves
}

fn rook_moves(ctx: Context) {
  {
    [
      Right(7),
      Left(7),
      Up(7),
      Down(7),
    ]
    |> list.flat_map(expand)
    |> list.fold(new_move_accumulator(), fn(acc, command) {
      accumulate_moves(acc, command, ctx, always_move, always_take_opponent)
    })
  }.moves
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
      {
        list.fold(commands, new_move_accumulator(), fn(acc, command) {
          accumulate_moves(
            acc,
            command,
            acc.moves
              |> list.last
              |> result.map(fn(move) {
                Context(..ctx, piece: piece.Piece(..ctx.piece, pos: move.final))
              })
              |> result.unwrap(ctx),
            always_move,
            always_take_regardless,
          )
        })
      }.moves

    // assert that for a knight to move the L command is possible
    use <- bool.guard(list.length(child_moves) != 2, outer)

    // for the final move, take eevery possible move
    // and merge the positions. the final position is the
    // last position in the list of positions
    let final_move =
      list.fold(
        child_moves,
        Move([], "", option.None, option.None),
        fn(final, current) {
          let merged_pos = list.append(final.positions, current.positions)

          Move(
            merged_pos,
            list.last(merged_pos) |> result.unwrap(current.final),
            current.take,
            option.None,
          )
        },
      )

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

type MoveAccumulator {

  MoveAccumulator(moves: List(Move), keys: List(String))
}

fn new_move_accumulator() -> MoveAccumulator {
  MoveAccumulator([], [])
}

fn add_move(accumulator: MoveAccumulator, move: Move) -> MoveAccumulator {
  use <- bool.guard(
    accumulator.keys |> list.contains(move.positions |> string.join("_")),
    accumulator,
  )

  MoveAccumulator(
    // NOTE: reverse the positions to make them incremental in order
    moves: list.append(accumulator.moves, [move]) |> list.reverse,
    keys: list.prepend(accumulator.keys, move.positions |> string.join("_")),
  )
}

/// here we do few things
/// 1. expand a command with more than one steps
/// 2. then for each command move the piece and check if it has reached boundary
/// 3. then check if we have an occupant on the next position
/// 4. based on take_when, we know if we can cross this or take this
fn accumulate_moves(
  accumulator: MoveAccumulator,
  command: MoveCommand,
  ctx: Context,
  move movable_when: fn(MoveCommand, option.Option(piece.Piece)) -> Bool,
  take take_when: fn(MoveCommand, piece.Piece, piece.Piece) -> TakeResult,
) -> MoveAccumulator {
  let piece = ctx.piece

  let outcome =
    list.fold_until(expand(command), Fail, fn(acc, command_part) {
      {
        use result_pos <- result.try(move_with(piece, ctx, command_part))
        use <- bool.guard(reached_boundary(result_pos), Error(Nil))
        use <- bool.guard(king_has_check(ctx, result_pos), Error(Nil))

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
      accumulator
      |> add_move(Move(
        pos,
        list.last(pos) |> result.unwrap(""),
        take:,
        sub: option.None,
      ))
    }
  }
}

/// move a piece from it's current position to next one with a command
fn move_with(
  piece: piece.Piece,
  ctx: Context,
  command: MoveCommand,
) -> Result(#(String, Int), Nil) {
  let pos = parse(piece.pos)

  let file_to_rank = ctx.file_to_rank
  let rank_to_file = ctx.rank_to_file

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
  !{ pos.1 >= 1 && pos.1 <= 8 } || !list.contains(constants.x_axis, pos.0)
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

fn king_has_check(ctx: Context, pos: #(String, Int)) -> Bool {
  use <- bool.guard(ctx.piece.kind != piece.King, False)

  {
    use checks <- result.try(dict.get(ctx.checks, ctx.piece))

    checks
    |> list.any(fn(check) {
      check.move.positions |> list.contains(serialize(pos))
    })
    |> Ok
  }
  |> result.unwrap(False)
}
