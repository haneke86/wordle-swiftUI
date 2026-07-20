//  PlayStateTests.swift
//  EngineTests
//
//  The play session (#7): PlayState and the rules of playing a Puzzle, exercised
//  entirely through the Engine's public interface with no UI. Each test maps to an
//  acceptance criterion from the ticket — the submission trichotomy, permanent
//  solved Rows, non-Witness solutions, Hint / give-up behaviour, and Perfect.
//
//  Puzzles here are hand-built with `Puzzle.init` from a small synthetic Lexicon:
//  targets are *computed* with the real `pattern(guess:answer:)` so they are
//  honest, but the layout is chosen to make each rule easy to provoke in isolation
//  (the generator's own invariants are already covered by PuzzleTests).

import Foundation
import Testing

@testable import Engine

@Suite("Play session engine")
struct PlayStateTests {

    // MARK: Fixtures

    /// Force a canonical `Word` from a known-good literal; a typo in a fixture is
    /// a test bug and should trap loudly.
    private static func word(_ raw: String) -> Word {
        guard let word = Word(raw) else {
            fatalError("PlayStateTests fixture is not a valid Word: \(raw)")
        }
        return word
    }

    /// A synthetic Lexicon whose Accept Set is exactly `accepted` (all its own
    /// answers, no blocklist). Membership is all PlayState asks of a Lexicon.
    private static func lexicon(accepting accepted: [String]) throws -> Lexicon {
        let text = accepted.joined(separator: "\n")
        return try Lexicon(
            acceptText: text,
            answersText: text,
            blocklistText: "",
            version: "syn-play"
        )
    }

    /// A hand-built Puzzle: each Witness's target is the real Pattern it scores
    /// against `answer`, so every Row is solvable by its Witness by construction.
    private static func puzzle(answer: String, witnesses: [String]) -> Puzzle {
        let answerWord = word(answer)
        let rows = witnesses.map { witness -> Row in
            let witnessWord = word(witness)
            return Row(target: pattern(guess: witnessWord, answer: answerWord), witness: witnessWord)
        }
        return Puzzle(answer: answerWord, rows: rows)
    }

    // MARK: Acceptance criterion 1 — the submission trichotomy

