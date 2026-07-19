//  Pattern.swift
//  Engine
//
//  The scoring seam (ticket #4, ADR-0001): the one pure function that turns a
//  guess Word and an answer Word into a Pattern — five explicit TileMarks. It is
//  shared verbatim by forward Wordle (which shows the Pattern as feedback) and
//  this reverse game (which compares it against a Row's target). Purity is a
//  hard requirement: the generator scores the whole word list against the answer
//  thousands of times, so this must be value-in / value-out with no side effects.

/// A Pattern (glossary): exactly five TileMarks — the output of scoring a Word
/// against an answer, and the target a Row asks a player to reproduce. It is
/// always produced internally by `pattern(guess:answer:)`, never parsed from
/// untrusted input, so unlike `Word` it needs no validating boundary — the alias
/// simply lets the seam speak the domain's own word for "five marks".
public typealias Pattern = [TileMark]

/// Score a `guess` against an `answer`, returning one `TileMark` per position.
///
/// Two passes, because duplicate letters make a single left-to-right scan wrong:
///
/// 1. **Greens.** Every exact position match is a `hit`, and each hit spends one
///    copy of that letter from the answer's remaining pool. Doing this first —
///    for all five positions, before any yellow — is what lets a later duplicate
///    correctly come up gray instead of stealing the copy a green needs.
/// 2. **Yellows.** Each still-unmarked position is a `present` only while an
///    unspent copy of its letter remains in the pool, and claiming it spends
///    that copy. Otherwise the tile is a `miss`.
///
/// Gray is never a default: positions start unmarked and every one is resolved
/// explicitly to `hit`, `present`, or `miss`.
public func pattern(guess: Word, answer: Word) -> Pattern {
    let guessLetters = guess.letters
    let answerLetters = answer.letters

    var marks = [TileMark?](repeating: nil, count: Word.length)

    // The answer's letters as a multiset; passes below draw copies down to zero.
    var remaining: [Character: Int] = [:]
    for letter in answerLetters {
        remaining[letter, default: 0] += 1
    }

    // Pass 1 — greens claim their copies first, at every position.
    for position in 0..<Word.length where guessLetters[position] == answerLetters[position] {
        marks[position] = .hit
        remaining[guessLetters[position]]! -= 1
    }

    // Pass 2 — yellows, only while an unspent copy of the letter is left.
    for position in 0..<Word.length where marks[position] == nil {
        let letter = guessLetters[position]
        if let copies = remaining[letter], copies > 0 {
            marks[position] = .present
            remaining[letter] = copies - 1
        } else {
            marks[position] = .miss
        }
    }

    return marks.map { $0! }
}
