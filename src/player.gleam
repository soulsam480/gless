import gleam/int
import gleam/list
import gleam/option
import gleam/string
import piece
import preact/signal
import preact/vnode
import state
import utils

pub type PlayerProps {
  PlayerProps(
    color: String,
    state: signal.Signal(state.Board),
    game_state: signal.Signal(option.Option(state.GameState)),
  )
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

  let player_name =
    props.game_state
    |> signal.map(fn(s) {
      case s {
        option.Some(state) ->
          case props.color {
            "white" ->
              utils.format("{} {}", [
                state.game.white_player,
                format_time_left(state.white_left),
              ])
            _ ->
              utils.format("{} {}", [
                state.game.black_plyer,
                format_time_left(state.black_left),
              ])
          }
        _ -> props.color
      }
    })

  vnode.new("div")
  |> vnode.prop("class", "player")
  |> vnode.prop("data-type", props.color)
  |> vnode.children([
    vnode.new("span")
      |> vnode.text_signal(player_name),
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

fn format_time_left(duration_seconds: Int) -> String {
  let mins = duration_seconds / 60
  let secs = duration_seconds % 60

  mins |> int.to_string |> string.pad_start(2, "0")
  <> ":"
  <> secs |> int.to_string |> string.pad_start(2, "0")
}
