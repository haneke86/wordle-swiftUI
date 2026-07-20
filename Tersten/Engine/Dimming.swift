//  Dimming.swift
//  Engine
//
//  Keyboard guidance for the active Row (#8, ADR-0003): green pre-fill and
//  cursor dimming, derived *only* from the Row's target Pattern and the answer —
//  never from the Accept Set. This is a game-economy boundary, not a technical
//  gap: exact, dictionary-aware dimming would light only letters on a path to a
//  valid completion, making Mistakes impossible and Hints worthless (ADR-0003).
//
//  The derivation is a pure value: constructed from `(target, answer)` and asked
//  about a cursor position, it never touches a Lexicon or mutates PlayState. That
//  the type's interface has no dictionary in it is the anti-oracle property made
//  structural — there is simply no seam through which the Accept Set could leak in.

/// The keyboard verdict for one letter at the cursor: whether the local rule
/// (target Pattern + answer only) considers it a plausible keystroke there.
///
/// - `lit`: the letter *could* produce the mark the target requires at the cursor.
/// - `dimmed`: it cannot — typing it would compute a different mark — so the
///   keyboard discourages it. Never a claim that a word exists; only a local,
///   dictionary-blind judgement about this one position.
public enum KeyState: Equatable {
    case lit
    case dimmed
}

/// Keyboard guidance for one active Row, derived only from its target Pattern and
/// the answer (ADR-0003). Two outputs: the green pre-fill (which positions are
/// forced, and to what letter) and, at a given cursor, which keys to dim.
///
/// Pure and progress-free: equal `(target, answer)` inputs yield an equal Dimming,
/// and nothing here reads the Accept Set or writes PlayState.
public struct Dimming: Equatable {

    /// The active Row's target Pattern — the five marks the player must reproduce.
    private let target: Pattern

    /// The answer the Row was scored against. Its letters are the only letters the
    /// derivation ever names: the forced pre-fills and the yellow "light only these"
    /// set both come from here, so guidance can never point past the answer.
    private let answer: Word

    /// The forced letter at each position, or `nil` where the player must type. A
    /// position is forced exactly when its target mark is `hit` (green): the only
    /// letter that scores green at position `i` is the answer's letter there, so it
    /// is pre-filled and the player never types into it.
    public let prefill: [Character?]

    public init(target: Pattern, answer: Word) {
        self.target = target
        self.answer = answer
        self.prefill = (0..<Word.length).map { position in
            target[position] == .hit ? answer.letters[position] : nil
        }
    }

    /// The keyboard verdict for typing `letter` at `cursor` — see `KeyState`. A
    /// pure function of the target Pattern and the answer at the cursor; the
    /// Accept Set is never consulted.
    public func keyState(_ letter: Character, at cursor: Int) -> KeyState {
        switch target[cursor] {
        case .miss:
            // Gray: only the answer's own letter here is provably wrong (it would
            // score green). Dim exactly that one letter; leave the rest lit.
            return letter == answer.letters[cursor] ? .dimmed : .lit
        case .present:
            // Yellow: the letter must appear somewhere in the answer to score
            // yellow, so light only the answer's letters — and dim its letter at
            // this position, which would score green here instead.
            if letter == answer.letters[cursor] { return .dimmed }
            return answer.letters.contains(letter) ? .lit : .dimmed
        case .hit:
            // Green: the position is forced to the answer's letter (it is pre-filled
            // and never typed), so only that letter is lit here.
            return letter == answer.letters[cursor] ? .lit : .dimmed
        }
    }
}
