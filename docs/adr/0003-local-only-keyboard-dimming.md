# Keyboard Dimming is local-only; dictionary-aware dimming is forbidden

Exact dimming — lighting only letters that continue some Accept Set word satisfying the active Row — is easy to build (one pure `pattern()` sweep per row) and would delete the game: every lit key would be on a path to a valid completion, so Mistakes become impossible and Hints become worthless. Dimming therefore derives **only** from the active Row's target Pattern and the answer: green tiles are pre-filled (their letter is forced), yellow/gray tiles dim the answer's letter at that position (it would compute green), and yellow tiles light only the answer's letters.

This is a game-economy boundary, not a technical limitation — do not "fix" it. Full candidate dimming may only ever ship as an explicitly paid assist mode, never always-on.
