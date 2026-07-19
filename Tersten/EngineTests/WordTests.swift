//  WordTests.swift
//  EngineTests
//
//  The Word-construction firewall seam (ADR-0002): the only door into the engine
//  is `Word(_:)`, which admits exactly five canonical letters and rejects
//  everything else — q/w/x, decomposed combining forms, wrong length, raw
//  lowercase — so `pattern(guess:answer:)` never sees un-canonical text.

import Testing

@testable import Engine

@Suite("Word construction firewall")
struct WordTests {

    // MARK: Accepts

    @Test(
        "Accepts canonical five-letter words, including the special letters",
        arguments: ["KEBAP", "ÇİLEK", "GÜNEŞ", "DOĞRU", "SICAK"]
    )
    func acceptsCanonical(_ raw: String) throws {
        let word = try #require(Word(raw))
        #expect(word.letters.count == Word.length)
        #expect(word.string == raw)
    }

    @Test("Round-trips and compares by value")
    func valueSemantics() throws {
        let a = try #require(Word("ÇİLEK"))
        let b = try #require(Word("ÇİLEK"))
        #expect(a == b)
        #expect(String(a.letters) == "ÇİLEK")
    }

    // MARK: Rejects

    /// Q, W and X are not in the 29-letter alphabet — upper or lower case.
    @Test(
        "Rejects q / w / x",
        arguments: ["QABCD", "WABCD", "XABCD", "qabcd", "wabcd", "xabcd"]
    )
    func rejectsQWX(_ raw: String) {
        #expect(Word(raw) == nil)
    }

    /// Decomposed combining forms carry a stray combining scalar (U+0307 dot
    /// above, U+0327 cedilla). Validating at the scalar level rejects them —
    /// crucially, we do NOT NFC-normalize first, which would recompose them.
    @Test(
        "Rejects decomposed combining forms",
        arguments: [
            "GI\u{0307}ZEM",  // "GİZEM" with a decomposed dotted İ  (I + U+0307)
            "C\u{0327}OCUK",  // "ÇOCUK" with a decomposed cedilla Ç  (C + U+0327)
        ]
    )
    func rejectsDecomposed(_ raw: String) {
        #expect(Word(raw) == nil)
    }

    @Test(
        "Rejects wrong-length input",
        arguments: ["", "ABCD", "ABCDEF", "ABCDEÇ"]
    )
    func rejectsWrongLength(_ raw: String) {
        #expect(Word(raw) == nil)
    }

    /// Canonical Form is UPPERCASE; raw lowercase must not slip through.
    @Test("Rejects raw lowercase", arguments: ["kebap", "çilek"])
    func rejectsLowercase(_ raw: String) {
        #expect(Word(raw) == nil)
    }
}
