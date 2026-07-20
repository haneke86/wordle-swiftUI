# Third-Party Notices

The Tersten Engine bundles Turkish word-list data derived from the MIT-licensed
sources below (ADR-0005). Each source's MIT notice travels with the
redistributed data, and each entry pins the exact upstream commit and the date
the bundled `.txt` was generated, so a list refresh is reproducible and
auditable. Regenerate with `ruby scripts/vendor_wordlists.rb`, then bump the
`Lexicon.version` List Version.

### caglarorhan/turkcewordle — MIT

- **Role:** Answer Pool (words shown as answers/Witnesses) and, currently, the Accept Set (valid submissions).
- **Bundled as:** `Tersten/Engine/Resources/answers-tr.txt`, `Tersten/Engine/Resources/accept-tr.txt`
- **Source:** https://github.com/caglarorhan/turkcewordle/blob/a00f6225d146ef71decdc2e07c755b73c669b401/dictionaries/tr_TR.js
- **Pinned commit:** `a00f6225d146ef71decdc2e07c755b73c669b401`
- **Generated:** 2026-07-20
- **Transformation:** Extracted the JS `dictionary` array; kept exactly-5 canonical-Turkish-lowercase tokens; de-duplicated. answers-tr.txt preserves upstream order (pinned by the List Version); accept-tr.txt is the same word set, sorted.

```
MIT License

Copyright (c) 2023-2024 Caglar Orhan

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
```

### viddexa/safetext — MIT

- **Role:** Blocklist seed — offensive words excluded from the Answer Pool.
- **Bundled as:** `Tersten/Engine/Resources/blocklist-tr.txt`
- **Source:** https://github.com/viddexa/safetext/blob/afe96c8053e577e7e1e3a2eb5c9503ac157efbb5/safetext/languages/tr/words.txt
- **Pinned commit:** `afe96c8053e577e7e1e3a2eb5c9503ac157efbb5`
- **Generated:** 2026-07-20
- **Transformation:** Kept single exactly-5 canonical-Turkish-lowercase tokens that also appear in the Answer Pool (only words that could be an answer are worth blocking); sorted. Hand-maintained thereafter.

```
MIT License

Copyright (c) 2023 DeepSafe

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
```
