# Turkish Word List & Blocklist Sourcing — Research Report

**Date:** 2026-07-20
**Context:** Tersten Kelime (Turkish reverse-Wordle, SwiftUI/iOS). Need a bundled
pool of 5-letter Turkish words (lowercase, Turkish alphabet ç ğ ı i ö ş ü) plus a
day-one blocklist of words to exclude as answers.
**Method:** deep-research workflow — 6 search angles, 20 sources fetched, 97 claims
extracted, top 25 adversarially verified (2/3-refute gate), 23 confirmed / 2 killed.
Key licenses and file line-counts were then re-verified live against the GitHub API
and raw files on 2026-07-20.

---

## TL;DR — recommended stack

| Need | Pick | License | Count (verified) | Format |
|------|------|---------|------------------|--------|
| **5-letter answer/guess pool** | **caglarorhan/turkcewordle** → `dictionaries/tr_TR.js` | **MIT** | **5,532** words | JS array, already lowercase, pure Turkish, all exactly 5 chars |
| Cross-check / alternate 5-letter list | MehmetHuseyinDelipalta/Wordle-Turkce-Kelime-Listesi → `5HarfliKelimeListesi.txt` | **MIT** | **5,634** words | newline .txt, **UPPERCASE** (needs tr-locale lowercasing) |
| Larger validation dictionary (allowed guesses) | csariyildiz/turkish-wordlist → `turkce_kelime_listesi.txt` | **MIT** | ~76,186 words | newline .txt, lowercase |
| **Profanity blocklist** | **ooguz/turkce-kufur-karaliste** → `karaliste.txt` / `karaliste.json` | **CC BY-SA 4.0** (copyleft) | 698 lines (~626 single words) | newline .txt + JSON |
| Permissive blocklist alternate | viddexa/safetext → `safetext/languages/tr/words.txt` | **MIT** | 475 words | newline .txt |

**Bottom line:** you do **not** need a near-empty seed. A realistic, clean, MIT-licensed
5-letter pool of ~5,500 words is available today (caglarorhan/turkcewordle) and needs
zero normalization. Pair it with a small profanity blocklist. Total effort: download,
drop into the Engine bundle, done.

---

## 1. LIST SIZE / SOURCE — what real open Turkish word lists exist

### Ready-to-use 5-letter lists (best fit)
- **caglarorhan/turkcewordle** — `dictionaries/tr_TR.js`. **MIT** (© 2023–2024 Caglar Orhan).
  **5,532** words, verified: 0 not-5-length, 0 uppercase, 0 out-of-alphabet across all
  entries; already lowercase, pure Turkish (ç ğ ı i ö ş ü). Actively maintained web Wordle
  (latest release v.2024.0.2). Shipped as `export const dictionary = ["abacı","abadi",…]`
  → one transform to a `.txt`/plist. **This is the "MIT 5-letter Turkish list" the ticket
  refers to.**
- **MehmetHuseyinDelipalta/Wordle-Turkce-Kelime-Listesi** — `5HarfliKelimeListesi.txt`.
  **MIT**. **5,634** words, plain newline .txt, but stored **UPPERCASE** → must be
  lowercased with Turkish-locale rules (dotted/dotless i). Good independent cross-check;
  ~5.5k overlap with caglarorhan suggests a shared TDK-ish origin.

### Larger general dictionaries (for allowed-guess validation, not answers)
- **csariyildiz/turkish-wordlist** — `turkce_kelime_listesi.txt` (~870 KB) + per-letter
  `.list` files (k.list is the biggest). **MIT**. ~**76,186** words, lowercase, full Turkish
  alphabet. ⚠️ One extraction agent reported "2,510,327 (~2.5M) words" and it passed the
  verifier, but a live check of the file size (~870 KB ≈ 76k words) shows **76,186 is the
  real figure; treat 2.5M as an extraction error.**
- **CanNuhlar/Turkce-Kelime-Listesi** — TDK-derived (scraped by a bot from TDK's *imla
  kılavuzu*), ~large full dictionary. ⚠️ **NO LICENSE FILE (GitHub reports `license: null`)
  → all-rights-reserved by default. Do NOT bundle.** (90★, but legally unsafe.)

