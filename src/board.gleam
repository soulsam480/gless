import cell
import dimension
import dom
import gleam/bool
import gleam/list
import piece
import position
import preact/component
import preact/signal
import preact/vnode
import state
import utils

pub fn render_board() -> component.PreactComponent {
  let board_state =
    state.new()
    |> state.set_pieces(
      piece.of(piece.Black)
      |> list.append(piece.of(piece.White)),
    )
    |> signal.new

  dom.add_global_listener("click", fn(ev) {
    use <- bool.guard(dom.event_matches(ev, ".wrapper *"), Nil)
    signal.setter(board_state, state.clear_focused)
    Nil
  })

  vnode.new("div")
  |> vnode.prop("class", "wrapper")
  |> vnode.prop(
    "style",
    utils.format("--cell-size: {};", [dimension.cell_size]),
  )
  |> vnode.children(
    list.map(position.y_axis, fn(el) {
      vnode.new("div")
      |> vnode.prop("class", "row")
      |> vnode.children(
        list.map(position.x_axis, fn(on_x: String) -> vnode.VNode {
          cell.CellProps(on_x:, el:, board_state:)
          |> cell.render
        }),
      )
    }),
  )
  |> component.to_preact
}
