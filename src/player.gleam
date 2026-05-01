import gleam/list
import gleam/string
import piece
import preact/signal
import preact/vnode
import state

pub type PlayerProps {
  PlayerProps(color: String, state: signal.Signal(state.Board))
}

pub fn player(props: PlayerProps) {
  let taken =
    signal.map(props.state, fn(state) {
      list.filter(state.pieces, fn(p) {
        case props.color {
          "white" -> p.color == piece.Black && p.flags.taken
          _ -> p.color == piece.White && p.flags.taken
        }
      })
      |> list.sort(fn(a, b) {
        string.compare(piece.to_string(a), piece.to_string(b))
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