### Hunspell / spellcheck dictionaries (raw material, needs processing)
- **tdd-ai/hunspell-tr** — modern, high-quality Turkish Hunspell. **MPL-2.0** (weak,
  file-level copyleft — OK to bundle derived data in a closed app; only modifications to the
  MPL files themselves must stay MPL). `tr_TR.dic` ≈ **177,543** entries. Derived from
  corpora by the TDD group (**not** the TDK dictionary → avoids TDK licensing concerns).
  94.67% correction accuracy (beats older hrzafer/zemberek-python). Ships as `.aff`+`.dic`
  → must be unmunched/affix-expanded and filtered before you get plain 5-letter words.
- **wooorm/dictionaries** (`dictionary-tr`) — Turkish Hunspell repackaged. **MIT per-file**,
  but it's a normalized derivative of an upstream OpenOffice extension → verify the
  individual `index.dic`/`index.aff` license, don't assume repo-wide MIT.
- **vdemir/hunspell-tr** — ❌ **CC BY-NC-ND 4.0** (non-commercial + no-derivatives).
  Unusable: bans both commercial use and modified/filtered redistribution.

### NLP / frequency corpora (noisy; filtering required)
- **hermitdave/FrequencyWords** — `content/2018/tr/tr_full.txt`, `tr_50k.txt` from
  OpenSubtitles. Real non-empty pool, **but dual-licensed: MIT (code) / CC-BY-SA-4.0
  (data)** → the word data is share-alike, not permissive. Colloquial/subtitle vocabulary
  (particles, interjections) → needs dictionary filtering.
- **rspeer/wordfreq** — supports Turkish (`tr`), Wikipedia+Subtitles+Web+Twitter. **Code
  Apache-2.0 but DATA largely CC-BY-SA-4.0**; Turkish is *not* in the "large" tier; corpus
  frozen at ~2021 (never updated again). Frequency list, not a curated dictionary.
- **ahmetaa/zemberek-nlp** — Apache-2.0 morphology toolkit. ❌ **Do not treat as an easy
  data source:** the claim "Apache code ⇒ extractable lexicon is permissively usable" was
  **refuted 0–3** by verification. The lexicon is embedded for a morphological parser;
  extracting a clean 5-letter list is non-trivial and the data's license status is not the
  same as the code's.

---

## 2. PROVENANCE — the "MIT 5-letter Turkish list" the ticket names

**Yes, it exists — two of them, both MIT:**
1. **caglarorhan/turkcewordle** `dictionaries/tr_TR.js` — 5,532 words, lowercase, clean.
   (Recommended primary.)
2. **MehmetHuseyinDelipalta/Wordle-Turkce-Kelime-Listesi** `5HarfliKelimeListesi.txt` —
   5,634 words, uppercase.

Both are Turkish Wordle-clone repos with usable, MIT-licensed 5-letter lists. Use one as
the answer pool and optionally union both (dedupe) for a ~5.6k allowed-guess pool.
No "kelime-bul"/"bulmaca" repo surfaced with a better-licensed or larger 5-letter list.

---

## 3. FILE FORMAT — bundling & Turkish-locale casing

- **Recommended resource format:** lowercase, newline-delimited `.txt`, UTF-8, bundled in
  the Engine framework. This matches how safetext/Delipalta/csariyildiz ship, is trivially
  `String(contentsOf:).split(separator: "\n")`, and diffs cleanly in git.
- **Two-list convention (from original Wordle):** keep **answers** and **allowed guesses**
  as separate files. Original Wordle's answer list was 2,315 words; the allowed-guess list
  was much larger and maintained as a separate file. For Tersten: a curated answer subset +
  a superset guess list (e.g. caglarorhan ∪ Delipalta ∪ filtered csariyildiz).
