import dimension
import dom
import gleam/int
import gleam/list
import piece
import position
import preact/component
import preact/signal
import preact/vnode
import state

pub fn render_board() -> component.Component {
  let wrapper =
    vnode.new("div")
    |> vnode.attr("class", "wrapper")
    |> vnode.children(
      list.map(position.y_axis, fn(el) {
        vnode.new("div")
        |> vnode.attr("class", "row")
        |> vnode.children(
          list.map(position.x_axis, fn(on_x) {
            let cell_id = on_x <> el

            vnode.new("div")
            |> vnode.attr("class", "cell")
            |> vnode.attr("data-id", cell_id)
            |> vnode.attr("data-row", el)
            |> vnode.attr("data-column", on_x)
            |> vnode.attr(
              "style",
              "--cell-size: " <> dimension.cell_size |> int.to_string <> "px;",
            )
          }),
        )
      }),
    )
    |> component.to_component

  piece.of(piece.Black)
  |> list.append(piece.of(piece.White))
  |> state.Board(piece.White)
  |> signal.signal
  |> echo

  wrapper
}

fn render_pieces(state: state.Board) {
  list.each(state.pieces, fn(it) {
    piece.mount(it)
    |> dom.listen("click", fn(_) {
      position.possible(it, state) |> echo
      Nil
    })
  })
}
