//  DimmingTests.swift
//  EngineTests
//
//  Dimming + green pre-fill (#8, ADR-0003): the keyboard guidance derived *only*
//  from the active Row's target Pattern and the answer — never the dictionary.
//  Each test maps to an acceptance criterion: green tiles report their forced
//  letter, yellow/gray cursors dim the answer's letter at that position, yellow
//  cursors light only the answer's letters, and the whole derivation is provably
//  blind to the Accept Set (the anti-oracle property).
//
//  Targets here are hand-built Pattern literals, not computed with
//  `pattern(guess:answer:)`: the expected pre-fill and lit/dimmed verdicts come
//  from the ADR's rules directly, so the tests are an independent source of truth
//  rather than a re-run of the code under test.

import Testing

@testable import Engine

@Suite("Dimming + green pre-fill")
struct DimmingTests {

    /// Force a canonical `Word` from a known-good literal; a typo in a fixture is
    /// a test bug and should trap loudly.
    private static func word(_ raw: String) -> Word {
        guard let word = Word(raw) else {
            fatalError("DimmingTests fixture is not a valid Word: \(raw)")
        }
        return word
    }

    /// A synthetic Lexicon whose Accept Set is exactly `accepted`. `dimming` never
    /// consults it — that is the whole point of the anti-oracle test — but a
    /// PlayState still needs one to exist.
    private static func lexicon(accepting accepted: [String]) throws -> Lexicon {
        let text = accepted.joined(separator: "\n")
        return try Lexicon(acceptText: text, answersText: text, blocklistText: "", version: "syn-dim")
    }

    /// A hand-built Puzzle whose Rows' targets are the real Patterns their
    /// Witnesses score against `answer`, so every Row is solvable by its Witness.
    private static func puzzle(answer: String, witnesses: [String]) -> Puzzle {
        let answerWord = word(answer)
        let rows = witnesses.map { witness -> Row in
            let witnessWord = word(witness)
            return Row(target: pattern(guess: witnessWord, answer: answerWord), witness: witnessWord)
        }
        return Puzzle(answer: answerWord, rows: rows)
    }

    // MARK: Acceptance criterion 1 — green tiles report their forced letter

    /// Every green (`hit`) position is pre-filled with the answer's letter there —
    /// the only letter that can score green — and every non-green position is left
    /// `nil` for the player to type into.
    @Test("Green positions report their forced letter; playable positions are nil")
    func greenPositionsReportForcedLetter() {
        // Greens at 0 and 2 → pre-fill A and C; positions 1, 3, 4 stay open.
        let target: Pattern = [.hit, .miss, .hit, .present, .miss]
        let dimming = Dimming(target: target, answer: Self.word("ABCDE"))

        #expect(dimming.prefill == ["A", nil, "C", nil, nil])
    }

    // MARK: Acceptance criterion 2 — gray cursors dim the answer's letter there

    /// At a gray (`miss`) cursor the answer's letter *at that position* is dimmed —
    /// typing it would compute green — while every other key stays lit. The rule is
    /// deliberately narrow (ADR-0003): it dims only the one letter it can prove is
    /// wrong, never the whole answer.
    @Test("A gray cursor dims only the answer's letter at that position")
    func grayCursorDimsOnlyItsAnswerLetter() {
        // Gray at position 1 (answer letter "B") and position 4 (answer letter "E").
        let target: Pattern = [.hit, .miss, .hit, .present, .miss]
        let dimming = Dimming(target: target, answer: Self.word("ABCDE"))

        #expect(dimming.keyState("B", at: 1) == .dimmed)  // answer[1]: would score green
        #expect(dimming.keyState("E", at: 4) == .dimmed)  // answer[4]: would score green

        // Everything else at a gray cursor is lit — even other answer letters and
        // absent letters; the gray rule touches only the position's own letter.
        #expect(dimming.keyState("A", at: 1) == .lit)  // an answer letter, but not answer[1]
        #expect(dimming.keyState("Z", at: 1) == .lit)  // absent from the answer entirely
    }

    /// At a yellow (`present`) cursor only the answer's own letters are lit — the
    /// letter must be somewhere in the answer to score yellow — and the answer's
    /// letter *at that position* is dimmed among them, since it would score green
    /// there instead.
    @Test("A yellow cursor lights only the answer's letters, minus the one at its position")
    func yellowCursorLightsOnlyAnswerLetters() {
        // Yellow at position 3 (answer letter "D"); answer letters are A,B,C,D,E.
        let target: Pattern = [.hit, .miss, .hit, .present, .miss]
        let dimming = Dimming(target: target, answer: Self.word("ABCDE"))

        #expect(dimming.keyState("D", at: 3) == .dimmed)  // answer[3]: would score green
        #expect(dimming.keyState("A", at: 3) == .lit)     // an answer letter elsewhere
        #expect(dimming.keyState("E", at: 3) == .lit)     // an answer letter elsewhere
        #expect(dimming.keyState("Z", at: 3) == .dimmed)  // absent → cannot score yellow
    }

