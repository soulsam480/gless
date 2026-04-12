import dimension
import dom
import gleam/int
import gleam/javascript/array
import gleam/list
import gleam/option
import piece
import position
import state

pub fn render_board() -> dom.HtmlElement {
  let assert option.Some(app) = dom.query("#app")

  let board =
    list.map(position.y_axis, fn(el) {
      let children =
        list.map(position.x_axis, fn(on_x) {
          let cell_id = on_x <> el

          dom.h_text(
            "div",
            array.from_list([
              #("class", "cell"),
              #("data-id", cell_id),
              #("data-row", el),
              #("data-column", on_x),
              #(
                "style",
                "--cell-size: " <> dimension.cell_size |> int.to_string <> "px;",
              ),
            ]),
            array.from_list([]),
          )
        })
        |> array.from_list

      dom.h_el("div", array.from_list([#("class", "row")]), children)
    })
    |> array.from_list
    |> dom.h_el("div", array.from_list([#("class", "wrapper")]), _)

  dom.append_child(app, board)
  render_pieces(board)
}

fn render_pieces(app: dom.HtmlElement) {
  let state =
    piece.make_from(piece.Black)
    |> list.append(piece.make_from(piece.White))
    |> state.Board(piece.White)

  list.each(state.pieces, fn(piece) {
    piece.mount(piece)
    |> dom.listen("click", fn(_) {
      position.possible(piece, state) |> echo
      Nil
    })
  })

  app
}
