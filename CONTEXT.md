# Tersten Kelime Oyunu

A Turkish reverse word-guess iOS game: the player sees a completed, pre-colored grid plus the answer word, and must fill each row with a valid Turkish word that reproduces that row's color pattern.

## Language

### Naming

**Tersten Kelime Oyunu**:
The full app name (App Store listing).

**Tersten**:
The brand short name — logo, icon, and anywhere space is tight.
_Avoid_: Wordle, Unwordle (both are other people's marks — never in names, bundle IDs, assets, or UI strings)

### Game model

**Word**:
A value of exactly 5 canonical Turkish letters. The only way to construct one is through Turkish-aware normalization — raw strings never cross this boundary.
_Avoid_: string, text, guess-string

**Canonical Form**:
Turkish UPPERCASE over the 29-letter alphabet (no Q/W/X; İ and I are distinct letters). Words, list entries, and keyboard emissions are always already canonical; case mapping exists only at word-list ingestion.
_Avoid_: normalized string, lowercased form

**TileMark**:
The color verdict for one tile: `hit` (green), `present` (yellow), `miss` (gray). Gray is always explicit, never a default.
_Avoid_: correct/misplaced/wrong (the fork's Color-based names), background color

**Pattern**:
An array of exactly 5 TileMarks. The output of scoring a Word against an answer, and the target a player must reproduce for a row.
_Avoid_: colors, feedback, result

**Row**:
One *playable* line of the puzzle grid: a target Pattern the player must reproduce with a valid Word. A Row is `pending`, `active` (exactly one at a time, advancing top-to-bottom), or `solved` — and solved is permanent. A Puzzle has 3–5 Rows.
_Avoid_: guess (the fork's forward-direction name), attempt, try

**Answer Row**:
The display-only bottom line of the grid showing the answer fully green. Not a Row — it has no target, no Witness, and no states.
_Avoid_: final row, solution row

**Daily Puzzle**:
The single Puzzle for a calendar date — identical on every device, with no server. The only mode in v1; streaks, stats, and the share string all belong to it.
_Avoid_: level, today's game

**Puzzle**:
The immutable, generated artifact: an answer Word plus an ordered list of Rows, each with a target Pattern and a Witness. Contains no player progress.
_Avoid_: game, board, grid (those are UI)

**Witness**:
The generator's proof word for a Row: a valid Word that reproduces the Row's target Pattern. Every shipped Row carries one — it is *a* solution, never *the* solution. Powers Hints and give-up.
_Avoid_: solution, intended word, correct answer

**Hint**:
Revealing part of a Row's Witness to the player. The monetization surface.

**PlayState**:
The player's mutable progress through one Puzzle: which Rows are solved with which Words, and the Mistake count. Always separate from the Puzzle itself.
_Avoid_: game state, session (overloaded)

**Accept Set**:
The full 5-letter Turkish word list; membership makes a player's submission a valid Word. Never surfaced to the player as content.
_Avoid_: dictionary, word list (ambiguous between the pools)

**Answer Pool**:
The curated subset of the Accept Set (blocklist-filtered; later frequency-filtered) from which answers and Witnesses are drawn. The only pool whose words the game ever *shows* the player.
_Avoid_: answer list, common words

**PuzzleSource**:
Anything that supplies Puzzles: the v1 generator, a daily feed, custom/authored puzzles later. The game loop consumes Puzzles without knowing their origin.
_Avoid_: level provider, puzzle factory

**Dimming**:
Keyboard guidance derived *only* from the active Row's target Pattern and the answer — never from the dictionary. Green tiles come pre-filled; yellow/gray tiles dim the answer's letter at that position; yellow tiles light only the answer's letters. Dictionary-aware dimming is forbidden: it would make Mistakes impossible and Hints worthless.
_Avoid_: key hints, keyboard solver

**Mistake**:
A submission of a valid Word whose computed Pattern does not match the Row's target. The game's only score — there is no lose state. Submitting a non-word is not a Mistake; it is a non-event.
_Avoid_: wrong guess, fail, error

**Perfect**:
Completing a puzzle with zero Mistakes.

**pattern(guess:answer:)**:
The pure two-pass scoring function — greens first with letter-count decrement, then yellows only while unused copies remain. The single seam shared by forward Wordle (generator of feedback) and this game (validator of a player's word).
_Avoid_: setCurrentGuessColors, coloring the row
