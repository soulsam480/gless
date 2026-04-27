import dom
import gleam/bool
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import preact/component
import preact/signal
import preact/vnode

pub const piece_size = 40

pub type Color {
  Black
  White
}

pub type Piece {
  Piece(color: Color, kind: PieceKind, pos: String)
}

pub type PieceKind {
  King
  Queen
  BishopL
  BishopR
  KnightL
  KnightR
  RookL
  RookR
  Pawn(index: Int)
}

pub fn of(color: Color) -> List(Piece) {
  [
    Piece(color, King, default_pos(color, King)),
    Piece(color, Queen, default_pos(color, Queen)),
    Piece(color, BishopL, default_pos(color, BishopL)),
    Piece(color, BishopR, default_pos(color, BishopR)),
    Piece(color, KnightL, default_pos(color, KnightL)),
    Piece(color, KnightR, default_pos(color, KnightR)),
    Piece(color, RookL, default_pos(color, RookL)),
    Piece(color, RookR, default_pos(color, RookR)),
  ]
  |> int.range(1, 9, _, fn(acc, curr) {
    acc
    |> list.prepend(Piece(color, Pawn(curr), default_pos(color, Pawn(curr))))
  })
}

pub fn to_string(piece: Piece) -> String {
  color_str(piece)
  <> case piece.kind {
    RookR -> "rook_r"
    KnightR -> "knight_r"
    BishopR -> "bishop_r"
    King -> "king"
    Queen -> "queen"
    BishopL -> "bishop_l"
    KnightL -> "knight_l"
    RookL -> "rook_l"
    Pawn(index) -> {
      "pawn_" <> int.to_string(index)
    }
  }
}

pub fn color_str(piece: Piece) -> String {
  case piece.color {
    Black -> "black"
    White -> "white"
  }
}

pub fn new(
  piece: Piece,
  is_focused: signal.Signal(Bool),
  is_in_path: signal.Signal(Bool),
  handle on_click: fn(Piece) -> a,
) {
  {
    use props <- component.try_render(component.new())
    use #(piece, on_click) <- result.try(option.to_result(props, Nil))

    vnode.new("div")
    |> vnode.prop("class", "piece")
    |> vnode.prop("data-color", color_str(piece))
    |> vnode.prop("data-kind", to_string(piece))
    |> vnode.prop(
      "data-title",
      to_string(piece)
        |> string.split("_")
        |> list.first
        |> result.unwrap("")
        |> string.replace("black", "")
        |> string.replace("white", ""),
    )
    |> vnode.prop("data-pos", piece.pos)
    |> vnode.signal_prop("data-focused", signal.map(is_focused, bool.to_string))
    |> vnode.on("click", fn(e) {
      case signal.peek(is_in_path) {
        False -> e |> dom.event_stop_propagation
        True -> {
          Nil
        }
      }

      on_click(piece)
      Nil
    })
    |> vnode.children([piece_icon(color_str(piece), to_string(piece))])
    |> Ok
  }
  |> component.to_vnode(option.Some(#(piece, on_click)))
}

fn default_pos(color: Color, kind: PieceKind) -> String {
  case color {
    White -> {
      case kind {
        RookL -> "a1"
        KnightL -> "b1"
        BishopL -> "c1"
        Queen -> "d1"
        King -> "e1"
        BishopR -> "f1"
        KnightR -> "g1"
        RookR -> "h1"
        Pawn(index) -> {
          case index {
            1 -> "a2"
            2 -> "b2"
            3 -> "c2"
            4 -> "d2"
            5 -> "e2"
            6 -> "f2"
            7 -> "g2"
            _ -> "h2"
          }
        }
      }
    }

    Black -> {
      case kind {
        RookL -> "a8"
        KnightL -> "b8"
        BishopL -> "c8"
        Queen -> "d8"
        King -> "e8"
        BishopR -> "f8"
        KnightR -> "g8"
        RookR -> "h8"
        Pawn(index) -> {
          case index {
            1 -> "a7"
            2 -> "b7"
            3 -> "c7"
            4 -> "d7"
            5 -> "e7"
            6 -> "f7"
            7 -> "g7"
            _ -> "h7"
          }
        }
      }
    }
  }
}

@external(javascript, "./piece_ffi.ts", "render_piece_icon")
fn piece_icon(color: String, piece: String) -> vnode.VNode
