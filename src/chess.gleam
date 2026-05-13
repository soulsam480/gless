import cell
import constants
import dom
import game_dash
import gleam/bool
import gleam/dict
import gleam/list
import gleam/option
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
    make_board_state()
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

  let game_state = app_state |> signal.map(fn(s) { s.game })

  let active_player =
    game_state |> signal.map(option.map(_, fn(s) { s.current }))

  // 1. take player names
  // 2. take duration
  // make a game state but don't start it
  let setup_game = fn(white_name: String, black_name: String, duration: Int) {
    let game =
      state.new_game(black_name, white_name)
      |> state.for_duration(duration)
      |> state.setup_game

    signal.setter(app_state, state.set_game_state(_, game))
  }

  // set timers and start a preset game
  let switch_game = fn(game_state: state.GameState, for_player: piece.Color) {
    signal.setter(app_state, fn(state) {
      let game_state =
        state.start(game_state.game)
        |> state.set_game(game_state, _)

      game_state
      |> state.time_player(for_player, fn(update) {
        signal.setter(app_state, fn(state) {
          case state.game {
            option.Some(game) -> state.set_game_state(state, update(game))
            _ -> state
          }
        })

        Nil
      })
      |> state.set_game_state(state, _)
    })

    signal.set(board_state, make_board_state())

    app_state
  }

  let start_game = fn(game_state: state.GameState) {
    switch_game(game_state, piece.White)
  }

  vnode.fragment()
  |> vnode.children([
    game_dash.new(app_state, setup_game, start_game),
    theme.new(app_state),
    vnode.new("div")
      |> vnode.prop("class", "wrapper")
      |> vnode.children([
        player.player(player.PlayerProps(
          color: "black",
          state: board_state,
          game_state: game_state,
        )),
        player.player(player.PlayerProps(
          color: "white",
          state: board_state,
          game_state: game_state,
        )),
      ])
      |> vnode.children(
        list.map(constants.y_axis, fn(rank) {
          vnode.new("div")
          |> vnode.prop("class", "row")
          |> vnode.children(
            list.map(constants.x_axis, fn(file: String) -> vnode.VNode {
              cell.CellProps(
                file:,
                rank:,
                board_state:,
                checks:,
                active_player:,
                on_move: fn() {
                  case signal.peek(game_state) {
                    option.Some(state) -> {
                      switch_game(state, case signal.peek(active_player) {
                        option.Some(piece.White) -> piece.Black
                        option.Some(piece.Black) -> piece.White
                        _ -> piece.White
                      })
                      Nil
                    }

                    _ -> Nil
                  }

                  Nil
                },
              )
              |> cell.render
            }),
          )
        }),
      ),
  ])
  |> component.to_preact
}

fn make_board_state() -> state.Board {
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
}
