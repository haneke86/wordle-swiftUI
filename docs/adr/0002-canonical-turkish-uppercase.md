# One canonical text form: Turkish uppercase via an explicit table

Dotted/dotless I (`i→İ`, `ı→I`) makes locale-naive case round-trips silently corrupt Turkish comparisons — this is the app's highest-risk correctness area. We fix one canonical form: **Turkish UPPERCASE over the 29-letter alphabet**, everywhere. The keyboard emits already-canonical letters and tiles render stored values verbatim, so **zero case conversions happen at runtime**. Case mapping exists in exactly one place — word-list ingestion — implemented as a hand-written 29-entry character table. `Word` construction validates every **Unicode scalar** of the input against the alphabet — deliberately *without* NFC-normalizing first. (NFC would *recompose* a decomposed `I`+`U+0307` straight back into `İ` and admit it; and Swift's `String`/`Character` `==` is itself canonical-equivalence-based, so grapheme comparison can't catch it either. Only raw-scalar validation rejects the combining mark.) Anything not exactly five canonical scalars — q/w/x, decomposed combining forms, raw strings, wrong length — is rejected at the boundary, so `pattern(guess:answer:)` never sees un-canonical text.

## Considered Options

- **Lowercase canonical** — forces a lowercase→uppercase hop at every tile render, reintroducing Turkish case mapping into the view layer.
- **`uppercased(with: Locale("tr"))`** — correct today, but trusts ICU behavior across OS versions and gives no alphabet validation.

## Consequences

Tests must pin the four casing cases (`i→İ`, `ı→I`, `I→I`, `İ→İ`), rejection of q/w/x and decomposed forms, and (test-only) that the table agrees with the `tr` locale API.
