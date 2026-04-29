import { Piece, type PieceProps } from "@chessire/pieces";
import { h } from "preact";

const ID_TO_PIECE: Record<string, PieceProps["piece"]> = {
	rook: "R",
	knight: "N",
	bishop: "B",
	queen: "Q",
	king: "K",
	pawn: "P",
};

export function render_piece_icon(
	color: PieceProps["color"],
	piece: PieceProps["piece"],
) {
	return h(Piece, {
		color: color === "white" ? "black" : "white",
		piece: ID_TO_PIECE[piece.replace(/black|white/, "").split("_")[0]],
		width: "calc(var(--piece-size, var(--size)) * 0.9)",
		fillColor: "currentColor",
	});
}
