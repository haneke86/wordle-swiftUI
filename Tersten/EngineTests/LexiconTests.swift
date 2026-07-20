//  LexiconTests.swift
//  EngineTests
//
//  The Lexicon ingestion seam (#15): the pure initializer over raw text builds
//  the Accept Set and the ordered Answer Pool. Every behavior below is asserted
//  through Lexicon's public interface — membership, the pool, loud failure, the
//  version — never against its backing storage. The pure init lets each case run
//  on tiny in-memory lists, so no multi-thousand-word bundle is needed to prove
//  the ingestion rules; a single smoke test covers the real bundle separately.

import Foundation
import Testing

@testable import Engine

@Suite("Lexicon ingestion")
struct LexiconTests {

    // MARK: Membership

    /// A word present in the accept list is a valid submission; a well-formed
    /// canonical word that simply isn't in the list is not.
    @Test("Accept Set membership admits listed words and rejects absent ones")
    func membership() throws {
        let lexicon = try Lexicon(
            acceptText: "kebap\nçilek\ngüneş",
            answersText: "kebap\nçilek",
            blocklistText: "",
            version: "test-v1"
        )
        #expect(lexicon.contains(try #require(Word("KEBAP"))))
        #expect(lexicon.contains(try #require(Word("ÇİLEK"))))
        #expect(lexicon.contains(try #require(Word("GÜNEŞ"))))
        // ZORLU is five canonical letters but was never ingested → not a member.
        #expect(!lexicon.contains(try #require(Word("ZORLU"))))
    }

    // MARK: Answer Pool + Blocklist

    /// The Answer Pool preserves the answers-file order with blocklisted words
    /// removed; a blocklisted word is gone from the pool yet still a valid
    /// submission (the blocklist restrains what the game *shows*, not what a
    /// player may type).
    @Test("Answer Pool is answers-order minus the blocklist; blocked words stay acceptable")
    func answerPoolOrderAndBlocklist() throws {
        let lexicon = try Lexicon(
            acceptText: "kebap\nçilek\ngüneş\ndoğru\nsıcak",
            answersText: "çilek\nkebap\nsıcak",  // deliberate non-alphabetical order
            blocklistText: "kebap",               // present in the answers → removed
            version: "test-v1"
        )
        let expected = try [Word("ÇİLEK"), Word("SICAK")].map { try #require($0) }
        #expect(lexicon.answerPool == expected)                       // order preserved, KEBAP gone
        #expect(lexicon.contains(try #require(Word("KEBAP"))))         // blocked, still acceptable
    }

    /// Every Answer Pool word is itself a member of the Accept Set — a shown
    /// answer is always an acceptable word (answers ⊆ accept).
    @Test("Every Answer Pool word is a member of the Accept Set")
    func answerPoolIsSubsetOfAccept() throws {
        let lexicon = try Lexicon(
            acceptText: "kebap\nçilek\ngüneş\ndoğru",
            answersText: "kebap\nçilek\ndoğru",
            blocklistText: "",
            version: "test-v1"
        )
        #expect(!lexicon.answerPool.isEmpty)
        for word in lexicon.answerPool {
            #expect(lexicon.contains(word))
        }
    }

    /// A well-formed blocklist word that isn't in the answers is a harmless
    /// no-op — not an error.
    @Test("A blocklist word absent from the answers is a no-op")
    func blocklistWordAbsentFromAnswers() throws {
        let lexicon = try Lexicon(
            acceptText: "kebap\nçilek",
            answersText: "kebap",
            blocklistText: "çilek",  // valid word, but not in the answers
            version: "test-v1"
        )
        #expect(lexicon.answerPool == [try #require(Word("KEBAP"))])
    }

    // MARK: Loud failure

    /// A malformed entry in *any* of the three lists stops construction — no
    /// silent drops. Covers all four malformed kinds (short, q/w/x, empty line,
    /// decomposed combining form) spread across the accept / answers / blocklist
    /// files. Each tuple keeps the other two files valid to isolate the fault.
    @Test(
        "A malformed entry in any list throws loudly",
        arguments: [
            // (acceptText, answersText, blocklistText) — exactly one is malformed.
            ("kebap\nabcd", "kebap", ""),           // accept: four letters
            ("kebap\nqebap", "kebap", ""),          // accept: q is not in the alphabet
            ("kebap\nçilek", "kebap\n\nçilek", ""), // answers: interior empty line
            ("kebap\nçilek", "c\u{0327}ilek", ""),  // answers: decomposed ç (c + U+0327)
            ("kebap\nçilek", "kebap", "abcd"),      // blocklist: four letters
            ("kebap\nçilek", "kebap", "c\u{0327}ilek"), // blocklist: decomposed ç
        ]
    )
    func malformedEntryThrows(_ accept: String, _ answers: String, _ blocklist: String) {
        #expect(throws: Lexicon.IngestionError.self) {
            try Lexicon(
                acceptText: accept,
                answersText: answers,
                blocklistText: blocklist,
                version: "test-v1"
            )
        }
    }

