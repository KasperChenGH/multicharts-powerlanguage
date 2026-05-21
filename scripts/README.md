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

1. Run `scripts/generate-keyword-details.ps1` — produces `skills/powerlanguage-keywords-reference/{keywords-index.md, details/}` and `tests/test_*.pla`.
2. Open each `tests/test_*.pla` in MultiCharts → PowerLanguage Editor → Verify (Ctrl+F3). All three must compile clean.
3. If any compile errors, the editor names the failing keyword. Fix `details/<Category>/<Keyword>.md`'s signature, re-run the generator, re-verify.
4. `Invoke-Pester scripts/tests/` should pass all unit tests.
5. Commit the regenerated `details/` and `tests/` artifacts.

## Module map

- `lib/Parse-Chm.psm1` — HTML→fields parser
- `lib/Paraphrase.psm1` — description rewriter
- `lib/Generate-Example.psm1` — original example generator
- `lib/Write-DetailFile.psm1` — composes the final markdown
- `lib/Build-Index.psm1` — generates `keywords-index.md`
- `lib/Build-PlaFixtures.psm1` — generates `tests/test_*.pla`
- `lib/Test-VerbatimLint.psm1` — ≥10-word verbatim copy detector
- `generate-keyword-details.ps1` — top-level orchestrator
