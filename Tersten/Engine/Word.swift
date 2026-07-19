//  Word.swift
//  Engine
//
//  The Word value type and the single boundary through which text enters the
//  engine (ADR-0002).

/// A value of exactly five canonical Turkish letters.
///
/// The only way to construct one is `init?(_:)`, which validates every Unicode
/// scalar against the 29-letter alphabet. Anything else — q/w/x, decomposed
/// combining forms, raw lowercase, wrong length — is rejected at the boundary,
/// so `pattern(guess:answer:)` and every later stage only ever see Canonical
/// Form text.
public struct Word: Equatable, Hashable {

    /// Every Word is exactly this many letters.
    public static let length = 5

    /// The five canonical letters, in order.
    public let letters: [Character]

    /// Construct a Word from a string, or `nil` if it is not exactly five
    /// canonical letters.
    ///
    /// Validation is deliberately performed on the *raw* Unicode scalars. We do
    /// not NFC-normalize first: NFC would recompose a decomposed `"I" + U+0307`
    /// straight back into `İ` and let it through, defeating the whole point of
    /// the firewall. A decomposed form instead shows up here as an extra
    /// combining scalar (U+0307, U+0327, …) that is not one of the 29 canonical
    /// letters — and is rejected.
    public init?(_ raw: String) {
        let scalars = Array(raw.unicodeScalars)
        guard scalars.count == Self.length else { return nil }
        guard scalars.allSatisfy(TurkishAlphabet.canonicalScalars.contains) else { return nil }
        self.letters = scalars.map(Character.init)
    }

    /// The canonical string form.
    public var string: String { String(letters) }
}

extension Word: CustomStringConvertible {
    public var description: String { string }
}
