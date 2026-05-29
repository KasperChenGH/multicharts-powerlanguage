# multicharts-powerlanguage

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.2-blue.svg)](https://github.com/KasperChenGH/multicharts-powerlanguage)
[![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-plugin-blueviolet.svg)](https://github.com/KasperChenGH/multicharts-powerlanguage)

A public Claude Code plugin for [MultiCharts](https://www.multicharts.com/) PowerLanguage — gives Claude expert knowledge of the language used to write Indicators, Signals, and Functions. Works on Windows, macOS, and Linux.

**947 keywords · 64 compile-verified functions · 3 auto-activating skills**

## Example

**Prompt:**
> Write a MultiCharts signal that enters long when RSI crosses below 30 and exits when it crosses above 70, with a 2% stop loss.

**Generated PowerLanguage (compiles with 0 errors):**
```
Inputs:
    RSI_Length(14),
    Oversold(30),
    Overbought(70),
    StopLossPct(2);

Variables:
    MyRSI(0);

MyRSI = RSI(Close, RSI_Length);

If MyRSI Crosses Below Oversold Then
    Buy ("RSI Long") Next Bar at Market;

If MyRSI Crosses Above Overbought Then
    Sell ("RSI Exit") Next Bar at Market;

SetStopLoss(StopLossPct * 0.01 * EntryPrice);
```

## What's inside

Three skills that auto-activate based on what you're asking Claude to do:

- **`multicharts-fundamentals`** — what MultiCharts is, when to use which script type (Indicator / Signal / Function), the execution model, multi-data series, order keywords, and the unique-signal-name compile rule.
- **`powerlanguage-syntax`** — declarations, the `begin/end` semicolon rule, control flow, bar references, operators, comments, built-in trade-state variables, 64 compile-verified built-in function signatures (Average, RSI, Stochastic, ADX, DirMovement, …), and code-generation gotchas (variable-name collisions with functions, single-letter aliases, loop-counter declarations, Length-only function signatures, order syntax).
- **`powerlanguage-keywords-reference`** — a categorized reference covering 947 official PowerLanguage keywords (40 categories from MultiCharts's own help system). Each keyword has signature, parameters, a paraphrased description, and a link to the official wiki page.

## Install (Claude Code)

```bash
/plugin marketplace add KasperChenGH/multicharts-powerlanguage
/plugin install multicharts-powerlanguage@multicharts-powerlanguage-dev
```

After install, the three skills auto-trigger when relevant. You don't have to invoke them manually — when you ask Claude something about MultiCharts or PowerLanguage, the right skill activates.

## Verifying keyword signatures (maintainer only)

The `tests/` directory contains 9 plain-text PowerLanguage source files that exercise keywords and code patterns inside unreachable `If False Then Begin … End;` blocks — so the compiler verifies syntax without executing anything. They are NOT `.pla` archives; they cannot be imported via File → Import.

| File | Study type | What it covers |
|---|---|---|
| `test_indicator.txt` | Indicator | 947 CHM keywords |
| `test_signal.txt` | Signal | 947 CHM keywords |
| `test_function.txt` | Function | 947 CHM keywords |
| `test_builtins.txt` | Signal | 64 built-in function (`.elf`) signatures |
| `test_syntax.txt` | Signal | If/Else, For/While, Switch, Once, operators, crosses over/under |
| `test_orders.txt` | Signal | Buy/Sell/SellShort/BuyToCover × Market/Limit/Stop/Close, SetStopLoss/SetProfitTarget |
| `test_declarations.txt` | Signal | Inputs, Variables, Arrays, IntraBarPersist, multi-data, Value1–99 |
| `test_plotting.txt` | Indicator | Plot1–4, SetPlotColor/Width/Style, TL/Text/Arw drawing |
| `test_strategies.txt` | Signal | 5 mini-strategies combining indicators, conditions, and orders |

To run the compile-test, for each file:

1. Open MultiCharts → PowerLanguage Editor → File → New → choose the matching script type (Indicator / Signal / Function).
2. Open the corresponding `tests/test_*.txt` in any text editor, copy all (Ctrl+A → Ctrl+C).
3. Paste into the new study (Ctrl+A → Ctrl+V replaces the template).
4. Press **F3** (Verify). Expected: 0 errors, 0 warnings.

This is a maintainer-only sanity check; end users never need to run it.

## How it works

Skills are markdown files with YAML frontmatter (a `name` and a `description`). Claude reads each plugin's skill descriptions and decides on the fly which to invoke. There are no install-time scripts, no runtime hooks, and no platform-specific tooling — the plugin works identically on Windows, macOS, and Linux.

## Attribution

MultiCharts® and PowerLanguage® are trademarks of MCT Limited. The keyword summaries in this plugin are original paraphrased descriptions written for this plugin; the authoritative documentation lives at https://www.multicharts.com/. Each keyword detail file links back to its official wiki page.

See `NOTICE` for the full attribution.

## License

MIT — see `LICENSE`.

## Source

https://github.com/KasperChenGH/multicharts-powerlanguage
