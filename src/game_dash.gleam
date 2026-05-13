import dom
import gleam/dynamic/decode
import gleam/int
import gleam/result
import preact/signal
import preact/vnode
import state

type GameFormData {
  GameFormData(white_name: String, black_name: String, duration: Int)
}

fn game_form_data_decoder() -> decode.Decoder(GameFormData) {
  use white_name <- decode.field("white_name", decode.string)
  use black_name <- decode.field("black_name", decode.string)

  use duration <- decode.field(
    "duration",
    decode.string |> decode.map(fn(v) { v |> int.parse |> result.unwrap(0) }),
  )

  decode.success(GameFormData(white_name:, black_name:, duration:))
}

pub fn new(
  app: signal.Signal(state.App),
  setup_game: fn(String, String, Int) -> signal.Signal(state.App),
  start_game: fn(state.GameState) -> signal.Signal(state.App),
) {
  let game = signal.map(app, fn(s) { s.game })

  vnode.new("div")
  |> vnode.prop("class", "game-dash")
  |> vnode.child_ternary_signal(
    game,
    render: fn(game) {
      vnode.new("button")
      |> vnode.text("Start Game")
      |> vnode.prop("type", "submit")
      |> vnode.on("click", fn(_) {
        start_game(game)

        Nil
      })
    },
    else_render: fn() {
      vnode.new("form")
      |> vnode.on("submit", fn(e) {
        e |> dom.event_stop_propagation |> dom.event_prevent_default

        case decode.run(dom.form_data_from(e), game_form_data_decoder()) {
          Ok(form) -> {
            setup_game(form.white_name, form.black_name, form.duration)
            Nil
          }
          _ -> Nil
        }
      })
      |> vnode.child(
        vnode.new("input")
        |> vnode.prop("type", "text")
        |> vnode.prop("name", "white_name")
        |> vnode.prop("required", True)
        |> vnode.prop("placeholder", "White Player"),
      )
      |> vnode.child(
        vnode.new("input")
        |> vnode.prop("type", "text")
        |> vnode.prop("name", "black_name")
        |> vnode.prop("required", True)
        |> vnode.prop("placeholder", "Black Player"),
      )
      |> vnode.child(
        vnode.new("input")
        |> vnode.prop("type", "number")
        |> vnode.prop("required", True)
        |> vnode.prop("name", "duration")
        |> vnode.prop("placeholder", "Duration seconds"),
      )
      |> vnode.child(
        vnode.new("button")
        |> vnode.prop("type", "submit")
        |> vnode.text("Setup Game"),
      )
    },
  )
}
