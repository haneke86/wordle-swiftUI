//  TurkishAlphabet.swift
//  Engine
//
//  The 29-letter Turkish alphabet in Canonical Form (Turkish UPPERCASE) and the
//  explicit lowercase → uppercase casing table (ADR-0002). The table is written
//  out by hand rather than derived from `uppercased(with:)` so that nothing at
//  runtime has to trust ICU's locale behavior across OS versions.

/// The Turkish alphabet in Canonical Form: 29 UPPERCASE letters, no Q/W/X,
/// with dotted `İ` and dotless `I` as distinct letters.
public enum TurkishAlphabet {

    /// The 29 canonical letters, in Turkish alphabetical order.
    public static let canonicalLetters: [Character] = [
        "A", "B", "C", "Ç", "D", "E", "F", "G", "Ğ", "H", "I", "İ", "J", "K",
        "L", "M", "N", "O", "Ö", "P", "R", "S", "Ş", "T", "U", "Ü", "V", "Y", "Z",
    ]

    /// The explicit 29-entry casing table: lowercase → canonical uppercase.
    /// The two dangerous rows are `ı → I` and `i → İ`.
    public static let uppercaseTable: [Character: Character] = [
        "a": "A", "b": "B", "c": "C", "ç": "Ç", "d": "D", "e": "E", "f": "F",
        "g": "G", "ğ": "Ğ", "h": "H", "ı": "I", "i": "İ", "j": "J", "k": "K",
        "l": "L", "m": "M", "n": "N", "o": "O", "ö": "Ö", "p": "P", "r": "R",
        "s": "S", "ş": "Ş", "t": "T", "u": "U", "ü": "Ü", "v": "V", "y": "Y",
        "z": "Z",
    ]

    /// The canonical letters as a set, for O(1) membership checks.
    public static let canonicalSet: Set<Character> = Set(canonicalLetters)

    /// The canonical letters as their single Unicode scalars, for scalar-level
    /// validation that rejects decomposed combining forms (see `Word`).
    public static let canonicalScalars: Set<Unicode.Scalar> =
        Set(canonicalLetters.flatMap { $0.unicodeScalars })

    /// Fold one character to Canonical Form (Turkish UPPERCASE).
    ///
    /// Already-canonical letters (including `I` and `İ`) map to themselves;
    /// lowercase letters map through the explicit table. Returns `nil` for any
    /// character outside the 29-letter alphabet.
    public static func uppercased(_ character: Character) -> Character? {
        if canonicalSet.contains(character) { return character }
        return uppercaseTable[character]
    }
}