    /// A green (`hit`) position is pre-filled, so the player never types there —
    /// but `keyState` stays total: at a green cursor only the forced letter is lit,
    /// mirroring the pre-fill.
    @Test("A green cursor lights only its forced letter")
    func greenCursorLightsOnlyForcedLetter() {
        // Greens at 0 (forced "A") and 2 (forced "C").
        let target: Pattern = [.hit, .miss, .hit, .present, .miss]
        let dimming = Dimming(target: target, answer: Self.word("ABCDE"))

        #expect(dimming.keyState("A", at: 0) == .lit)     // the forced letter
        #expect(dimming.keyState("C", at: 2) == .lit)     // the forced letter
        #expect(dimming.keyState("B", at: 0) == .dimmed)  // anything else is forced out
    }

    // MARK: PlayState integration — dimming follows the active Row

    /// `PlayState.dimming` derives from whichever Row is active, advancing as Rows
    /// are solved, and is `nil` once the Puzzle is complete — mirroring
    /// `revealedHints`, and never mutating progress.
    @Test("PlayState.dimming follows the active Row and is nil once complete")
    func dimmingFollowsActiveRow() throws {
        // Row 0 ("ABFGH") → [hit,hit,miss,miss,miss]; Row 1 ("AFGHI") → [hit,miss,…].
        let lexicon = try Self.lexicon(accepting: ["ABCDE", "ABFGH", "AFGHI"])
        var play = PlayState(
            puzzle: Self.puzzle(answer: "ABCDE", witnesses: ["ABFGH", "AFGHI"]),
            lexicon: lexicon
        )

        #expect(play.dimming?.prefill == ["A", "B", nil, nil, nil])  // Row 0's greens

        #expect(play.submit(Self.word("ABFGH")) == .solved)
        #expect(play.dimming?.prefill == ["A", nil, nil, nil, nil])  // Row 1's greens

        #expect(play.submit(Self.word("AFGHI")) == .solved)
        #expect(play.dimming == nil)  // complete: no active Row to guide
    }

    // MARK: Acceptance criterion 3 — the anti-oracle property

    /// The dimming for a Puzzle is identical no matter what the Accept Set holds —
    /// the reference run's guidance is byte-for-byte the same as a run whose
    /// dictionary is swapped for a disjoint one and a run whose dictionary is
    /// empty. If keyboard guidance ever leaked the Accept Set, one of these keys
    /// would differ; none can, because `Dimming` is a pure function of the target
    /// Pattern and the answer alone (ADR-0003).
    @Test("Dimming is identical under a swapped or empty dictionary")
    func dimmingIsBlindToTheDictionary() throws {
        // Witness "ABZCD" vs "ABCDE" → [hit,hit,miss,present,present]: the target
        // exercises a green, a gray, and a yellow cursor in one Row.
        let puzzle = Self.puzzle(answer: "ABCDE", witnesses: ["ABZCD"])

        let reference = PlayState(puzzle: puzzle, lexicon: try Self.lexicon(accepting: ["ABCDE", "ABZCD"]))
        let swapped = PlayState(puzzle: puzzle, lexicon: try Self.lexicon(accepting: ["OKPRS", "MNVYZ"]))
        let empty = PlayState(puzzle: puzzle, lexicon: try Self.lexicon(accepting: []))

        // Whole-value identity: same target, same answer ⇒ equal Dimming.
        #expect(reference.dimming == swapped.dimming)
        #expect(reference.dimming == empty.dimming)

        // And key-by-key across the entire keyboard at every cursor, so a future
        // dictionary-aware code path could not slip through Equatable.
        let reference0 = try #require(reference.dimming)
        for variant in [swapped, empty] {
            let variant0 = try #require(variant.dimming)
            #expect(variant0.prefill == reference0.prefill)
            for cursor in 0..<Word.length {
                for letter in TurkishAlphabet.canonicalLetters {
                    #expect(
                        variant0.keyState(letter, at: cursor) == reference0.keyState(letter, at: cursor),
                        "key \(letter) at cursor \(cursor) diverged under a changed dictionary"
                    )
                }
            }
        }
    }
}