- **Turkish casing is the #1 correctness trap.** Swift's `uppercased()`/`lowercased()` are
  locale-independent by default; you MUST use the locale-aware variants for Turkish:
  - `"i".uppercased(with: Locale(identifier: "tr_TR"))` → `"İ"` (dotted capital)
  - `"ı".uppercased(with: Locale(identifier: "tr_TR"))` → `"I"` (dotless capital)
  Normalize on ingest with the `tr_TR` locale so the dotted/dotless-i distinction is
  preserved. If you take Delipalta's uppercase list, lowercase it with `tr_TR` — a plain
  `.lowercased()` will mangle `I`→`i` instead of `I`→`ı`.
  (Firewall note: this reinforces the existing Engine casing-firewall work in #3.)

---

## 4. BLOCKLIST SEEDING — day-one exclusions

**In scope now, and cheap to seed.** Put **profanity/obscenity + slurs** on the blocklist
first; proper nouns are largely handled by sourcing answers from a common-noun dictionary,
but add an explicit small proper-noun exclusion if any slip in.

Concrete open lists:
- **ooguz/turkce-kufur-karaliste** — the de-facto standard Turkish profanity blacklist
  (205★). `karaliste.txt` (698 lines, ~626 single-word) + `karaliste.json`. Full Turkish
  alphabet coverage. ❗ **CC BY-SA 4.0 (copyleft)** → attribution + share-alike obligations
  if you redistribute the list as data. For a blocklist you filter *against* (not display),
  this is usually fine, but note it in NOTICE/credits. Mixes single words and multi-word
  phrases → filter to single tokens for a word-game answer exclusion.
- **viddexa/safetext** — `safetext/languages/tr/words.txt`, **475** words, newline .txt,
  **MIT** (cleanest license). Best choice if you want a permissive, no-strings blocklist.
- **d35k/Turkish-Swear-Words** — `swears.txt`, 1,561 entries, lowercase Turkish. ❌ **No
  license → unsafe to bundle.**
- **90pixel/kufur-filtresi** — ❌ `license: null` → all-rights-reserved. Skip.
- **0xberkay/kotuSozApi** — Apache-2.0, but data is a **~24 KB SQLite** `kotusozler.db`
  (must export/query, not plain text). Usable license, extra step.
- **eonurk/sinkaf** — MIT, but it's an **ML classifier** (BERT), ships **no word list**.
  Not usable as a static bundled resource.

**Recommendation:** seed from **safetext (MIT, 475)** for a clean license, optionally
union with **ooguz karaliste** single-token entries for coverage (crediting CC BY-SA).
Dedupe, lowercase (tr locale), drop multi-word phrases. Also strip any of these from the
*answer* pool automatically at build time.

---

## 5. VERSIONING LABEL — list-version constant

For a daily-word game, the version constant exists to make **which answer showed on day N**
reproducible and to signal "the pool changed." Two viable conventions:
- **CalVer `YYYY.0M.0D`** (e.g. `2026.07.20`) — calendar-derived, naturally sortable and
  totally ordered, matches a list that rotates on a calendar cadence. Established practice
  (youtube-dl, many data releases). Best when the list is regenerated on dates.
- **Monotonic integer / `tr-vN`** (e.g. `tr-v1`, `tr-v2`) — simplest; unambiguous ordering;
  no false compatibility semantics. SemVer's major.minor.patch is discouraged here because
  its compatibility signals are unenforced and meaningless for a word pool.

**Recommendation for Tersten Kelime:** use a **language-tagged monotonic label: `tr-v1`,
`tr-v2`, …** as the bundled constant, and record the source snapshot date in metadata
(e.g. a header comment / accompanying JSON `{ "version": "tr-v1", "generated": "2026-07-20",
"sources": [...] }`). This keeps the daily-answer index stable (answers keyed off a fixed
list order), makes "the pool changed" explicit and greppable, and avoids implying date-based
semantics you don't need. Bump the integer only when the answer ordering/content changes.

---

## Pitfalls the verifier explicitly killed (don't repeat these)
- ❌ "Zemberek is Apache-2.0, so its lexicon data is permissively usable/extractable." —
  **refuted 0–3.** Don't plan on Zemberek as a data source.
- ⚠️ "tdd-ai/vdemir `tr_TR.dic` entries are capitalized/proper-noun forms with apostrophes,
  needing heavy normalization." — **only 1–2 (not killed, weak):** treat as plausible-but-
  unconfirmed; inspect the actual `.dic` before assuming its casing.
- ⚠️ csariyildiz "2.5 million words" — passed the text verifier but contradicted by live
  file size; real count ≈ **76,186**.

---

## Recommended concrete plan for Tersten Kelime
1. **Answers + guesses:** vendor **caglarorhan/turkcewordle `tr_TR.js`** (MIT), transform
   the JS array → `answers-tr.txt` (curated subset) + `guesses-tr.txt` (full 5,532, optional
   ∪ Delipalta 5,634 deduped). Keep MIT LICENSE/notice in the repo.
2. **Blocklist:** vendor **safetext `tr/words.txt`** (MIT, 475); optionally union
   ooguz `karaliste.txt` single-tokens (credit CC BY-SA 4.0). Lowercase with `tr_TR`,
   drop phrases, subtract from the answer pool at build time.
3. **Normalization:** lowercase everything with `Locale(identifier: "tr_TR")` on ingest;
   assert all answer words are exactly 5 chars and within the 29-letter Turkish alphabet.
4. **Versioning:** ship constant `tr-v1` + a metadata JSON recording generated-date and
   source URLs/licenses.
5. **Licensing hygiene:** add a `NOTICE`/`THIRD_PARTY` file listing caglarorhan (MIT),
   safetext (MIT), and — if used — ooguz (CC BY-SA 4.0) and FrequencyWords (CC-BY-SA-4.0).
   **Exclude** CanNuhlar, d35k, 90pixel (no license) and vdemir (NC-ND).

---

## Sources (verified 2026-07-20)
- https://github.com/caglarorhan/turkcewordle — MIT, tr_TR.js 5,532 words *(live-verified)*
- https://github.com/MehmetHuseyinDelipalta/Wordle-Turkce-Kelime-Listesi — MIT, 5,634 words *(live-verified)*
- https://github.com/csariyildiz/turkish-wordlist — MIT, ~76,186 words *(live-verified license)*
- https://github.com/CanNuhlar/Turkce-Kelime-Listesi — NO LICENSE (TDK-scraped) *(live-verified null)*
- https://github.com/tdd-ai/hunspell-tr — MPL-2.0, ~177,543 dic entries *(live-verified license)*
- https://github.com/wooorm/dictionaries — MIT per-file (dictionary-tr, OpenOffice-derived)
- https://github.com/vdemir/hunspell-tr — CC BY-NC-ND 4.0 (unusable)
- https://github.com/ahmetaa/zemberek-nlp — Apache-2.0 code (lexicon NOT easily usable)
- https://github.com/rspeer/wordfreq — Apache code / CC-BY-SA data, tr, frozen ~2021
- https://github.com/hermitdave/FrequencyWords — MIT code / CC-BY-SA-4.0 data, OpenSubtitles tr
- https://github.com/ooguz/turkce-kufur-karaliste — CC BY-SA 4.0, karaliste.txt 698 lines *(live-verified)*
- https://github.com/viddexa/safetext — MIT, tr/words.txt 475 words *(live-verified)*
- https://github.com/d35k/Turkish-Swear-Words — no license, swears.txt 1,561 (unsafe)
- https://github.com/90pixel/kufur-filtresi — license:null (unsafe)
- https://github.com/0xberkay/kotuSozApi — Apache-2.0, SQLite db (not plain text)
- https://github.com/eonurk/sinkaf — MIT, ML classifier, no word list
- https://blog.eidinger.info/transforming-the-case-of-strings-in-swift — Swift locale-aware casing (tr)
- https://calver.org/ — CalVer YYYY.0M.0D convention
- https://www.tianxiangxiong.com/2023/03/08/semantic-vs-date-versioning.html — date vs semver
- https://gist.github.com/cfreshman/a03ef2cba789d8cf00c08f767e0fad7b — original Wordle answer list (2,315), answers-vs-guesses split
