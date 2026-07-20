//  PuzzleTests.swift
//  EngineTests
//
//  The Puzzle model + deterministic Daily generator (#6, ADR-0001 & ADR-0004).
//  The generator is words-first: it samples real Answer Pool words and *computes*
//  their Patterns, so every Row is solvable by construction. These are property
//  tests — they assert the invariants hold across a wide sweep of day numbers
//  rather than pinning one hand-worked puzzle, because the generator's contract
//  is a set of guarantees, not a single fixed output.
//
//  The bulk of the sweep runs against the real bundled Lexicon (~5.5k words) so
//  sampling is realistic; a handful of synthetic lexicons cover the small-pool
//  edge and prove the List Version feeds the seed.

import Foundation
import Testing

@testable import Engine

@Suite("Puzzle model + Daily generator")
struct PuzzleTests {

    /// How many consecutive day numbers each property sweep covers.
    private static let sweep = 0..<200

    /// Count the green (hit) tiles in a Pattern.
    private static func greens(_ pattern: Pattern) -> Int {
        pattern.filter { $0 == .hit }.count
    }

    /// A synthetic Lexicon of `wordCount` distinct canonical words at `version`.
    /// Words are the base-23 encodings of `0..<wordCount` over a Q/W/X-free slice
    /// of the alphabet, so each index yields a distinct valid five-letter Word.
    /// The accept and answers lists are identical (every word is its own answer),
    /// which keeps the answers ⊆ accept invariant and leaves the whole list as
    /// the Answer Pool.
    private static func syntheticLexicon(wordCount: Int, version: String) throws -> Lexicon {
        let letters = Array("ABCDEFGHIJKLMNOPRSTUVYZ")  // 23 canonical letters
        let base = letters.count
        let words = (0..<wordCount).map { index -> String in
            var remainder = index
            var characters: [Character] = []
            for _ in 0..<Word.length {
                characters.append(letters[remainder % base])
                remainder /= base
            }
            return String(characters)
        }
        let text = words.joined(separator: "\n")
        return try Lexicon(
            acceptText: text,
            answersText: text,
            blocklistText: "",
            version: version
        )
    }

    // MARK: Acceptance criterion 1 — Witnesses realize their targets

    /// Every Row's Witness, scored against the answer, reproduces exactly the
    /// Row's target Pattern. This is the words-first guarantee (ADR-0001): the
    /// puzzle is solvable by construction because each target *is* the Pattern of
    /// a real word the generator kept as proof.
    @Test("Every Row's Witness reproduces its target Pattern")
    func witnessReproducesTarget() {
        let lexicon = Lexicon.bundled()
        for day in Self.sweep {
            let puzzle = Puzzle.daily(dayNumber: day, lexicon: lexicon)
            for row in puzzle.rows {
                #expect(pattern(guess: row.witness, answer: puzzle.answer) == row.target)
            }
        }
    }

    // MARK: Acceptance criterion 2 — structural invariants

    /// Green counts never decrease from one Row to the next, so the grid reads as
    /// a game converging on the answer (ADR-0001).
    @Test("Green counts are non-decreasing top to bottom")
    func greensNonDecreasing() {
        let lexicon = Lexicon.bundled()
        for day in Self.sweep {
            let puzzle = Puzzle.daily(dayNumber: day, lexicon: lexicon)
            let hits = puzzle.rows.map { Self.greens($0.target) }
            #expect(hits == hits.sorted())
        }
    }

    /// Every Puzzle has between three and five Rows.
    @Test("Row count is always 3 to 5")
    func rowCountInRange() {
        let lexicon = Lexicon.bundled()
        for day in Self.sweep {
            let puzzle = Puzzle.daily(dayNumber: day, lexicon: lexicon)
            #expect((3...5).contains(puzzle.rows.count))
        }
    }

    /// The answer and every Witness are members of the Answer Pool — the only
    /// pool whose words the game may show.
    @Test("Answer and every Witness are drawn from the Answer Pool")
    func drawnFromAnswerPool() {
        let lexicon = Lexicon.bundled()
        let pool = Set(lexicon.answerPool)
        for day in Self.sweep {
            let puzzle = Puzzle.daily(dayNumber: day, lexicon: lexicon)
            #expect(pool.contains(puzzle.answer))
            for row in puzzle.rows {
                #expect(pool.contains(row.witness))
            }
        }
    }