    /// The answers ⊆ accept invariant is enforced loudly: an answer that is not
    /// in the Accept Set is a hole in the vocabulary, caught at construction.
    @Test("An Answer Pool word missing from the Accept Set throws")
    func answerMissingFromAcceptThrows() {
        #expect(throws: Lexicon.IngestionError.self) {
            try Lexicon(
                acceptText: "kebap\nçilek",
                answersText: "kebap\ngüneş",  // GÜNEŞ is not in the accept list
                blocklistText: "",
                version: "test-v1"
            )
        }
    }

    // MARK: Determinism + version

    /// Ingestion is a pure function of its input bytes: the same text yields an
    /// equal Answer Pool, in equal order, every time. The List Version is the
    /// only handle that may vary ingestion output.
    @Test("Ingesting the same text twice yields an identical Answer Pool")
    func deterministic() throws {
        let make = { try Lexicon(
            acceptText: "kebap\nçilek\ngüneş",
            answersText: "güneş\nkebap",
            blocklistText: "",
            version: "test-v1"
        ) }
        let first = try make()
        let second = try make()
        #expect(first.answerPool == second.answerPool)
    }

    /// The List Version is exposed on the interface, and the bundled constant is
    /// `tr-v1`.
    @Test("List Version is exposed and the bundled constant is tr-v1")
    func versionIsExposed() throws {
        let lexicon = try Lexicon(
            acceptText: "kebap",
            answersText: "kebap",
            blocklistText: "",
            version: "test-v9"
        )
        #expect(lexicon.version == "test-v9")
        #expect(Lexicon.version == "tr-v1")
    }

    // MARK: Real bundle

    /// One smoke test over the actual shipped resources: `bundled()` ingests
    /// every entry without a loud failure (a malformed bundle would trap in
    /// `bundled()`), the Answer Pool is non-empty and within a sane sanity band,
    /// a known common word is acceptable, and canonical gibberish is not. This
    /// is what verifies the vendor step's output — no unit test peeks at it.
    @Test("The bundled Turkish lists ingest cleanly")
    func bundledListIngestsCleanly() throws {
        let lexicon = Lexicon.bundled()

        #expect(lexicon.version == "tr-v1")
        #expect(!lexicon.answerPool.isEmpty)
        // ~5.5k answers minus a handful of blocklisted words (tr-v1, pinned).
        #expect((5000...6000).contains(lexicon.answerPool.count))
        // A real word is acceptable; five canonical letters that spell nothing
        // are not (also proving the Accept Set isn't "everything shaped right").
        #expect(lexicon.contains(try #require(Word("KEBAP"))))
        #expect(!lexicon.contains(try #require(Word("ĞĞĞĞĞ"))))
    }
}
