# Deterministic serverless Daily Puzzle

v1 ships daily-only, and streaks depend on every device deriving the *same* puzzle for the same date with no server. Two things make that reproducible:

1. **A date-seeded, hand-rolled PRNG** (e.g., SplitMix64). Swift's `SystemRandomNumberGenerator` is neither seedable nor guaranteed stable across OS versions, so it cannot appear anywhere in generation.
2. **A versioned word list.** Any edit to the Answer Pool or blocklist reshuffles every future daily. List changes must bump a list version that gates puzzle numbering, so already-published dates never change retroactively under players' streaks.

## Consequences

Word-list files are immutable once shipped; edits land as a new version, not in-place. The generator's inputs are exactly (date, list version) — nothing else may influence sampling.
