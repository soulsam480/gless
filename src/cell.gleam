import gleam/bool
import gleam/dict
import gleam/list
import gleam/option
import movement
import piece
import position
import preact/signal
import preact/vnode
import state

pub type CellProps {
  CellProps(
    file: String,
    rank: String,
    board_state: signal.Signal(state.Board),
    checks: signal.Signal(dict.Dict(piece.Piece, List(movement.Check))),
  )
}

pub fn render(props: CellProps) {
  let CellProps(file, rank, board_state, checks) = props

  let cell_id = file <> rank

  let piece =
    board_state
    |> signal.map(fn(state) {
      dict.get(state.visible_pieces, cell_id)
      |> option.from_result
    })

  let is_focused =
    signal.computed(with: fn() {
      case
        signal.value(board_state).focused |> option.map(fn(v) { v.piece }),
        signal.value(piece)
      {
        option.Some(left), option.Some(right) ->
          piece.to_string(left) == piece.to_string(right)
        _, _ -> False
      }
    })

  let destination_move =
    board_state
    |> signal.map(fn(state) {
      state.focused
      |> option.then(fn(s) {
        s.moves
        |> list.find(fn(m) { m.final == cell_id })
        |> option.from_result
      })
    })

  let is_destination =
    destination_move
    |> signal.map(fn(move) {
      move
      |> option.map(fn(m) { m.final == cell_id })
      |> option.unwrap(False)
    })

  let has_check =
    signal.computed(fn() {
      signal.value(piece)
      |> option.map(fn(p) { signal.value(checks) |> dict.has_key(p) })
      |> option.unwrap(False)
    })

  vnode.new("div")
  |> vnode.prop("class", "cell")
  |> vnode.prop("data-id", cell_id)
  |> vnode.prop("data-row", rank)
  |> vnode.prop("data-column", file)
  |> vnode.signal_prop(
    "data-has-check",
    has_check |> signal.map(bool.to_string),
  )
  |> vnode.prop("key", cell_id)
  |> vnode.signal_prop(
    "data-is-in-path",
    is_destination |> signal.map(bool.to_string),
  )
  |> vnode.on("click", fn(_) {
    case signal.peek(destination_move) {
      option.Some(move) -> {
        signal.setter(board_state, fn(prev) {
          let assert option.Some(focus_state) = prev.focused

          prev
          |> state.set_pieces(position.run(move, focus_state.piece, prev.pieces))
          |> state.clear_focused
          |> state.map(fn(base) {
            base
            |> state.set_possible_moves(
              base.pieces
              |> list.fold(dict.new(), fn(acc, piece) {
                use <- bool.guard(piece.flags.taken, acc)

                acc
                |> dict.insert(
                  piece,
                  position.possible(
                    piece,
                    base.pieces,
                    base.visible_pieces,
                    signal.peek(checks),
                  ),
                )
              }),
            )
          })
        })

        Nil
      }

      _ -> Nil
    }
  })
  |> vnode.child_if_signal(piece, render: fn(piece) {
    piece.new(piece, is_focused, is_destination, handle: fn(p) {
      signal.setter(board_state, fn(prev) {
        case signal.peek(is_destination) {
          True -> prev

          False -> {
            let state.Board(pieces:, visible_pieces:, ..) =
              signal.peek(board_state)

            prev
            |> state.set_focused(state.FocusState(
              piece,
              moves: position.possible(
                p,
                pieces,
                visible_pieces,
                signal.peek(checks),
              ),
            ))
          }
        }
      })
    })
  })
}
