## Gless

- install gleam and bun from mise
- bun install
- bun dev

## Project Goal (AI written)

This is a playable chess board, not a rules engine. It does not attempt to
detect every illegal move. **However, any rule that it does enforce must be
enforced correctly.** If you find a case where the board rejects a legal move or
allows an illegal one that it claims to detect, that's a bug.

## Feature Status (AI written)

### Present

- Interactive board rendering with Preact + Gleam
- Click-to-select, click-to-move piece interaction
- Move highlighting for valid destinations
- Turn-based piece selection (you can only move your own color)
- Visual check indicators
- Pawn movement: 1 step, 2 steps from starting rank
- Pawn diagonal captures
- Knight L-shaped movement (jumps over pieces)
- Bishop diagonal sliding
- Rook orthogonal sliding
- Queen combined sliding (bishop + rook)
- King 1-step movement in all directions
- Basic castling logic for kingside and queenside
- Piece capture (pieces move to taken area)
- Theme switcher with localStorage persistence (wood, sky, cyberpunk)
- Responsive CSS with container queries

### Known Gaps / Not Implemented

- No pawn promotion (pawns reaching the end do nothing)
- No en passant
- No checkmate or stalemate detection
- No move history / undo
- No turn enforcement (both players can move any color)
- No discovered check validation for non-king pieces (you can expose your own
  king)
- No "king cannot move into check" validation after the move resolves
- No unique piece IDs (promoted pieces may share identity with existing ones)
- No clock / timer
- No move notation export
- Accessibility: pieces are divs, not keyboard-navigable buttons

### Images

<img width="786" height="786" alt="image" src="https://github.com/user-attachments/assets/8a3c2917-022a-45a2-960a-cfd8dc8ae0b4" />
