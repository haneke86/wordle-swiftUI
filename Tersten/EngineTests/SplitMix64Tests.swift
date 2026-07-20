//  SplitMix64Tests.swift
//  EngineTests
//
//  The deterministic PRNG seam (#6, ADR-0004): a seedable, hand-rolled
//  SplitMix64 that replaces `SystemRandomNumberGenerator` — which is neither
//  seedable nor guaranteed stable across OS versions and so may never appear in
//  generation. The reference vectors below are the independent oracle: they were
//  produced by a separate SplitMix64 implementation (the canonical Vigna
//  reference) rather than by this code, so the test can genuinely disagree with
//  the implementation instead of restating it.

import Testing

@testable import Engine

@Suite("SplitMix64 deterministic PRNG")
struct SplitMix64Tests {

    // MARK: Reference vectors (independent oracle)

    /// The first five `next()` outputs for three seeds, computed by a separate
    /// canonical SplitMix64 (not by this struct). Seed 0 famously begins with
    /// 0xE220A8397B1DCDAF.
    @Test(
        "next() reproduces the canonical SplitMix64 stream",
        arguments: [
            (
                UInt64(0),
                [
                    0xE220_A839_7B1D_CDAF, 0x6E78_9E6A_A1B9_65F4,
                    0x06C4_5D18_8009_454F, 0xF88B_B8A8_724C_81EC,
                    0x1B39_896A_51A8_749B,
                ] as [UInt64]
            ),
            (
                UInt64(1),
                [
                    0x910A_2DEC_8902_5CC1, 0xBEEB_8DA1_658E_EC67,
                    0xF893_A2EE_FB32_555E, 0x71C1_8690_EE42_C90B,
                    0x71BB_54D8_D101_B5B9,
                ] as [UInt64]
            ),
            (
                UInt64(0xDEAD_BEEF),
                [
                    0x4ADF_B90F_68C9_EB9B, 0xDE58_6A31_41A1_0922,
                    0x021F_BC2F_8E1C_FC1D, 0x7466_CE73_7BE1_6790,
                    0x3BFA_8764_F685_BD1C,
                ] as [UInt64]
            ),
        ]
    )
    func referenceVectors(_ seed: UInt64, _ expected: [UInt64]) {
        var generator = SplitMix64(seed: seed)
        let produced = (0..<expected.count).map { _ in generator.next() }
        #expect(produced == expected)
    }

    // MARK: Determinism

    /// Two generators built from the same seed walk byte-identical streams — the
    /// foundation the Daily Puzzle's cross-device reproducibility rests on.
    @Test("Equal seeds produce identical streams")
    func equalSeedsAgree() {
        var a = SplitMix64(seed: 0x1234_5678_9ABC_DEF0)
        var b = SplitMix64(seed: 0x1234_5678_9ABC_DEF0)
        let left = (0..<64).map { _ in a.next() }
        let right = (0..<64).map { _ in b.next() }
        #expect(left == right)
    }

    /// Different seeds diverge immediately — adjacent days must not collapse to
    /// the same puzzle.
    @Test("Adjacent seeds produce different streams")
    func differentSeedsDiverge() {
        var a = SplitMix64(seed: 100)
        var b = SplitMix64(seed: 101)
        let left = (0..<8).map { _ in a.next() }
        let right = (0..<8).map { _ in b.next() }
        #expect(left != right)
    }

    // MARK: Bounded draw

    /// Every bounded draw lands in `0..<upperBound`, for a spread of bounds and
    /// across many draws.
    @Test("next(upperBound:) stays within [0, upperBound)")
    func boundedInRange() {
        var generator = SplitMix64(seed: 42)
        for bound in [UInt64(1), 2, 3, 5, 7, 29, 100, 5528] {
            for _ in 0..<500 {
                let value = generator.next(upperBound: bound)
                #expect(value < bound)
            }
        }
    }

    /// An upper bound of one has exactly one legal outcome: zero. (A pool of one
    /// candidate always draws that candidate.)
    @Test("next(upperBound: 1) is always zero")
    func boundedOfOne() {
        var generator = SplitMix64(seed: 7)
        for _ in 0..<100 {
            #expect(generator.next(upperBound: 1) == 0)
        }
    }

    /// The bounded draw is as deterministic as the raw stream: equal seeds yield
    /// equal bounded sequences.
    @Test("Bounded draws are deterministic under equal seeds")
    func boundedDeterministic() {
        var a = SplitMix64(seed: 2026)
        var b = SplitMix64(seed: 2026)
        let left = (0..<64).map { _ in a.next(upperBound: 29) }
        let right = (0..<64).map { _ in b.next(upperBound: 29) }
        #expect(left == right)
    }

    /// The draw covers the whole range, not just a sub-band: across many draws
    /// with a small bound, every legal value appears at least once. Guards
    /// against an off-by-one that can never reach `upperBound - 1`.
    @Test("Bounded draws reach every value in the range")
    func boundedCoversRange() {
        var generator = SplitMix64(seed: 99)
        var seen = Set<UInt64>()
        for _ in 0..<1000 {
            seen.insert(generator.next(upperBound: 6))
        }
        #expect(seen == Set(0..<6))
    }
}
