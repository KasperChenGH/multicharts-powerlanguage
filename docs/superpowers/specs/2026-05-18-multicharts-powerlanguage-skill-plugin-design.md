# MultiCharts PowerLanguage Skill Plugin — Design

**Date:** 2026-05-18
**Status:** Approved
**Author:** Kasper Chen

---

## Goal

Build a Claude Code skill plugin named `multicharts-powerlanguage` that teaches Claude how to read and write MultiCharts PowerLanguage code and how to look up the language's built-in functions. The plugin follows the on-disk format of the official [`superpowers`](https://github.com/obra/superpowers) plugin so it can be installed via the standard plugin marketplace flow and hosted on GitHub Pages / GitHub.

There is no public Claude skill for MultiCharts PowerLanguage today; this fills that gap.

---

## Scope

**In scope:** General MultiCharts PowerLanguage *language* and *platform* usage — what a new MultiCharts user needs to write a working indicator, signal, or function.

**Out of scope:** Trading strategy patterns, exit recipes, position-sizing formulas, indicator-selection methodology, alpha research, parameter-tuning heuristics, monte-carlo tooling. These are the author's strategy research — they're leakage from a different domain and would mislead public users into thinking the plugin endorses a particular trading style.

---

## Audience

Any MultiCharts PowerLanguage user. Examples are kept generic (no TXF / TWD / specific contract assumptions, no "92 strategies" references). Where a worked example needs a contract spec, use an abstract `BigPointValue` placeholder and say so.

---

## Repository layout

```
Multicharts-Powerlanguage-skill/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skills/
│   ├── multicharts-fundamentals/
│   │   └── SKILL.md
│   ├── powerlanguage-syntax/
│   │   └── SKILL.md
│   └── powerlanguage-functions/
│       ├── SKILL.md
│       └── functions-reference.md
├── docs/
│   └── superpowers/
│       └── specs/
│           └── 2026-05-18-multicharts-powerlanguage-skill-plugin-design.md
├── README.md
├── LICENSE                 (existing — MIT, Kasper Chen 2026)
└── package.json
```

### Why this layout

Mirrors the `superpowers` plugin convention exactly:

- `.claude-plugin/plugin.json` — plugin metadata (name, version, author, repo, license, keywords).
- `.claude-plugin/marketplace.json` — listing entry so the GitHub repo itself works as a single-plugin marketplace (`/plugin marketplace add <user>/Multicharts-Powerlanguage-skill`).
- `skills/<skill-name>/SKILL.md` — one folder per skill. Each `SKILL.md` has YAML frontmatter (`name`, `description`) plus a markdown body. The `description` field is the trigger Claude reads to decide whether to invoke the skill.
- Large reference material lives in a sibling `.md` file inside the skill folder (e.g. `functions-reference.md`). The `SKILL.md` stays small (fast to load); the reference is loaded on demand. This matches how superpowers handles `testing-anti-patterns.md` next to `test-driven-development/SKILL.md`.
- `package.json` mirrors the version/name (some harnesses read it).
- `README.md` documents install paths for Claude Code and any other supported harnesses, lists the three skills, and links to the LICENSE.

---

## The three skills

### 1. `multicharts-fundamentals`

**Trigger description (frontmatter):** Use when learning what MultiCharts is or deciding which PowerLanguage script type to write — covers platform overview, editions (Standard / .NET / Portfolio Trader), the three script types (Indicator / Signal / Function), script execution model (bar-close vs intra-bar-order-generation), data series (data1, data2, …), order keywords (Buy / Sell / SellShort / BuyToCover), and the unique-signal-name compile rule.

