//  DailyGenerator.swift
//  Engine
//
//  The deterministic Daily generator (#6, ADR-0001 & ADR-0004). It turns a
//  clock-free `(dayNumber, list version)` pair into a Puzzle, words-first: sample
//  real Answer Pool words, compute their Patterns against the answer, and keep
//  each sampled word as its Row's Witness — so every Row ships with its own proof
//  of solvability and no backtracking is ever needed.
//
//  Nothing here reads a clock or the system RNG. The day number arrives as a
//  value (the app maps a calendar date to it, outside the Engine), and all
//  randomness flows from a `SplitMix64` seeded purely by `(dayNumber, version)`.
//  Same inputs in, byte-identical Puzzle out.

extension Puzzle {

    /// The fewest and most Rows a Puzzle may have (glossary: 3–5).
    private static let rowCountRange = 3...5

    /// Generate the deterministic Daily Puzzle for `dayNumber` from `lexicon`.
    ///
    /// `dayNumber` is a calendar-day index the caller derives from the date; the
    /// Engine never reads a clock (ADR-0004). The seed folds in `lexicon.version`
    /// so a list edit — which bumps the List Version — reshuffles every future
    /// daily instead of silently rewriting already-published ones.
    ///
    /// Requires an Answer Pool of at least six words (one answer plus up to five
    /// distinct Witnesses). The shipped `Lexicon.bundled()` has thousands; a pool
    /// too small to draw a full puzzle is a programmer error, so it traps rather
    /// than returning a malformed Puzzle.
    public static func daily(dayNumber: Int, lexicon: Lexicon) -> Puzzle {
        let pool = lexicon.answerPool
        precondition(
            pool.count >= 1 + rowCountRange.upperBound,
            "Answer Pool too small to generate a Daily Puzzle: \(pool.count) words"
        )

        var generator = SplitMix64(seed: seed(dayNumber: dayNumber, version: lexicon.version))

        // 1. The answer — the word every Row's Pattern is scored against.
        let answer = pool[Int(generator.next(upperBound: UInt64(pool.count)))]

        // 2. How many Rows this puzzle has (3–5, uniform).
        let span = UInt64(rowCountRange.count)
        let rowCount = rowCountRange.lowerBound + Int(generator.next(upperBound: span))

        // 3. The Witnesses: `rowCount` words drawn without replacement, each
        //    distinct by value and never equal to the answer (so no Row is ever
        //    all-green — only the display Answer Row is). A partial Fisher–Yates
        //    over the pool indices keeps the draw uniform and clock-free.
        let witnesses = sampleWitnesses(
            count: rowCount,
            from: pool,
            excluding: answer,
            using: &generator
        )

        // 4. Score each Witness, then order the Rows so green counts never
        //    decrease top-to-bottom. The tie-break on draw order makes the sort a
        //    total order — the final layout is pinned regardless of whether the
        //    stdlib sort is stable, which byte-identical determinism demands.
        let rows =
            witnesses
            .enumerated()
            .map { drawOrder, witness -> (row: Row, hits: Int, drawOrder: Int) in
                let target = pattern(guess: witness, answer: answer)
                let hits = target.reduce(0) { $0 + ($1 == .hit ? 1 : 0) }
                return (Row(target: target, witness: witness), hits, drawOrder)
            }
            .sorted { $0.hits != $1.hits ? $0.hits < $1.hits : $0.drawOrder < $1.drawOrder }
            .map(\.row)

        return Puzzle(answer: answer, rows: rows)
    }

    // MARK: Sampling

    /// Draw `count` words from `pool` without replacement, skipping `excluded`
    /// and any value already chosen, so the result is `count` distinct Witnesses
    /// none of which equals the answer.
    ///
    /// This is a partial Fisher–Yates: at each step it swaps a uniformly-chosen
    /// still-unused index into the front and reads it. Drawing without
    /// replacement means it can never loop forever — the precondition in `daily`
    /// guarantees enough distinct candidates exist to reach `count`.
    private static func sampleWitnesses(
        count: Int,
        from pool: [Word],
        excluding excluded: Word,
        using generator: inout SplitMix64
    ) -> [Word] {
        var indices = Array(pool.indices)
        var chosen: [Word] = []
        var chosenSet: Set<Word> = []

        var frontier = 0
        while chosen.count < count {
            let remaining = pool.count - frontier
            guard remaining > 0 else {
                preconditionFailure("Answer Pool exhausted before \(count) distinct Witnesses were drawn")
            }
            let pick = frontier + Int(generator.next(upperBound: UInt64(remaining)))
            indices.swapAt(frontier, pick)
            let word = pool[indices[frontier]]
            frontier += 1

            if word != excluded && chosenSet.insert(word).inserted {
                chosen.append(word)
            }
        }
        return chosen
    }

    // MARK: Seeding

    /// Fold `(dayNumber, version)` into a 64-bit seed with FNV-1a.
    ///
    /// FNV-1a is a fully-specified byte hash, so the seed depends only on these
    /// two inputs and nothing ambient — unlike Swift's `Hasher`, which is salted
    /// per process and would hand the same day a different puzzle on every
    /// launch. That stability is exactly what cross-device Daily agreement needs.
    private static func seed(dayNumber: Int, version: String) -> UInt64 {
        let offsetBasis: UInt64 = 0xCBF2_9CE4_8422_2325
        let prime: UInt64 = 0x0000_0100_0000_01B3
        var hash = offsetBasis
        for byte in "\(version)#\(dayNumber)".utf8 {
            hash = (hash ^ UInt64(byte)) &* prime
        }
        return hash
    }
}
