# Two-pool Turkish word lists from MIT-only sources

Reverse Wordle punishes a thin Accept Set: because the player is hunting word-space to reproduce a fixed color Pattern, a real Turkish word rejected as "invalid" is common and frustrating — more so than in forward Wordle. So the engine keeps two *pools* as distinct concepts: the **Accept Set** (every valid submission, never shown) and the **Answer Pool** (the blocklist-filtered words the game may show). They are bundled as separate files even when drawn from the same source, so acceptance and presentation can evolve independently.

**Both pools are sourced from `caglarorhan/turkcewordle`** (MIT, ~5.5k) — clean, already lowercase, pure Turkish, five-letter. `answers-tr.txt` preserves upstream order (pinned by the List Version); `accept-tr.txt` is the same word set, sorted. The **Blocklist** is seeded by intersecting `viddexa/safetext` (MIT, 475 profanity tokens) with the Answer Pool — only words that can actually *be* an answer are worth blocking — and is hand-maintained thereafter. Both sources ship lowercase; the ADR-0002 casing table uppercases them to Canonical Form at ingest — the only place case mapping runs. Bundled files are three newline `.txt` resources; ingestion asserts `answers ⊆ accept` loudly. The bundle is kept MIT-clean on purpose, and ingestion output is pinned by the `tr-v1` List Version.

**Revised 2026-07-20.** The Accept Set was originally `csariyildiz/turkish-wordlist` (MIT), filtered to 5 canonical letters and unioned with the answers, chosen for breadth. In practice that source is a 2.5M-row CSV whose 5-letter canonical subset (~106k) is heavily polluted with English/foreign tokens — 84% pure-ASCII vs 61% in the clean answer pool, plus vowel-less junk like `bbjpg`. A cleaner Accept Set would be a real Turkish dictionary, but the good ones are not bundlable (see below). We chose to keep the bundle **clean and unambiguously MIT** over broad-but-noisy, accepting a thinner Accept Set for now (see Consequences).

## Considered Options

- **Broad Accept Set via `csariyildiz/turkish-wordlist`** (MIT) — the original decision; gives ~106k five-letter tokens including inflected forms, but heavily polluted with foreign/junk strings. Legal, but noisy. Demoted 2026-07-20.
- **`tdd-ai/hunspell-tr`** (177k, MPL-2.0) — richest coverage and clean, but ships as `.dic`/`.aff` needing affix expansion and carries file-level copyleft. The remaining licensed path to *clean and broad*; deferred as future work if the thin Accept Set proves limiting.
- **TDK-derived lists** (`ncarkaci/TDKDictionaryCrawler`, `CanNuhlar/Turkce-Kelime-Listesi`) — the cleanest Turkish vocabularies, but scraped TDK dictionary content with `license: null` → all-rights-reserved, and TDK asserts its own copyright. Not bundlable. (The crawler's own README frames its output as a password-cracking wordlist.) Its 5-letter subset is also only ~5.3k headwords — thinner than our answer pool, since Turkish inflected forms aren't headwords.
- **`vdemir/hunspell-tr`** — CC-BY-NC-ND: bans commercial use *and* derivatives. Unusable.
- **Copyleft blocklists / corpora** (`ooguz/turkce-kufur-karaliste`, `hermitdave/FrequencyWords`) — CC-BY-SA share-alike. Avoided to keep the bundle permissive/MIT-clean.

## Consequences

- `THIRD_PARTY_NOTICES.md` carries the two MIT copyright notices (caglarorhan, safetext) plus provenance pinning the exact source commit and generated-date each `.txt` was derived from, so a list refresh is reproducible.
- **The Accept Set is currently thin** (≈5.5k, the same word set as the Answer Pool). Some valid-but-uncommon or inflected Turkish words a player types will be rejected as invalid — the reverse-Wordle failure mode. Mitigation: `accept-tr.txt` is a *separate* bundled file, so a licensed broader source (e.g. expanded `tdd-ai/hunspell-tr`) can replace it later as a data-only change with no Engine interface change — just a List Version bump.
- The Answer Pool ships without a rarity filter; a later ticket adds frequency curation. Until then some daily answers may be obscure.
- Refreshing any bundled list bumps the `tr-v1` List Version, which is how the Daily generator keeps historical answers reproducible.
- Blocked words are excluded from the Answer Pool but still validate as player submissions.