**Body covers:**
- What MultiCharts is and what PowerLanguage is (`.pla` files; EasyLanguage compatibility).
- Editions: MultiCharts (standard, PowerLanguage), MultiCharts .NET (C# / VB.NET), MultiCharts Portfolio Trader.
- The three script types and what each can do:
  - **Indicator** — plots only, cannot place orders.
  - **Signal** — places orders; one or more signals compose a Strategy.
  - **Function** — reusable calculation; returns via `FunctionName = value;`.
- Execution model: top-to-bottom on each bar close; IOG (intra-bar order generation) for per-tick execution.
- Multi-data series (`data1`, `data2`, …) and how to reference them.
- Order keywords and the **unique-signal-name rule** (every order name must be unique within a strategy or compile fails).

**Sources:** `multicharts_fundamentals.md` (full) + the uniqueness rule from `signal_naming.md` (rule only, not the personal naming table).

### 2. `powerlanguage-syntax`

**Trigger description (frontmatter):** Use when reading or writing PowerLanguage code — declarations (Inputs / Variables / Arrays), data types, `begin/end` semicolon rules, control flow (if/then/else, for, while, switch), bar references (Close, Close[N], Date, Time, BarNumber), operators, comments, built-in trade variables (MarketPosition, EntryPrice, BarsSinceEntry), and common gotchas like `MarketPosition(N)` being position history (not a bar offset) and bars being labeled by their close time.

**Body covers:**
- Declarations: `Inputs:`, `Variables:` (aliases: `Vars:`, `Var:`), arrays (`Array: name[size](initial)`).
- Data types: numeric, string, truefalse (bool).
- `begin … end` blocks and the semicolon rules (every `end` gets `;` *except* when followed by `else`).
- Control flow: `If … Then … Else`, `For … To … Begin … End`, `While`, `Switch … Case`.
- Bar references: `Close`, `Close[1]`, `Open`/`High`/`Low`/`Close`/`Volume`/`OpenInterest`, `Date`/`Time`/`BarNumber`.
- Operators (arithmetic, comparison, logical: `and` / `or` / `not`).
- Comments: `//` line, `{ }` block.
- Built-in trade-state variables: `MarketPosition`, `EntryPrice`, `BarsSinceEntry`, `CurrentContracts`.
- Order syntax (placement keywords, sizing, "next bar at market/limit/stop"), with examples.
- **Gotchas section:**
  - `MarketPosition(N)` returns *position history* (the position you held N positions ago), **not** the market position N bars ago — to detect a transition, store the previous bar's position in a variable (`_prevMP`) at end of bar.
  - MultiCharts labels each bar by its **close** time, not its open time. A 60-min bar covering 15:00–16:00 has `Time = 1600`. Filters like `If Time = 1500` will miss it.

**Sources:** `powerlanguage_reference.md` — only the language-syntax sections; scrub strategy-specific examples ("seller v4-v6", "Kway HU01W", named personal strategies, the "Strategy Code Structure — Canonical Layout" section, the "Custom Indicator Construction Patterns" section).

### 3. `powerlanguage-functions`

**Trigger description (frontmatter):** Use when looking up a PowerLanguage built-in or library function — the functions shipped with MultiCharts across the ADE framework, Global Variables (GV*), ADA/ADP period access, technical indicators, options pricing (OS_*), collections (Map/List), date/time utilities, strategy diagnostics, and INI file I/O.

**Body (`SKILL.md`):** Short trigger + a category index pointing into `functions-reference.md`. Categories:
1. Chart Drawing & Auto-Build (AB_*)
2. ADE Framework (ADE*, _ADE*)
3. Global Variables (GV*)
4. Trade Manager / Account Functions (Get*)
5. Session & Calendar Utilities
6. Futures Expiration / Close Dates
7. Technical Indicators
8. OHLC Period Access (ADA / ADP)
9. Options Pricing (OS_*)
10. Strategy Diagnostics & Equity
11. Position Sizing & Entry Tracking
12. Array & Utility Functions
13. Collection Framework (Map / List)
14. Date/Time Utilities
15. Chart Display Helpers
16. INI File I/O
17. ARPS Functions
18. Miscellaneous Functions
19. Empty / Stub Functions

**`functions-reference.md`:** The full 343-function catalog. Each entry: function name, source `.elf` file, inputs, purpose, return value. This is bulky reference material — Claude loads it only when looking up a specific function.

**Sources:** `mc_functions.md` (full file, light editorial pass for clarity).

---

## Content sourcing rules

The two source directories (`C:\Users\User\Desktop\Mc_Agent` and `C:\Users\User\Desktop\trade_agent\knowledge\coding`) contain overlapping files. When a file exists in both:

- For `powerlanguage_reference.md`, use the **larger 728-line version** from `trade_agent/coding/` as the base. Then drop these sections entirely (do not attempt to genericize — their value is tied to the specific strategies they describe):
  - "Custom Indicator Construction Patterns" (names personal strategies: seller v4-v6, Kway HU01W/HU07W/HU08W/HU10W).
  - "Strategy Code Structure — Canonical Layout" (personal section-comment convention: `{ === BUSINESS === }` / `{ === DIAGNOSTIC === }`).
  Keep "Bar Time Labeling Convention" (the close-time labeling rule) — it documents general MultiCharts behavior, not a strategy choice.
- For files identical in both sources, use either.

Files explicitly **excluded** from this plugin (they are strategy research, not language reference):
- `input_reduction.md`
- `exit_patterns.md`
- `position_sizing_formulas.md`
- `all_indicators_reference.md`
- `novel_indicators.md`
- `price_action_features.md`
- `monte_carlo_usage.md`
- The personal naming table in `signal_naming.md` (only the compile-rule survives, folded into skill 1).

Scrubbing checklist when copying content into `SKILL.md` bodies:
- Replace TXF / TWD / `BigPointValue = 200` with generic placeholders or example contract specs.
- Remove references to "92 strategies", "seller v4-v6", "Kway HU01W", etc.
- Remove personal section-comment conventions (`{ === BUSINESS === }`, `{ === DIAGNOSTIC === }`).
- Keep general gotchas, language rules, platform behavior. Drop user-specific exit/sizing/indicator opinions.

---

## Plugin metadata

`.claude-plugin/plugin.json`:

```json
{
  "name": "multicharts-powerlanguage",
  "description": "MultiCharts PowerLanguage skills for Claude: platform fundamentals, language syntax, and the built-in function reference.",
  "version": "0.1.0",
  "author": { "name": "Kasper Chen" },
  "homepage": "https://github.com/<user>/Multicharts-Powerlanguage-skill",
  "repository": "https://github.com/<user>/Multicharts-Powerlanguage-skill",
  "license": "MIT",
  "keywords": ["multicharts", "powerlanguage", "trading", "skills", "easylanguage"]
}
```

`.claude-plugin/marketplace.json`:

```json
{
  "name": "multicharts-powerlanguage-dev",
  "description": "MultiCharts PowerLanguage skills marketplace",
  "owner": { "name": "Kasper Chen" },
  "plugins": [
    {
      "name": "multicharts-powerlanguage",
      "description": "MultiCharts PowerLanguage skills for Claude: fundamentals, syntax, and built-in function reference.",
      "version": "0.1.0",
      "source": "./"
    }
  ]
}
```

`package.json`:

```json
{
  "name": "multicharts-powerlanguage",
  "version": "0.1.0"
}
```

(The repo URL and GitHub user need to be filled in once the user provides their GitHub handle.)

---

## README

The root `README.md` should cover:

1. **What this is** — one-paragraph pitch: a Claude Code skill plugin that teaches Claude to write and look up MultiCharts PowerLanguage.
2. **Install** — for now, Claude Code only (the user can extend later):
   ```text
   /plugin marketplace add <github-user>/Multicharts-Powerlanguage-skill
   /plugin install multicharts-powerlanguage@multicharts-powerlanguage-dev
   ```
3. **What's inside** — list the three skills with one-line descriptions.
4. **How it works** — skills auto-trigger based on conversation context (Claude reads the `description` frontmatter). Users don't need to invoke anything manually.
5. **License** — MIT (existing).
6. **Contributing / source** — link to the repo. No contribution guide for v0.1.

---

## Validation criteria

The plugin is complete when:

1. The three `SKILL.md` files exist with proper YAML frontmatter (`name` matches folder name, `description` starts with "Use when …").
2. `functions-reference.md` lists all 343 functions in the source catalog, organized by the 19 categories.
3. No file under `skills/` contains TXF / TWD / "92 strategies" / personal-strategy-name references.
4. `.claude-plugin/plugin.json` and `marketplace.json` are valid JSON and parse with the same shape as the superpowers equivalents.
5. `README.md` documents the install command.
6. A manual test from a fresh Claude Code instance: install the plugin from a local path, ask "what's the difference between a MultiCharts indicator and a signal?" — the `multicharts-fundamentals` skill should auto-invoke.

---

## Versioning

Start at `0.1.0`. Bump minor for new skills, patch for content fixes within a skill. The version lives in three places: `plugin.json`, `marketplace.json`, `package.json` — keep them in sync.

---

## Out-of-scope decisions deferred

- **Other harnesses (Codex, Gemini, OpenCode, Copilot, Cursor, Factory).** The superpowers plugin supports all of them via per-harness install scripts and a `gemini-extension.json` / `.opencode/` / `AGENTS.md` etc. For v0.1 we ship Claude Code only. Adding other harnesses is a future minor-version bump.
- **A separate marketplace.** For v0.1 the repo itself is the marketplace (single-plugin). If this grows to multiple MultiCharts-related plugins later, split out a real marketplace repo.
- **CI / tests.** No automated tests in v0.1. The `superpowers:writing-skills` skill has a methodology for testing skills with subagents — adopt only if the plugin grows.
