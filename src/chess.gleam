import cell
import constants
import dom
import gleam/bool
import gleam/dict
import gleam/list
import piece
import player
import position
import preact/component
import preact/signal
import preact/vnode
import state
import theme

pub fn main() -> component.PreactComponent {
  let board_state =
    state.new()
    |> state.set_pieces(
      piece.of(piece.Black)
      |> list.append(piece.of(piece.White)),
    )
    |> state.map(fn(state) {
      state
      |> state.set_possible_moves(
        state.pieces
        |> list.fold(dict.new(), fn(acc, piece) {
          use <- bool.guard(piece.flags.taken, acc)

          acc
          |> dict.insert(
            piece,
            position.possible(
              piece,
              state.pieces,
              state.visible_pieces,
              dict.new(),
              state.possible_moves,
            ),
          )
        }),
      )
    })
    |> signal.new

  let app_state = state.new_app("wood") |> signal.new_persisted("app_state", _)

  let checks =
    board_state
    |> signal.map(fn(state) { position.find_checks(state.possible_moves) })

  dom.add_global_listener("click", fn(ev) {
    use <- bool.guard(dom.event_matches(ev, ".wrapper *"), Nil)
    signal.setter(board_state, state.clear_focused)
    Nil
  })

  vnode.new("app")
  |> vnode.children([
    theme.new(app_state),
    vnode.new("div")
      |> vnode.prop("class", "wrapper")
      |> vnode.children([
        player.player(player.PlayerProps(color: "black", state: board_state)),
        player.player(player.PlayerProps(color: "white", state: board_state)),
      ])
      |> vnode.children(
        list.map(constants.y_axis, fn(rank) {
          vnode.new("div")
          |> vnode.prop("class", "row")
          |> vnode.children(
            list.map(constants.x_axis, fn(file: String) -> vnode.VNode {
              cell.CellProps(file:, rank:, board_state:, checks:)
              |> cell.render
            }),
          )
        }),
      ),
  ])
  |> component.to_preact
}
