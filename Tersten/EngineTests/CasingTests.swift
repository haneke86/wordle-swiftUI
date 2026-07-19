//  CasingTests.swift
//  EngineTests
//
//  The casing-table seam (ADR-0002): the hand-written 29-entry lowercase →
//  canonical-uppercase table, cross-checked against the tr-locale ICU API.

import Foundation
import Testing

@testable import Engine

@Suite("Turkish casing table")
struct CasingTests {

    /// The four horsemen of Turkish dotted/dotless I — the highest-risk mappings.
    /// `i → İ`, `ı → I` are the folds; `I → I`, `İ → İ` are canonical fixed points.
    @Test(
        "Four horsemen fold to canonical uppercase",
        arguments: zip(
            [Character("i"), Character("ı"), Character("I"), Character("İ")],
            [Character("İ"), Character("I"), Character("I"), Character("İ")]
        )
    )
    func fourHorsemen(input: Character, expected: Character) {
        #expect(TurkishAlphabet.uppercased(input) == expected)
    }

    /// Every entry of the explicit table must agree with `uppercased(with: tr)` —
    /// the safety net that catches any typo in the hand-written table — and the
    /// public seam must fold through that same table.
    @Test("Explicit table agrees with the tr locale over the full alphabet")
    func tableAgreesWithLocale() {
        #expect(TurkishAlphabet.uppercaseTable.count == 29)
        let tr = Locale(identifier: "tr_TR")
        for (lower, upper) in TurkishAlphabet.uppercaseTable {
            #expect(String(lower).uppercased(with: tr) == String(upper))
            #expect(TurkishAlphabet.uppercased(lower) == upper)
        }
    }
}
