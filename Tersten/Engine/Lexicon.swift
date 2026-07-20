//  Lexicon.swift
//  Engine
//
//  The word-list ingestion seam (#15, ADR-0005): the one place the bundled
//  Turkish vocabulary becomes engine values. A Lexicon is built once, purely,
//  from three raw lowercase lists and exposes exactly three things — Accept Set
//  membership, the ordered Answer Pool, and the List Version. Ingestion reuses
//  the ADR-0002 casing boundary (no new case mapping) and is a pure function of
//  its input bytes: same text in, same pools out.

import Foundation

/// Anchors `Bundle(for:)` to the Engine framework bundle so `Lexicon.bundled()`
/// can find the bundled `.txt` resources. A framework target has no
/// auto-generated `Bundle.module`, so we resolve the bundle from a type it owns.
private final class LexiconBundleToken {}

/// The ingested Turkish vocabulary: an Accept Set (all valid submissions), an
/// ordered Answer Pool (the blocklist-filtered words the game may *show*), and
/// the List Version that pins the exact contents.
public struct Lexicon {

    /// The bundled List Version (glossary): the single label that identifies the
    /// exact shipped list contents and gates Daily reproducibility (ADR-0004).
    public static let version = "tr-v1"

    /// The List Version this Lexicon was built with.
    public let version: String

    /// The ordered Answer Pool: answers-file order, blocklisted words removed.
    public let answerPool: [Word]

    /// The Accept Set, backed by a `Set` for O(1) membership. Never surfaced —
    /// membership is observed only through `contains(_:)`.
    private let accept: Set<Word>

    /// A loud ingestion failure. Ingestion never drops an entry silently: any
    /// list line that is not exactly five canonical Turkish letters, or an
    /// Answer Pool word absent from the Accept Set, stops construction here.
    public enum IngestionError: Error, Equatable {
        /// A line in `list` did not fold to a canonical five-letter `Word`.
        case malformedEntry(list: String, line: String)
        /// An Answer Pool word is not a member of the Accept Set (invariant).
        case answerNotInAccept(word: String)
    }

    /// Ingest three raw lowercase lists into a Lexicon, or throw loudly.
    ///
    /// Each line of each list is folded character-by-character through the
    /// ADR-0002 casing table and then validated by `Word`'s scalar firewall, so
    /// the only case mapping in the whole engine happens right here.
    public init(
        acceptText: String,
        answersText: String,
        blocklistText: String,
        version: String
    ) throws {
        self.version = version

        let accept = Set(try Self.words(from: acceptText, list: "accept"))
        let blocklist = Set(try Self.words(from: blocklistText, list: "blocklist"))

        // Walk the answers in file order: enforce the answers ⊆ accept invariant,
        // then keep every answer the blocklist doesn't remove. Order is the
        // answers-file order — part of what the List Version pins (ADR-0004).
        var pool: [Word] = []
        for answer in try Self.words(from: answersText, list: "answers") {
            guard accept.contains(answer) else {
                throw IngestionError.answerNotInAccept(word: answer.string)
            }
            if !blocklist.contains(answer) {
                pool.append(answer)
            }
        }

        self.accept = accept
        self.answerPool = pool
    }

    /// Accept Set membership: `true` iff `word` is an acceptable submission.
    /// Blocklisted words remain members — the blocklist restrains only what the
    /// game *shows*, never what a player may type.
    public func contains(_ word: Word) -> Bool { accept.contains(word) }

    // MARK: Bundled list

    /// The Lexicon built from the three bundled `.txt` resources at the current
    /// List Version. A malformed *shipped* bundle is an unrecoverable programmer
    /// error, so the loud-failure paths that are recoverable at the pure `init`
    /// (and asserted in tests) become `fatalError`s here.
    public static func bundled() -> Lexicon {
        let bundle = Bundle(for: LexiconBundleToken.self)
        func text(_ resource: String) -> String {
            guard let url = bundle.url(forResource: resource, withExtension: "txt"),
                  let contents = try? String(contentsOf: url, encoding: .utf8)
            else { fatalError("Lexicon: missing bundled resource \(resource).txt") }
            return contents
        }
        do {
            return try Lexicon(
                acceptText: text("accept-tr"),
                answersText: text("answers-tr"),
                blocklistText: text("blocklist-tr"),
                version: Lexicon.version
            )
        } catch {
            fatalError("Lexicon: malformed bundled list: \(error)")
        }
    }

    // MARK: Ingestion

    /// Parse every line of `text` into a canonical `Word`, throwing on the first
    /// malformed line. `list` names the source file for the error message.
    private static func words(from text: String, list: String) throws -> [Word] {
        try lines(of: text).map { try word(from: $0, list: list) }
    }

    /// Fold one lowercase line to a canonical `Word`. A character outside the
    /// 29-letter alphabet, or an assembled string that is not five canonical
    /// letters (wrong length, decomposed combining form, …), is a malformed
    /// entry — never a silent drop.
    private static func word(from line: Substring, list: String) throws -> Word {
        var canonical = ""
        for character in line {
            // Reject decomposed combining forms at the scalar level. Swift's
            // `Character` equality is canonical-equivalence-based, so a decomposed
            // `"c" + U+0327` would match the casing table's precomposed `"ç"` key
            // and be silently normalized — exactly what ADR-0002 forbids. `Word`'s
            // own scalar firewall can't catch it here because the table sits in
            // front of it, so we guard the raw scalars before folding.
            guard character.unicodeScalars.count == 1,
                  let uppercased = TurkishAlphabet.uppercased(character) else {
                throw IngestionError.malformedEntry(list: list, line: String(line))
            }
            canonical.append(uppercased)
        }
        guard let word = Word(canonical) else {
            throw IngestionError.malformedEntry(list: list, line: String(line))
        }
        return word
    }

    /// Split raw list text into lines, dropping only the conventional single
    /// trailing newline at end-of-file. An *interior* empty line is kept — it
    /// becomes a malformed entry, so a stray blank line fails loudly rather than
    /// vanishing.
    private static func lines(of text: String) -> [Substring] {
        var parts = text.split(separator: "\n", omittingEmptySubsequences: false)
        if parts.last == "" { parts.removeLast() }
        return parts
    }
}
