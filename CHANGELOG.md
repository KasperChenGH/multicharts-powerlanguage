# Changelog

All notable changes to this plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.1] - 2026-06-10

### Changed

- Compressed all 10 SKILL.md frontmatter descriptions to tight trigger language (4,964 → ~2,400 chars, ~52% less). The skill listing is injected into every Claude Code session and counts against the user's `skillListingBudgetFraction` (default 1% of context); this halves the plugin's always-loaded footprint. Skill bodies are unchanged.

## [0.5.0] - 2026-06-10

### Added

- 10 custom PowerLanguage functions (`StochRSI`, `supertrend`, `NVI`, `PVI`, `Coppo`, `LWTI`, `TVI`, `SharpeRatio`, `WRSI`, `NewMA`) documented in the syntax skill, mapped in all 4 conversion skills, and covered by compile-test fixtures — 160 documented functions total
- README: full conversion teaching example across all 4 targets, plus a "How to use" section with natural-language usage examples

### Changed

- Split the 84 KB `pinescript-reference` skill into 3 focused sub-skills: `pinescript-core`, `pinescript-builtins`, `pinescript-visual`
- Harmonized all order-phrase examples on the explicit `at` form (`Buy ... Next Bar at Market;`)

### Fixed

Full-project review (~80 findings), fact-checked against official MultiCharts documentation:

- **Conversion correctness:** `Buy next bar at market` fills at the NEXT bar's open — Python/Rust/C++ templates now use a pending-order queue filled at next open; `AvgTrueRange` is a simple `Average(TrueRange, Len)`, not Wilder smoothing; `PercentR` is positive 0..100 (Williams %R + 100); `Volatility` is an EMA-weighted TrueRange average; `VolatilityStdDev` is annualized stdev of log returns; `TriAverage`, `StdError`, `SwingHigh`, `AvgPrice` definitions corrected
- **Keyword reference:** regenerated all 947 detail-file examples category-aware; examples never emit `Value1 = X;` for keywords that cannot be RHS values (connector words, reserved tokens, multi-word names, boolean returners, string returners)
- **Compile-error documentation:** empty `Switch`/`Case` body; reserved `I` loop variable replaced with `idx` in all loop examples; unique order names per Signal script
- **Build pipeline:** orchestrator module-scope import bug (nested `Import-Module -Force`), single-parameter array unrolling, PowerShell 5.1 em-dash/BOM encoding hazards; Pester suite green at 221/221

## [0.4.0] - 2026-06-08

### Added

- `powerlanguage-python-conversion` skill (pandas-ta and TA-Lib mappings, gotchas, checklists)
- Built-in function coverage expanded from 65 to 150 across the syntax skill and all conversion skills
- Conversion test files for the new functions in all 4 target languages
- PL strategies 6-14 added to all conversion test files

## [0.3.0] - 2026-06-05

### Added

- `powerlanguage-rust-conversion` skill (ta-rs mappings)
- `powerlanguage-cpp-conversion` skill (TA-Lib C API mappings)
- Rust and C++ conversion test files

## [0.2.0] - 2026-06-01

### Added

- `pinescript-reference` skill: Pine Script v5 types, declarations, built-in namespaces, plotting, control flow, UDFs, bar state, drawing objects, and gotchas
- `powerlanguage-pinescript-conversion` skill: bidirectional PL <-> Pine Script conversion with concept-mapping tables
- Pine Script conversion test files (PL -> Pine and Pine -> PL)

## [0.1.0] - 2026-05-28

Initial release (patched through 0.1.3).

### Added

- `multicharts-fundamentals` skill: platform concepts, study types, calculation model
- `powerlanguage-syntax` skill: full language syntax with pre-generation checklist
- `powerlanguage-keywords-reference` skill: 947 keywords across 40 categories, generated from the official CHM with original paraphrased descriptions and examples
- Compile-verified PowerLanguage test fixtures
- Maintainer build pipeline (CHM parser, paraphraser, example generator, verbatim-copy lint) with Pester tests
