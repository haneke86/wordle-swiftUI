//  TileMark.swift
//  Engine
//
//  The color verdict for one tile — the atom of a Pattern (glossary). Gray is a
//  first-class case (`miss`), never the absence of a value: every tile a Word
//  scores against an answer gets an explicit verdict.

/// The color verdict for a single tile.
///
/// - `hit`: right letter, right place (green).
/// - `present`: right letter, wrong place, and an unused copy remained (yellow).
/// - `miss`: the letter is spent or absent (gray).
///
/// `miss` is explicit by design: `pattern(guess:answer:)` fills all five tiles,
/// so a gray tile is a decision the scorer made, not a default it fell back to.
public enum TileMark: Equatable, Hashable, Sendable {
    case hit
    case present
    case miss
}
