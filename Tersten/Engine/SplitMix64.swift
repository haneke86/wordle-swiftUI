//  SplitMix64.swift
//  Engine
//
//  The deterministic PRNG seam (#6, ADR-0004). Daily reproducibility requires
//  every device to derive the same puzzle for the same date with no server, so
//  generation may never touch `SystemRandomNumberGenerator` — it is neither
//  seedable nor guaranteed stable across OS versions. This hand-rolled SplitMix64
//  is the replacement: a tiny, fully-specified generator whose stream is pinned
//  by its seed alone.
//
//  Deliberately NOT a `RandomNumberGenerator`. That protocol's conveniences
//  (`shuffled(using:)`, the generic `next(upperBound:)`) run stdlib algorithms
//  whose output is not contracted to be stable across Swift versions — the exact
//  hazard ADR-0004 guards against. Exposing only our own pinned primitives keeps
//  every bit of the stream under this file's control, so a stdlib change can
//  never silently reshuffle a published Daily Puzzle.

/// A seedable SplitMix64 pseudo-random generator (Vigna's reference constants).
///
/// The seed fully determines the stream: two values built from the same seed
/// emit byte-identical sequences forever. That is the property the Daily Puzzle
/// leans on — `(date, list version)` folds to a seed, and the seed folds to a
/// puzzle.
public struct SplitMix64 {

    /// The 64-bit internal state, advanced by the golden-ratio increment on
    /// every draw. Private: callers observe the generator only through `next`.
    private var state: UInt64

    /// Seed the generator. Any `UInt64` is a valid seed; the Daily generator
    /// derives one purely from `(dayNumber, list version)`.
    public init(seed: UInt64) {
        self.state = seed
    }

    /// The next 64 bits of the stream.
    ///
    /// One step of SplitMix64: bump the state by the odd golden-ratio constant
    /// `0x9E3779B97F4A7C15`, then run that value through two xor-shift/multiply
    /// mixing rounds so consecutive states scramble into well-distributed output.
    /// All arithmetic wraps (`&+`, `&*`) — overflow is the algorithm, not a bug.
    public mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// A uniformly-distributed draw in `0..<upperBound`, free of modulo bias.
    ///
    /// Naive `next() % upperBound` skews toward small values whenever
    /// `upperBound` does not divide `2^64` evenly. We remove the skew by
    /// rejection: `threshold` is `2^64 mod upperBound`, the size of the short
    /// leftover band at the bottom of the 64-bit range; any raw draw landing in
    /// that band is discarded and redrawn, so the values that remain map onto
    /// `0..<upperBound` in perfectly equal shares.
    ///
    /// `upperBound` must be positive (a draw from an empty range is meaningless).
    public mutating func next(upperBound: UInt64) -> UInt64 {
        precondition(upperBound > 0, "SplitMix64.next(upperBound:) requires upperBound > 0")

        // (0 &- upperBound) is 2^64 - upperBound; reducing it mod upperBound
        // yields 2^64 mod upperBound — the count of biased low values to reject.
        let threshold = (0 &- upperBound) % upperBound
        var raw = next()
        while raw < threshold {
            raw = next()
        }
        return raw % upperBound
    }
}
