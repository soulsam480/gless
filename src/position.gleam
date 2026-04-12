import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import piece
import state

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
  Move(command: MoveCommand, dest: String, take: option.Option(piece.Piece))
}

pub fn possible(piece: piece.Piece, state: state.Board) -> List(Move) {
  let occupancy_map = occupancy(state)

  case piece.kind {
    piece.King -> king_moves(piece, occupancy_map)
    piece.Pawn(_) -> pawn_moves(piece, state, occupancy_map)

    _ -> {
      []
    }
  }
}

fn king_moves(
  piece: piece.Piece,
  occupancy: dict.Dict(String, piece.Piece),
) -> List(Move) {
  let pos = parse(piece.pos)

  [
    Up(1),
    Down(1),
    Left(1),
    Right(1),
  ]
  |> list.filter_map(fn(command) {
    {
      use <- bool.guard(reached_boundary(pos, command), Error(option.None))
      let result_pos = move_with(piece, command) |> serialize

      use p <- result.try(
        dict.get(occupancy, result_pos)
        |> result.replace_error(
          option.Some(Move(command:, dest: result_pos, take: option.None)),
        ),
      )

      use <- bool.guard(p.color == piece.color, Error(option.None))

      Ok(Move(command:, dest: result_pos, take: option.Some(p)))
    }
    |> result.try_recover(option.to_result(_, Nil))
  })
}

fn pawn_moves(
  piece: piece.Piece,
  state: state.Board,
  occupancy: dict.Dict(String, piece.Piece),
) -> List(Move) {
  let pos = parse(piece.pos)

  case pos.1 == 2 || pos.1 == 7 {
    True -> [
      pawn_forward_command(piece, state, 2),
      pawn_forward_command(piece, state, 1),
    ]
    False -> [pawn_forward_command(piece, state, 1)]
  }
  |> list.filter_map(fn(command) {
    use <- bool.guard(reached_boundary(pos, command), Error(Nil))
    let result_pos = move_with(piece, command) |> serialize

    case dict.get(occupancy, result_pos) {
      Ok(_) -> Error(Nil)
      _ -> Ok(Move(command:, dest: result_pos, take: option.None))
    }
  })
  // TODO: implement diagonal take
}

fn move_with(piece: piece.Piece, command: MoveCommand) {
  let pos = parse(piece.pos)

  let file_to_rank = make_file_to_rank()
  let rank_to_file = make_rank_to_file()

  case command {
    Up(step) -> {
      #(pos.0, pos.1 + step)
    }

    Down(step) -> {
      #(pos.0, pos.1 - step)
    }

    Left(step) -> {
      let assert Ok(file) =
        dict.get(file_to_rank, pos.0)
        |> result.try(fn(rank) { Ok({ rank - step }) })
        |> result.try(fn(rank) { dict.get(rank_to_file, rank) })

      #(file, pos.1)
    }

    Right(step) -> {
      let assert Ok(file) =
        dict.get(file_to_rank, pos.0)
        |> result.try(fn(rank) { Ok({ rank + step }) })
        |> result.try(fn(v) { dict.get(rank_to_file, v) })

      #(file, pos.1)
    }

    _ -> {
      pos
    }
  }
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

fn reached_boundary(pos: #(String, Int), command: MoveCommand) -> Bool {
  case command {
    Up(_) -> {
      pos.1 == 8
    }

    Down(_) -> {
      pos.1 == 1
    }

    Left(_) -> {
      pos.0 == "a"
    }

    Right(_) -> {
      pos.0 == "h"
    }

    // NOTE: below are wrong
    BottomLeft(_) -> {
      pos.0 == "a" && pos.1 == 1
    }

    BottomRight(_) -> {
      pos.0 == "h" && pos.1 == 1
    }

    TopLeft(_) -> {
      pos.0 == "a" && pos.1 == 8
    }

    TopRight(_) -> {
      pos.0 == "h" && pos.1 == 8
    }
  }
}

fn occupancy(state: state.Board) -> dict.Dict(String, piece.Piece) {
  list.fold(state.pieces, dict.new(), fn(acc, curr) {
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

fn pawn_forward_command(
  piece: piece.Piece,
  state: state.Board,
  step: Int,
) -> MoveCommand {
  case piece.color == state.starting {
    True -> Up(step)
    False -> Down(step)
  }
}