    /// First arm: a submission absent from the Accept Set is a non-event. The
    /// Mistake count does not move and the active Row does not advance.
    @Test("A non-word submission changes nothing")
    func nonWordIsNonEvent() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "AFGHI"])
        var play = PlayState(puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["AFGHI"]), lexicon: lexicon)

        // "ZKLMN" is a valid Word shape but was never added to the Accept Set.
        let outcome = play.submit(Self.word("ZKLMN"))

        #expect(outcome == .nonWord)
        #expect(play.mistakes == 0)
        #expect(play.activeRowIndex == 0)
        #expect(play.status(ofRow: 0) == .active)
    }

    /// Second arm: a valid Word whose computed Pattern misses the target costs one
    /// Mistake, and leaves the Row unsolved and active.
    @Test("A valid Word with the wrong Pattern is one Mistake")
    func wrongPatternIsMistake() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "AFGHI", "FGHIA"])
        var play = PlayState(puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["AFGHI"]), lexicon: lexicon)

        // "FGHIA" scores [miss,miss,miss,miss,present] against "ABCDE" — not the
        // Row's [hit,miss,miss,miss,miss] target.
        let outcome = play.submit(Self.word("FGHIA"))

        #expect(outcome == .mistake)
        #expect(play.mistakes == 1)
        #expect(play.activeRowIndex == 0)
        #expect(play.status(ofRow: 0) == .active)
    }

    /// Third arm: a Word reproducing the target solves the Row and advances the
    /// active Row one step down. The Row records the Word that solved it.
    @Test("A matching Pattern solves the Row and advances")
    func matchingPatternSolvesAndAdvances() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "AFGHI", "ABFGH"])
        var play = PlayState(
            puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["AFGHI", "ABFGH"]),
            lexicon: lexicon
        )

        let outcome = play.submit(Self.word("AFGHI"))

        #expect(outcome == .solved)
        #expect(play.status(ofRow: 0) == .solved(Self.word("AFGHI")))
        #expect(play.activeRowIndex == 1)
        #expect(play.status(ofRow: 1) == .active)
        #expect(play.mistakes == 0)
    }

    // MARK: Acceptance criterion — any Accept Set word reproducing the target wins

    /// A Word that is *not* the Witness but reproduces the target Pattern still
    /// solves the Row, and the Row records that Word — the game validates Patterns,
    /// never identity against the Witness.
    @Test("A non-Witness word that reproduces the target solves the Row")
    func nonWitnessSolutionIsAccepted() throws {
        // "AFGHJ" and the Witness "AFGHI" both score [hit,miss,miss,miss,miss]
        // against "ABCDE", yet are different Words.
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "AFGHI", "AFGHJ"])
        var play = PlayState(puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["AFGHI"]), lexicon: lexicon)

        let outcome = play.submit(Self.word("AFGHJ"))

        #expect(outcome == .solved)
        #expect(play.status(ofRow: 0) == .solved(Self.word("AFGHJ")))
        #expect(play.activeRowIndex == nil)
    }

    // MARK: Acceptance criterion 2 — a solved Row is permanent

    /// Once solved, a Row's recorded Word survives every later action. Because
    /// actions only ever reach the single active Row, a Row above it can be
    /// neither re-solved nor overwritten.
    @Test("A solved Row is untouched by subsequent submissions")
    func solvedRowIsPermanent() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "AFGHI", "ABFGH", "FGHIA"])
        var play = PlayState(
            puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["AFGHI", "ABFGH"]),
            lexicon: lexicon
        )

        #expect(play.submit(Self.word("AFGHI")) == .solved)  // Row 0 solved
        #expect(play.status(ofRow: 0) == .solved(Self.word("AFGHI")))

        // Everything after this targets the active Row (Row 1), never Row 0:
        #expect(play.submit(Self.word("FGHIA")) == .mistake)  // wrong Pattern for Row 1
        #expect(play.submit(Self.word("AFGHI")) == .mistake)  // Row 0's Pattern ≠ Row 1's target
        #expect(play.status(ofRow: 0) == .solved(Self.word("AFGHI")))  // still Row 0's original Word

        #expect(play.submit(Self.word("ABFGH")) == .solved)  // Row 1 solved
        #expect(play.status(ofRow: 0) == .solved(Self.word("AFGHI")))  // Row 0 unchanged by Row 1's solve
        #expect(play.status(ofRow: 1) == .solved(Self.word("ABFGH")))
    }

    // MARK: Acceptance criterion 4 — completion and Perfect

    /// Solving every Row completes the Puzzle: there is no active Row left, and a
    /// clean run (no Mistakes, no assists) is Perfect.
    @Test("A clean run completes the Puzzle and is Perfect")
    func cleanRunIsPerfect() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "AFGHI", "ABFGH"])
        var play = PlayState(
            puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["AFGHI", "ABFGH"]),
            lexicon: lexicon
        )

        #expect(!play.isComplete)
        play.submit(Self.word("AFGHI"))
        play.submit(Self.word("ABFGH"))

        #expect(play.isComplete)
        #expect(play.activeRowIndex == nil)
        #expect(play.isPerfect)
    }

    /// A Mistake anywhere voids Perfect, even though the Puzzle still completes —
    /// there is no lose state, only the loss of a Perfect.
    @Test("A Mistake voids Perfect but not completion")
    func mistakeVoidsPerfect() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "AFGHI", "ABFGH", "FGHIA"])
        var play = PlayState(
            puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["AFGHI", "ABFGH"]),
            lexicon: lexicon
        )

        play.submit(Self.word("FGHIA"))  // one Mistake on Row 0
        play.submit(Self.word("AFGHI"))  // then solve it
        play.submit(Self.word("ABFGH"))  // solve Row 1

        #expect(play.isComplete)
        #expect(play.mistakes == 1)
        #expect(!play.isPerfect)
    }

    // MARK: Acceptance criterion 4 — Hint

    /// Hint walks the active Row's non-green positions left to right, revealing the
    /// Witness's letter at each and skipping the pre-filled green positions.
    /// Reveals accumulate, and once all non-green positions are shown it returns
    /// `nil` and changes nothing.
    @Test("Hint reveals the Witness's non-green letters left to right")
    func hintRevealsNonGreenLetters() throws {
        // "ABFGH" vs "ABCDE" → [hit,hit,miss,miss,miss]; greens at 0,1 are skipped,
        // so hints reveal F,G,H at positions 2,3,4.
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "ABFGH"])
        var play = PlayState(puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["ABFGH"]), lexicon: lexicon)

        #expect(play.hint() == Reveal(position: 2, letter: "F"))
        #expect(play.revealedHints == [2: "F"])
        #expect(play.hint() == Reveal(position: 3, letter: "G"))
        #expect(play.hint() == Reveal(position: 4, letter: "H"))
        #expect(play.revealedHints == [2: "F", 3: "G", 4: "H"])

        #expect(play.hint() == nil)  // nothing left to reveal
        #expect(play.revealedHints == [2: "F", 3: "G", 4: "H"])
    }

    /// A Hint voids Perfect without adding a Mistake — a flawless-but-assisted run
    /// completes, but is not Perfect.
    @Test("A Hint voids Perfect without adding a Mistake")
    func hintVoidsPerfect() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "ABFGH"])
        var play = PlayState(puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["ABFGH"]), lexicon: lexicon)

        _ = play.hint()
        play.submit(Self.word("ABFGH"))

        #expect(play.isComplete)
        #expect(play.mistakes == 0)
        #expect(!play.isPerfect)
    }

    /// Revealed Hints belong to the active Row alone: when it advances, the next
    /// Row starts with a clean slate.
    @Test("Revealed Hints reset when the active Row advances")
    func hintsResetOnAdvance() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "AFGHI", "ABFGH"])
        var play = PlayState(
            puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["AFGHI", "ABFGH"]),
            lexicon: lexicon
        )

        _ = play.hint()
        #expect(!play.revealedHints.isEmpty)

        play.submit(Self.word("AFGHI"))  // solve Row 0, advance to Row 1
        #expect(play.revealedHints.isEmpty)
    }

    /// A Hint with nothing to reveal — the Puzzle is already complete — is a true
    /// no-op: it returns `nil` and does not void a Perfect already earned.
    @Test("A no-op Hint does not void Perfect")
    func noOpHintKeepsPerfect() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "ABFGH"])
        var play = PlayState(puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["ABFGH"]), lexicon: lexicon)

        play.submit(Self.word("ABFGH"))
        #expect(play.isPerfect)

        #expect(play.hint() == nil)
        #expect(play.isPerfect)
    }

    // MARK: Acceptance criterion 4 — give-up

    /// Give-up fills the active Row with its full Witness and solves it, advancing
    /// the active Row. It adds no Mistake, but voids Perfect.
    @Test("Give-up solves the active Row with its Witness and voids Perfect")
    func giveUpSolvesWithWitnessAndVoidsPerfect() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "AFGHI", "ABFGH"])
        var play = PlayState(
            puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["AFGHI", "ABFGH"]),
            lexicon: lexicon
        )

        play.giveUp()  // give up Row 0

        #expect(play.status(ofRow: 0) == .solved(Self.word("AFGHI")))  // solved with its Witness
        #expect(play.activeRowIndex == 1)
        #expect(play.mistakes == 0)

        play.submit(Self.word("ABFGH"))  // finish Row 1 cleanly
        #expect(play.isComplete)
        #expect(!play.isPerfect)  // the give-up voided Perfect
    }

    /// Give-up on a completed Puzzle has no Row to fill: it changes nothing and
    /// does not void a Perfect already earned.
    @Test("Give-up on a completed Puzzle is a no-op")
    func giveUpWhenCompleteIsNoOp() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "ABFGH"])
        var play = PlayState(puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["ABFGH"]), lexicon: lexicon)

        play.submit(Self.word("ABFGH"))
        #expect(play.isPerfect)

        play.giveUp()
        #expect(play.isComplete)
        #expect(play.isPerfect)
    }

    /// Submitting once every Row is solved is a non-event: there is no active Row
    /// to apply the Word to, so nothing changes and an earned Perfect stands —
    /// even for a Word that is in the Accept Set.
    @Test("A submission after completion is a non-event")
    func submitAfterCompletionIsNonEvent() throws {
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "ABFGH"])
        var play = PlayState(puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["ABFGH"]), lexicon: lexicon)

        play.submit(Self.word("ABFGH"))
        #expect(play.isComplete)
        #expect(play.isPerfect)

        #expect(play.submit(Self.word("ABFGH")) == .nonWord)  // accepted, but no Row to receive it
        #expect(play.mistakes == 0)
        #expect(play.isComplete)
        #expect(play.isPerfect)
    }

    // MARK: Acceptance criterion 5 — a full Puzzle is playable end-to-end

    /// A real generated Daily Puzzle is solvable start-to-finish using only
    /// PlayState's public interface: submitting each Row's Witness in order solves
    /// every Row and reaches a Perfect completion. This is the whole engine wired
    /// together on real 3–5 Row puzzles from the bundled Lexicon.
    @Test("A full Daily Puzzle plays to a Perfect completion through the public API")
    func fullDailyPuzzleIsPlayable() {
        let lexicon = Lexicon.bundled()
        for day in [0, 1, 42, 365, 1000] {
            let puzzle = Puzzle.daily(dayNumber: day, lexicon: lexicon)
            var play = PlayState(puzzle: puzzle, lexicon: lexicon)

            for index in puzzle.rows.indices {
                #expect(play.activeRowIndex == index)
                #expect(play.submit(puzzle.rows[index].witness) == .solved)
            }

            #expect(play.isComplete)
            #expect(play.activeRowIndex == nil)
            #expect(play.isPerfect)
        }
    }
}