    /// The answer is never itself sampled as a Row's Witness — the only all-green
    /// line is the display-only Answer Row, never a playable Row.
    @Test("The answer is never used as a Witness")
    func answerNeverWitness() {
        let lexicon = Lexicon.bundled()
        for day in Self.sweep {
            let puzzle = Puzzle.daily(dayNumber: day, lexicon: lexicon)
            for row in puzzle.rows {
                #expect(row.witness != puzzle.answer)
            }
        }
    }

    /// A Puzzle never repeats a Witness — two identical Rows would be a
    /// degenerate grid, and distinct-by-value sampling rules it out.
    @Test("Witnesses within a Puzzle are distinct")
    func witnessesDistinct() {
        let lexicon = Lexicon.bundled()
        for day in Self.sweep {
            let puzzle = Puzzle.daily(dayNumber: day, lexicon: lexicon)
            let witnesses = puzzle.rows.map { $0.witness }
            #expect(Set(witnesses).count == witnesses.count)
        }
    }

    // MARK: Acceptance criterion 3 — determinism

    /// Equal `(dayNumber, list version)` yields byte-identical Puzzles, even
    /// across independently-built Lexicon instances at the same version. This is
    /// what lets two devices agree on the day's puzzle with no server (ADR-0004).
    ///
    /// It doubles as the regression guard for "no system RNG in generation": a
    /// freshly-seeded `SystemRandomNumberGenerator` would make two runs diverge,
    /// so this would fail the moment one crept into the generation path. (The
    /// clock half of that rule is prevented structurally — the generator takes a
    /// `dayNumber` and imports no Foundation, so it has no clock to read.)
    @Test("Equal inputs yield identical Puzzles across runs and Lexicon instances")
    func deterministicForEqualInputs() {
        for day in [0, 1, 42, 365, 1000] {
            let first = Puzzle.daily(dayNumber: day, lexicon: Lexicon.bundled())
            let second = Puzzle.daily(dayNumber: day, lexicon: Lexicon.bundled())
            #expect(first == second)
        }
    }

    /// Different day numbers yield different Puzzles: adjacent days differ, and a
    /// broad window stays highly diverse — a guard against a seed that only
    /// stirs the low bits and cycles quickly.
    @Test("Different day numbers yield different Puzzles")
    func differentDaysDiffer() {
        let lexicon = Lexicon.bundled()
        #expect(
            Puzzle.daily(dayNumber: 0, lexicon: lexicon)
                != Puzzle.daily(dayNumber: 1, lexicon: lexicon)
        )
        let window = (0..<64).map { Puzzle.daily(dayNumber: $0, lexicon: lexicon) }
        #expect(Set(window).count >= 50)
    }

    /// The List Version feeds the seed: the same words under two different
    /// versions produce a different run of daily Puzzles, so a list edit (which
    /// bumps the version) reshuffles future dailies as ADR-0004 requires.
    @Test("List Version participates in the seed")
    func versionAffectsGeneration() throws {
        let lexiconA = try Self.syntheticLexicon(wordCount: 300, version: "syn-vA")
        let lexiconB = try Self.syntheticLexicon(wordCount: 300, version: "syn-vB")
        let runA = (0..<10).map { Puzzle.daily(dayNumber: $0, lexicon: lexiconA) }
        let runB = (0..<10).map { Puzzle.daily(dayNumber: $0, lexicon: lexiconB) }
        #expect(runA != runB)
    }

    // MARK: Edge — minimally-sized pool

    /// Six distinct words is the tight case: excluding the answer leaves exactly
    /// five candidate Witnesses, matching the maximum Row count. Generation still
    /// upholds every invariant.
    @Test("Generates a valid Puzzle from a minimally-sized Answer Pool")
    func minimallySizedPool() throws {
        let lexicon = try Self.syntheticLexicon(wordCount: 6, version: "syn-min")
        for day in 0..<50 {
            let puzzle = Puzzle.daily(dayNumber: day, lexicon: lexicon)
            #expect((3...5).contains(puzzle.rows.count))
            #expect(!puzzle.rows.contains { $0.witness == puzzle.answer })
            for row in puzzle.rows {
                #expect(pattern(guess: row.witness, answer: puzzle.answer) == row.target)
            }
        }
    }
}
