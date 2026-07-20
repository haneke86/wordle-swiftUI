//  PlayState.swift
//  Engine
//
//  The play session (#7): the player's mutable progress through one Puzzle, and
//  the rules of playing it — fully exercisable with no UI. A Puzzle is immutable
//  (an answer plus target Rows with Witnesses); PlayState layers progress on top,
//  never touching the Puzzle itself (CONTEXT.md: "Always separate from the Puzzle").
//
//  Deliberately lean: the Engine owns solved Words, the Mistake count, whether an
//  assist was used, and the active Row's revealed Hints — nothing else. The
//  player's in-progress keystrokes are a UI concern and never enter here.

/// The outcome of a submission — the trichotomy from CONTEXT.md's Mistake rule.
public enum Submission: Equatable {

    /// The submission had no effect — a non-event. Either it was absent from the
    /// Accept Set, or the Puzzle was already complete (no active Row to apply it
    /// to). Nothing changed: not the Mistake count, not the active Row.
    case nonWord

    /// A valid Word whose computed Pattern did not match the active Row's target.
    /// The Mistake count went up by one; the Row is untouched.
    case mistake

    /// The submission reproduced the active Row's target Pattern. The Row is now
    /// permanently solved and the active Row has advanced.
    case solved
}

/// One letter of the active Row's Witness, revealed by a Hint: the `letter` to
/// show and the `position` it belongs at.
public struct Reveal: Equatable {
    public let position: Int
    public let letter: Character

    public init(position: Int, letter: Character) {
        self.position = position
        self.letter = letter
    }
}

/// The state of one Row from the player's point of view. Exactly one Row is
/// `active` at a time; every Row above it is `solved` (permanently), every Row
/// below is `pending`.
public enum RowStatus: Equatable {
    case pending
    case active
    /// Solved, carrying the Word that solved it — the player's Word, or the
    /// Witness when the Row was given up.
    case solved(Word)
}

/// The player's progress through one Puzzle.
public struct PlayState {

    /// The Puzzle being played — immutable; only progress below it changes.
    public let puzzle: Puzzle

    /// The Accept Set a submission is validated against.
    private let lexicon: Lexicon

    /// The Words that solved Rows `0..<count`, in order. Because there is exactly
    /// one active Row advancing top-to-bottom, the solved Rows are always the
    /// contiguous prefix `0..<solvedWords.count` — so this array *is* the progress.
    private var solvedWords: [Word] = []

    /// How many valid-Word-but-wrong-Pattern submissions have been made. The
    /// game's only score; there is no lose state.
    public private(set) var mistakes: Int = 0

    /// Whether the player has used a Hint or give-up. Either assist voids Perfect
    /// without adding a Mistake — assists and Mistakes are separate ledgers.
    private var assisted = false

    /// The active Row's positions already revealed by a Hint. Cleared whenever the
    /// active Row advances, so reveals belong to one Row at a time.
    private var hintedPositions: Set<Int> = []

    public init(puzzle: Puzzle, lexicon: Lexicon) {
        self.puzzle = puzzle
        self.lexicon = lexicon
    }

    /// The index of the Row the player is currently on, or `nil` once every Row
    /// is solved. Solved Rows form the prefix `0..<solvedWords.count`, so the
    /// active Row is the next one down.
    public var activeRowIndex: Int? {
        solvedWords.count < puzzle.rows.count ? solvedWords.count : nil
    }

    /// `true` once every Row is solved — there is no active Row left.
    public var isComplete: Bool { activeRowIndex == nil }

    /// A Perfect (glossary, refined by #7): completed with zero Mistakes and no
    /// assist. Any Mistake, Hint, or give-up along the way voids it.
    public var isPerfect: Bool { isComplete && mistakes == 0 && !assisted }

    /// The active Row's currently revealed Hint letters, keyed by position — what
    /// the UI should show pre-filled beyond the free green tiles. Empty once the
    /// Puzzle is complete.
    public var revealedHints: [Int: Character] {
        guard let active = activeRowIndex else { return [:] }
        let witness = puzzle.rows[active].witness
        return Dictionary(uniqueKeysWithValues: hintedPositions.map { ($0, witness.letters[$0]) })
    }

    /// The status of Row `index` from the player's point of view.
    public func status(ofRow index: Int) -> RowStatus {
        if index < solvedWords.count { return .solved(solvedWords[index]) }
        if index == solvedWords.count && index < puzzle.rows.count { return .active }
        return .pending
    }

    /// Reveal the active Row's Witness letter at the next unfilled non-green
    /// position, or `nil` if the Puzzle is complete or every non-green position is
    /// already revealed. Green positions come pre-filled and are skipped. A reveal
    /// voids Perfect; a `nil` no-op does not.
    @discardableResult
    public mutating func hint() -> Reveal? {
        guard let active = activeRowIndex else { return nil }
        let row = puzzle.rows[active]

        // Leftmost non-green position not yet revealed. Green tiles are free
        // pre-fills, so a Hint never spends itself on one.
        guard let position = (0..<Word.length).first(where: { position in
            row.target[position] != .hit && !hintedPositions.contains(position)
        }) else { return nil }

        hintedPositions.insert(position)
        assisted = true
        return Reveal(position: position, letter: row.witness.letters[position])
    }

    /// Submit a Word against the active Row, returning which arm of the trichotomy
    /// it fell into. A non-word changes nothing; a wrong Pattern is one Mistake; a
    /// matching Pattern solves the Row and advances the active Row.
    @discardableResult
    public mutating func submit(_ word: Word) -> Submission {
        // A submission to a finished Puzzle, or a Word outside the Accept Set, is
        // a non-event — nothing changes either way.
        guard let active = activeRowIndex else { return .nonWord }
        guard lexicon.contains(word) else { return .nonWord }

        if pattern(guess: word, answer: puzzle.answer) == puzzle.rows[active].target {
            solve(active, with: word)
            return .solved
        } else {
            mistakes += 1
            return .mistake
        }
    }

    /// Give up the active Row: fill it with its full Witness and solve it. Adds no
    /// Mistake, but voids Perfect. A no-op once the Puzzle is complete.
    public mutating func giveUp() {
        guard let active = activeRowIndex else { return }
        assisted = true
        solve(active, with: puzzle.rows[active].witness)
    }

    /// Lock Row `index` with `word` and advance. Because there is a single active
    /// Row moving top-to-bottom, the solved Rows are the prefix `0..<count` and
    /// solving is exactly an append — a Row can never be solved out of order or
    /// re-solved.
    private mutating func solve(_ index: Int, with word: Word) {
        assert(index == solvedWords.count, "only the active Row can be solved")
        solvedWords.append(word)
        hintedPositions.removeAll()  // reveals belong to the Row just left behind
    }
}
