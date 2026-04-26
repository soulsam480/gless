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
  CellProps(on_x: String, el: String, board_state: signal.Signal(state.Board))
}

pub fn render(props: CellProps) {
  {
    use props <- component.render_result(component.new())

    use CellProps(on_x, el, board_state) <- result.try(option.to_result(
      props,
      Nil,
    ))

    let cell_id = on_x <> el

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

    let is_in_path =
      board_state
      |> signal.map(fn(state) {
        state.focused
        |> option.map(fn(s) {
          s.moves
          |> list.any(fn(m) { m.positions |> list.contains(cell_id) })
        })
        |> option.unwrap(False)
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

    vnode.new("div")
    |> vnode.prop("class", "cell")
    |> vnode.prop("data-id", cell_id)
    |> vnode.prop("data-row", el)
    |> vnode.prop("data-column", on_x)
    |> vnode.signal_prop(
      "data-is-in-path",
      is_in_path |> signal.map(bool.to_string),
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
    |> vnode.wrap_if_signal(piece, render: fn(piece) {
      piece.new(piece, is_focused, handle: fn(p) {
        signal.setter(board_state, fn(prev) {
          prev
          |> state.set_focused(state.FocusState(
            piece,
            moves: position.possible(p, { board_state |> signal.value }.pieces),
          ))
        })
      })
    })
    |> Ok
  }
  |> component.to_vnode(option.Some(props))
}
