import dimension
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import piece
import position
import preact/component
import preact/signal
import preact/vnode
import state
import utils

pub fn render_board() -> component.PreactComponent {
  let board_state =
    piece.of(piece.Black)
    |> list.append(piece.of(piece.White))
    |> state.Board(piece.White)
    |> signal.new

  vnode.new("div")
  |> vnode.prop("class", "wrapper")
  |> vnode.children(
    list.map(position.y_axis, fn(el) {
      vnode.new("div")
      |> vnode.prop("class", "row")
      |> vnode.children(
        list.map(position.x_axis, fn(on_x) {
          let piece =
            signal.computed(fn() {
              list.find(signal.value(board_state).pieces, fn(p) {
                p.pos == on_x <> el
              })
              |> option.from_result
            })

          cell(#(on_x, el, piece))
        }),
      )
    }),
  )
  |> component.to_preact
}

fn cell(props: #(String, String, signal.Signal(option.Option(piece.Piece)))) {
  component.new(fn(_, props) {
    let assert option.Some(#(on_x, el, piece)) = props

    vnode.new("div")
    |> vnode.prop("class", "cell")
    |> vnode.prop("data-id", on_x <> el)
    |> vnode.prop("data-row", el)
    |> vnode.prop("data-column", on_x)
    |> vnode.prop(
      "style",
      utils.format("--cell-size: {}px;", [
        dimension.cell_size |> int.to_string,
      ]),
    )
  })
  |> component.render(option.Some(props))
}
// fn render_pieces(state: state.Board) {
//   list.each(state.pieces, fn(it) {
//     piece.mount(it)
//     |> dom.listen("click", fn(_) {
//       position.possible(it, state) |> echo
//       Nil
//     })
//   })
// }
