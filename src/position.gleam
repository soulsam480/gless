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
  Context(pieces: List(piece.Piece), occupancy: dict.Dict(String, piece.Piece))
}

pub fn possible(
  moves_for piece: piece.Piece,
  with_other pieces: List(piece.Piece),
) -> List(Move) {
  let occupancy_map = make_occupancy(pieces)

  let ctx = Context(pieces:, occupancy: occupancy_map)

  case piece.kind {
    piece.King -> king_moves(piece, ctx)
    piece.Pawn(_) -> pawn_moves(piece, ctx)
    _ -> []
  }
}

pub fn run(
  move move: Move,
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

fn king_moves(piece: piece.Piece, ctx: Context) -> List(Move) {
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
  |> list.filter_map(fn(command) {
    use _, occupant <- check_command(piece, command, ctx)
    occupant.color != piece.color
  })
}

fn pawn_moves(piece: piece.Piece, ctx: Context) -> List(Move) {
  let pos = parse(piece.pos)

  // pawn can move 1/2 places if it's not moved yet
  case pos.1 == 2 || pos.1 == 7 {
    True -> [
      pawn_forward_command(piece, 2),
      pawn_forward_command(piece, 1),
    ]
    False -> [pawn_forward_command(piece, 1)]
  }
  |> list.filter_map(fn(command) {
    use command, occupant <- check_command(piece, command, ctx)

    case command {
      Up(_) | Down(_) | Left(_) | Right(_) -> False
      _ -> occupant.color == piece.color
    }
  })
}

type CheckResult {
  Pass(positions: List(String), take: option.Option(piece.Piece))
  Fail
}

fn new_or_append(
  check_result: CheckResult,
  pos: String,
  occupant: option.Option(piece.Piece),
) {
  case check_result {
    Pass(current, _) -> Pass(list.append([pos], current), occupant)
    _ -> Pass([pos], occupant)
  }
}

/// here we do few things
/// 1. expand a command with more than one steps
/// 2. then for each command move the piece and check if it has reached boundary
/// 3. then check if we have an occupant on the next position
/// 4. based on take_when, we know if we can cross this or take this
fn check_command(
  piece: piece.Piece,
  command: MoveCommand,
  ctx: Context,
  take_when: fn(MoveCommand, piece.Piece) -> Bool,
) {
  let outcome =
    list.fold_until(expand(command), Fail, fn(acc, command_part) {
      let result_pos = move_with(piece, command_part)

      use <- bool.guard(reached_boundary(result_pos), list.Stop(Fail))

      // TODO: need to figure out how to move knight
      case dict.get(ctx.occupancy, serialize(result_pos)) {
        Ok(occupant) -> {
          use <- bool.guard(!take_when(command, occupant), list.Stop(Fail))

          list.Continue(new_or_append(
            acc,
            result_pos |> serialize,
            option.Some(occupant),
          ))
        }
        _ ->
          list.Continue(new_or_append(acc, result_pos |> serialize, option.None))
      }
    })

  case outcome {
    Fail -> Error(Nil)
    Pass(pos, take) -> Ok(Move(pos, list.last(pos) |> result.unwrap(""), take:))
  }
}

/// move a piece from it's current position to next one with a command
fn move_with(piece: piece.Piece, command: MoveCommand) -> #(String, Int) {
  let pos = parse(piece.pos)

  let file_to_rank = make_file_to_rank()
  let rank_to_file = make_rank_to_file()

  case command {
    Down(step) | Up(step) -> {
      #(pos.0, case command {
        Up(_) -> pos.1 + step
        _ -> pos.1 - step
      })
    }

    Left(step) | Right(step) -> {
      let assert Ok(file) =
        dict.get(file_to_rank, pos.0)
        |> result.map(fn(rank) {
          case command {
            Right(_) -> rank + step
            _ -> rank - step
          }
        })
        |> result.try(dict.get(rank_to_file, _))

      #(file, pos.1)
    }

    TopLeft(step) | TopRight(step) -> {
      let rank = pos.1 + step

      let assert Ok(file) =
        dict.get(file_to_rank, pos.0)
        |> result.map(fn(r) {
          case command {
            TopRight(_) -> r + step
            _ -> r - step
          }
        })
        |> result.try(dict.get(rank_to_file, _))

      #(file, rank)
    }

    BottomLeft(step) | BottomRight(step) -> {
      let rank = pos.1 - step

      let assert Ok(file) =
        dict.get(file_to_rank, pos.0)
        |> result.map(fn(r) {
          case command {
            BottomRight(_) -> r + step
            _ -> r - step
          }
        })
        |> result.try(dict.get(rank_to_file, _))

      #(file, rank)
    }
  }
}

/// expand a command with more than one steps to
/// singular ones. this way we can see if a move
/// can be stopped by an occupant
fn expand(command: MoveCommand) -> List(MoveCommand) {
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

fn parse(pos: String) {
  let parts = string.split(pos, "")
  let assert Ok(file) = parts |> list.first
  let assert Ok(rank) = parts |> list.last |> result.try(fn(v) { int.parse(v) })
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
