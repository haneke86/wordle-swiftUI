#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Offline vendor step for the Turkish word lists (#15, ADR-0005).
#
# Downloads two MIT-licensed upstream sources at pinned commits, transforms them
# into three bundled lowercase `.txt` resources, and writes THIRD_PARTY_NOTICES.md
# with provenance. This script is delivery scope and is NOT unit-tested: its
# output is validated indirectly by the real-bundle smoke test in EngineTests
# (`Lexicon.bundled()` must ingest every entry cleanly).
#
# Sourcing (ADR-0005, revised 2026-07-20): the Accept Set and the Answer Pool are
# both drawn from the clean caglarorhan list, so `accept-tr.txt` currently equals
# `answers-tr.txt`'s word set. They remain SEPARATE bundled files on purpose — a
# later broader, appropriately-licensed Accept Set is a one-file swap with no
# Engine change (Lexicon still ingests three texts).
#
# Refresh process: bump the pinned SHAs / GENERATED_DATE below, re-run, then bump
# the `Lexicon.version` List Version constant so the Daily generator keeps past
# answers reproducible (ADR-0004).
#
# Usage:  ruby scripts/vendor_wordlists.rb

require "set"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
RES  = File.join(ROOT, "Tersten", "Engine", "Resources")

GENERATED_DATE = "2026-07-20"

# The 29 canonical lowercase Turkish letters — the mirror of TurkishAlphabet's
# casing-table keys (no q/w/x; dotted i and dotless ı are distinct). A bundled
# entry is exactly five of these. Anything else — foreign letters, apostrophes,
# combining marks, wrong length, uppercase — is filtered out here; whatever
# slips through is still rejected loudly at ingestion.
LOWER29 = %w[a b c ç d e f g ğ h ı i j k l m n o ö p r s ş t u ü v y z].to_set

def five_letter?(token)
  chars = token.chars
  chars.length == 5 && chars.all? { |c| LOWER29.include?(c) }
end

SOURCES = {
  words: {
    repo: "caglarorhan/turkcewordle",
    sha:  "a00f6225d146ef71decdc2e07c755b73c669b401",
    path: "dictionaries/tr_TR.js",
    holder: "Copyright (c) 2023-2024 Caglar Orhan",
    files: %w[answers-tr.txt accept-tr.txt],
    role: "Answer Pool (words shown as answers/Witnesses) and, currently, the " \
          "Accept Set (valid submissions).",
    xform: "Extracted the JS `dictionary` array; kept exactly-5 " \
           "canonical-Turkish-lowercase tokens; de-duplicated. answers-tr.txt " \
           "preserves upstream order (pinned by the List Version); accept-tr.txt " \
           "is the same word set, sorted.",
  },
  block: {
    repo: "viddexa/safetext",
    sha:  "afe96c8053e577e7e1e3a2eb5c9503ac157efbb5",
    path: "safetext/languages/tr/words.txt",
    holder: "Copyright (c) 2023 DeepSafe",
    files: %w[blocklist-tr.txt],
    role: "Blocklist seed — offensive words excluded from the Answer Pool.",
    xform: "Kept single exactly-5 canonical-Turkish-lowercase tokens that also " \
           "appear in the Answer Pool (only words that could be an answer are " \
           "worth blocking); sorted. Hand-maintained thereafter.",
  },
}.freeze

def raw_url(src)
  "https://raw.githubusercontent.com/#{src[:repo]}/#{src[:sha]}/#{src[:path]}"
end

def fetch(src, dest)
  ok = system("curl", "-sSL", "-m", "180", raw_url(src), "-o", dest)
  abort "  ! download failed: #{raw_url(src)}" unless ok && File.size?(dest)
end

def write_list(name, words)
  File.write(File.join(RES, "#{name}.txt"), words.join("\n") + "\n")
  puts "  → #{name}.txt  (#{words.length} entries)"
end

Dir.mkdir(RES) unless Dir.exist?(RES)

answers = []
blocklist = []

Dir.mktmpdir("tk-vendor") do |tmp|
  # --- Answer Pool + Accept Set: extract the JS array, in order ------------
  words_js = File.join(tmp, "words.js")
  fetch(SOURCES[:words], words_js)
  seen = Set.new
  File.read(words_js, encoding: "UTF-8").scan(/"([^"]+)"/) do |(token)|
    next unless five_letter?(token)
    answers << token if seen.add?(token)
  end
  abort "  ! no answers extracted" if answers.empty?

  # --- Blocklist: 5-letter offensive tokens that can actually be answers ---
  block_txt = File.join(tmp, "block.txt")
  fetch(SOURCES[:block], block_txt)
  answer_set = answers.to_set
  blocklist = File.readlines(block_txt, encoding: "UTF-8")
                  .map(&:strip)
                  .select { |t| five_letter?(t) && answer_set.include?(t) }
                  .uniq
                  .sort
end

write_list("answers-tr", answers)          # upstream order — pinned by the version
write_list("accept-tr", answers.sort)      # same word set, sorted (answers ⊆ accept)
write_list("blocklist-tr", blocklist)

# --- THIRD_PARTY_NOTICES.md ------------------------------------------------
mit = <<~MIT
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
MIT

sections = SOURCES.map do |_key, src|
  <<~SECTION
    ### #{src[:repo]} — MIT

    - **Role:** #{src[:role]}
    - **Bundled as:** #{src[:files].map { |f| "`Tersten/Engine/Resources/#{f}`" }.join(", ")}
    - **Source:** https://github.com/#{src[:repo]}/blob/#{src[:sha]}/#{src[:path]}
    - **Pinned commit:** `#{src[:sha]}`
    - **Generated:** #{GENERATED_DATE}
    - **Transformation:** #{src[:xform]}

    ```
    MIT License

    #{src[:holder]}

    #{mit.strip}
    ```
  SECTION
end

File.write(File.join(ROOT, "THIRD_PARTY_NOTICES.md"), <<~DOC)
  # Third-Party Notices

  The Tersten Engine bundles Turkish word-list data derived from the MIT-licensed
  sources below (ADR-0005). Each source's MIT notice travels with the
  redistributed data, and each entry pins the exact upstream commit and the date
  the bundled `.txt` was generated, so a list refresh is reproducible and
  auditable. Regenerate with `ruby scripts/vendor_wordlists.rb`, then bump the
  `Lexicon.version` List Version.

  #{sections.join("\n").strip}
DOC
puts "  → THIRD_PARTY_NOTICES.md"
puts "OK: answers=#{answers.length}, accept=#{answers.length}, blocklist=#{blocklist.length}"
