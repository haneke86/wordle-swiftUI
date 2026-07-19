//  PatternTests.swift
//  EngineTests
//
//  The scoring seam (ticket #4): `pattern(guess:answer:)` is the single pure
//  function shared by forward Wordle (feedback generator) and this game (Word
//  validator). Its whole subtlety is duplicate letters, so the suite is
//  table-driven: each row states a guess, an answer, and the expected five-mark
//  Pattern encoded as H (hit / green), P (present / yellow), M (miss / gray).
//
//  Inputs are canonical five-letter Words, not necessarily Answer Pool words —
//  scoring is pure letter-multiset arithmetic and knows nothing about the
//  dictionary.

import Testing

@testable import Engine

@Suite("pattern(guess:answer:) scoring seam")
struct PatternTests {

    /// Decode a compact "HPMMM"-style spec into the expected marks. Fails loudly
    /// on any character that is not H/P/M so a typo in a table can't masquerade
    /// as a passing expectation.
    private static func marks(_ spec: String) -> [TileMark] {
        spec.map {
            switch $0 {
            case "H": return .hit
            case "P": return .present
            case "M": return .miss
            default: fatalError("bad mark spec: \($0)")
            }
        }
    }

    // MARK: Baselines

    @Test(
        "Whole-row baselines: all green, all gray, all yellow (anagram)",
        arguments: [
            ("KEBAP", "KEBAP", "HHHHH"),  // identical → every tile a hit
            ("KEBAP", "TOZLU", "MMMMM"),  // no shared letters → every tile a miss
            ("ARISK", "KARIS", "PPPPP"),  // same letters, every one displaced → all present
        ]
    )
    func baselines(_ guess: String, _ answer: String, _ expected: String) throws {
        try expectPattern(guess: guess, answer: answer, equals: expected)
    }

    // MARK: Duplicate letters

    /// Double letter in the *guess* against a single copy in the answer.
    @Test(
        "Duplicate in guess vs single in answer",
        arguments: [
            // green + gray: K is a hit at 0, so K at 2 finds no copy left → gray.
            ("KAKAO", "KATIR", "HHMMM"),
            // yellow + gray: A has no hit anywhere, so the first A claims the lone
            // copy (yellow) and every later A is gray.
            ("ADANA", "KATIR", "PMMMM"),
        ]
    )
    func duplicateInGuess(_ guess: String, _ answer: String, _ expected: String) throws {
        try expectPattern(guess: guess, answer: answer, equals: expected)
    }

    /// Double letter in the *answer* against a single copy in the guess: the lone
    /// guess copy earns exactly one mark; the answer's spare copy is never
    /// invented into a second yellow.
    @Test("Duplicate in answer vs single in guess")
    func duplicateInAnswer() throws {
        // ADRES has one A (pos 0); TABAK has two A's. The single guess A yields a
        // single yellow — not two — and nothing else lands.
        try expectPattern(guess: "ADRES", answer: "TABAK", equals: "PMMMM")
    }

    /// Greens must claim their letter-copies before any yellow is handed out,
    /// regardless of position. A left-of-green duplicate would be a yellow under
    /// naive left-to-right scanning; two-pass scoring makes it gray.
    @Test("Greens consume counts before yellows are assigned")
    func greensConsumeBeforeYellows() throws {
        // SEDİR has one E (pos 1). EEDİR matches it at pos 1 (hit) and repeats E
        // at pos 0. The hit spends the only E, so pos 0 is gray — not yellow.
        try expectPattern(guess: "EEDİR", answer: "SEDİR", equals: "MHHHH")
    }

    /// The same letter wearing two colors in one row: doubled in both guess and
    /// answer, one copy lands as a hit and the leftover copy as a present.
    @Test("Same letter scores as both hit and present")
    func sameLetterTwoColors() throws {
        // HAMAM has M at 2 and 4. MAMUL has M at 0 and 2: the pos-2 M is a hit,
        // which leaves one M copy for the pos-0 M to claim as a present.
        try expectPattern(guess: "MAMUL", answer: "HAMAM", equals: "PHHMM")
    }

    // MARK: Shape and purity

    /// Every result is exactly five marks with gray represented explicitly — a
    /// Pattern is never short, never padded, never nil-for-gray.
    @Test(
        "Output is always exactly five explicit marks",
        arguments: [
            ("KEBAP", "KEBAP"), ("KEBAP", "TOZLU"),
            ("KAKAO", "KATIR"), ("MAMUL", "HAMAM"),
        ]
    )
    func alwaysFiveMarks(_ guess: String, _ answer: String) throws {
        let g = try #require(Word(guess))
        let a = try #require(Word(answer))
        let result = pattern(guess: g, answer: a)
        #expect(result.count == Word.length)
    }

    /// Pure: value types in, value out, no observable side effects. Scoring the
    /// same inputs twice yields equal Patterns, and neither Word is mutated —
    /// the prerequisite for calling this thousands of times during generation.
    @Test("Scoring is pure and deterministic")
    func isPure() throws {
        let g = try #require(Word("MAMUL"))
        let a = try #require(Word("HAMAM"))

        let first = pattern(guess: g, answer: a)
        let second = pattern(guess: g, answer: a)

        #expect(first == second)
        #expect(g.string == "MAMUL")
        #expect(a.string == "HAMAM")
    }

    // MARK: Helper

    private func expectPattern(
        guess: String,
        answer: String,
        equals spec: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let g = try #require(Word(guess), sourceLocation: sourceLocation)
        let a = try #require(Word(answer), sourceLocation: sourceLocation)
        #expect(
            pattern(guess: g, answer: a) == Self.marks(spec),
            "guess \(guess) vs answer \(answer)",
            sourceLocation: sourceLocation
        )
    }
}
