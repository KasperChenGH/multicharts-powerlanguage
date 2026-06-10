# scripts/ — maintainer-only build tooling

These scripts are run by the plugin maintainer (Yu-An Chen), not by end users.
End users install the plugin and get all generated content via the committed
`skills/powerlanguage-keywords-reference/details/` tree.

## Requirements

- Windows with MultiCharts installed (provides `PowerLanguage.chm`)
- PowerShell 5.1+ or PowerShell 7
- Pester 5+ (`Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser`)
- Git Bash (used for commit operations only)

## Workflow

1. Run `scripts/generate-keyword-details.ps1` — produces `skills/powerlanguage-keywords-reference/{keywords-index.md, details/}` and `tests/test_*.txt`.
2. Open each `tests/test_*.txt` in MultiCharts → PowerLanguage Editor → Verify (Ctrl+F3). All three must compile clean.
3. If any compile errors, the editor names the failing keyword. Fix `details/<Category>/<Keyword>.md`'s signature, re-run the generator, re-verify.
4. `Invoke-Pester scripts/tests/` should pass all unit tests.
5. Commit the regenerated `details/` and `tests/` artifacts.

### Failure semantics (fail-closed)

- If a keyword's verbatim lint still fails after every escalation step
  (placeholder description, then stripped signature/parameters), the generator
  **deletes the leaking detail file from disk**, records a hard failure, skips
  the index + fixture build entirely, and **exits 1**. Leaking content can never
  be indexed or committed.
- Any parse failure also aborts the run with exit 1 before index/fixture build.
- On a successful parse pass, a reconciliation step deletes any orphan
  `details/<Category>/<Keyword>.md` whose keyword is no longer in the parsed
  set (each deletion is logged), so removed/renamed CHM keywords don't get
  re-indexed forever. Empty category folders are removed too.
- `tests/test_function.txt` is a minimal explicit Function template (no keyword
  category routes to the Function script type).

## Module map

- `lib/Parse-Chm.psm1` — HTML→fields parser (decodes common HTML entities; abbreviation-aware first-sentence split)
- `lib/Paraphrase.psm1` — description rewriter (`Get-ParaphrasedDescription`, `Get-CleanedParamDescription`)
- `lib/Generate-Example.psm1` — category-aware original example generator (`New-KeywordExample`, `Get-CategoryAwareExample`, shared `Test-StringReturningKeyword` taxonomy)
- `lib/Write-DetailFile.psm1` — composes the final markdown
- `lib/Build-Index.psm1` — generates `keywords-index.md`
- `lib/Build-PlaFixtures.psm1` — generates `tests/test_*.txt` (order names are made unique per build: MultiCharts requires unique order names per script)
- `lib/Test-VerbatimLint.psm1` — ≥9-word verbatim copy detector (the paraphraser's own guard uses the same 9-word threshold)
- `generate-keyword-details.ps1` — top-level orchestrator
