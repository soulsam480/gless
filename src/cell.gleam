import gleam/bool
import gleam/list
import gleam/option
import gleam/result
import piece
import position
import preact/component
import preact/signal
import preact/vnode
import state

pub type CellProps {
  CellProps(file: String, rank: String, board_state: signal.Signal(state.Board))
}

pub fn render(props: CellProps) {
  {
    use props <- component.try_render(component.new())

    use CellProps(file, rank, board_state) <- result.try(option.to_result(
      props,
      Nil,
    ))

    let cell_id = file <> rank

    let piece =
      board_state
      |> signal.map(fn(state) {
        list.find(state.pieces, fn(p) { p.pos == cell_id })
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

    vnode.new("div")
    |> vnode.prop("class", "cell")
    |> vnode.prop("data-id", cell_id)
    |> vnode.prop("data-row", rank)
    |> vnode.prop("data-column", file)
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
            |> state.set_pieces(position.run(
              move,
              focus_state.piece,
              prev.pieces,
            ))
            |> state.clear_focused
          })

          Nil
        }

        _ -> Nil
      }
    })
    |> vnode.child_if_signal(piece, render: fn(piece) {
      piece.new(piece, is_focused, is_destination, handle: fn(p) {
        signal.setter(board_state, fn(prev) {
          case signal.value(is_destination) {
            True -> prev

            False -> {
              prev
              |> state.set_focused(state.FocusState(
                piece,
                moves: position.possible(p, signal.value(board_state).pieces),
              ))
            }
          }
        })
      })
    })
    |> Ok
  }
  |> component.to_vnode(option.Some(props))
}
