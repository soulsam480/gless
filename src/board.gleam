import cell
import dom
import gleam/bool
import gleam/list
import piece
import position
import preact/component
import preact/signal
import preact/vnode
import state

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
  |> vnode.children(
    list.map(position.y_axis, fn(rank) {
      vnode.new("div")
      |> vnode.prop("class", "row")
      |> vnode.children(
        list.map(position.x_axis, fn(file: String) -> vnode.VNode {
          cell.CellProps(file:, rank:, board_state:)
          |> cell.render
        }),
      )
    }),
  )
  |> component.to_preact
}
