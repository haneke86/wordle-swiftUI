# Words-first puzzle generation, not patterns-first backtracking

Every Row's target Pattern must be realizable by at least one Accept Set word, or the puzzle is unsolvable. The generator therefore picks real words from the Answer Pool and *computes* their Patterns against the answer — the picked word becomes the Row's Witness, so every shipped Row carries its own proof of solvability. Rows are sampled so green (hit) counts are non-decreasing top-to-bottom, making the grid read like a real game converging on the answer.

## Considered Options

Patterns-first with backtracking (invent Pattern shapes, then search the word list for realizing words) was the original plan. Rejected: many Patterns have zero realizing words in a ~5k-word list, so it needs backtracking, retry budgets, and a fallback — all to buy authored difficulty that v1 doesn't need. If authored puzzles ever matter, patterns-first can return as another PuzzleSource without touching the Puzzle model.

## Consequences

`pattern(guess:answer:)` gets called thousands of times per generation (bucketing the whole list by hit-count against the answer), so it must stay pure — no UI, animation, or keyboard side effects.
