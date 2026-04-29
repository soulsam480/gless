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
  |> vnode.children([
    player(PlayerProps(color: "black", state: board_state)),
    player(PlayerProps(color: "white", state: board_state)),
  ])
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

type PlayerProps {
  PlayerProps(color: String, state: signal.Signal(state.Board))
}

fn player(props: PlayerProps) {
  let taken =
    signal.map(props.state, fn(state) {
      list.filter(state.pieces, fn(p) {
        case props.color {
          "white" -> p.color == piece.Black && p.flags.taken
          _ -> p.color == piece.White && p.flags.taken
        }
      })
    })

  vnode.new("div")
  |> vnode.prop("class", "player")
  |> vnode.prop("data-type", props.color)
  |> vnode.children([
    vnode.new("span")
      |> vnode.text(props.color),
    vnode.new("div")
      |> vnode.prop("class", "taken-pieces")
      |> vnode.signal_children(
        signal.map(
          taken,
          list.map(
            _,
            piece.new(_, signal.new(False), signal.new(False), fn(_) { Nil }),
          ),
        ),
      ),
  ])
}
