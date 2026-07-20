//  Puzzle.swift
//  Engine
//
//  The Puzzle model (#6): the immutable, generated artifact the game loop
//  consumes. A Puzzle is an answer Word plus an ordered list of Rows, each a
//  target Pattern paired with a Witness that proves the target is reachable
//  (ADR-0001, words-first). It carries no player progress — which Rows are solved
//  with which Words lives in PlayState, a separate concern layered on top.

/// One Row of a Puzzle: a target Pattern the player must reproduce, and a
/// Witness — a real Word that reproduces it.
///
/// The Witness is *a* solution, never *the* solution: it is the generator's
/// proof that the target is solvable (every shipped Row carries one), and it is
/// what powers Hints and give-up. The playable states a Row moves through while
/// someone solves it (`pending` → `active` → `solved`) are player progress and
/// belong to PlayState, not to this immutable value.
public struct Row: Equatable, Hashable {

    /// The five-mark Pattern the player must reproduce for this Row.
    public let target: Pattern

    /// A Word that reproduces `target` when scored against the Puzzle's answer.
    public let witness: Word

    public init(target: Pattern, witness: Word) {
        self.target = target
        self.witness = witness
    }
}

/// A Puzzle: an answer Word and the ordered Rows leading up to it.
///
/// Immutable and progress-free by construction — regenerating the same
/// `(date, list version)` yields an equal Puzzle (ADR-0004), and two devices
/// therefore agree without a server. The bottom Answer Row (the answer shown
/// fully green) is display-only and is *not* one of these Rows: `rows` holds
/// exactly the playable lines.
public struct Puzzle: Equatable, Hashable {

    /// The answer every Row's Pattern was scored against, and the word revealed
    /// fully green in the display-only Answer Row.
    public let answer: Word

    /// The playable Rows, ordered top-to-bottom. Green (hit) counts are
    /// non-decreasing down this list, so the grid reads like a real game
    /// converging on the answer (ADR-0001). A Puzzle has 3–5 Rows.
    public let rows: [Row]

    public init(answer: Word, rows: [Row]) {
        self.answer = answer
        self.rows = rows
    }
}
