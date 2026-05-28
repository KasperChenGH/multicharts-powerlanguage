# multicharts-powerlanguage

The first public Claude Code plugin for [MultiCharts](https://www.multicharts.com/) PowerLanguage — gives Claude expert knowledge of the language used to write Indicators, Signals, and Functions. Works on Windows, macOS, and Linux.

## What's inside

Three skills that auto-activate based on what you're asking Claude to do:

- **`multicharts-fundamentals`** — what MultiCharts is, when to use which script type (Indicator / Signal / Function), the execution model, multi-data series, order keywords, and the unique-signal-name compile rule.
- **`powerlanguage-syntax`** — declarations, the `begin/end` semicolon rule, control flow, bar references, operators, comments, built-in trade-state variables, and the two main gotchas (`MarketPosition(N)` is position history not bar offset; bars are labeled by close time).
- **`powerlanguage-keywords-reference`** — a categorized reference covering 947 official PowerLanguage keywords (40 categories from MultiCharts's own help system). Each keyword has signature, parameters, a paraphrased description, and a link to the official wiki page.

## Install (Claude Code)

```bash
/plugin marketplace add KasperChenGH/Multicharts-Powerlanguage-skill
/plugin install multicharts-powerlanguage@multicharts-powerlanguage-dev
```

After install, the three skills auto-trigger when relevant. You don't have to invoke them manually — when you ask Claude something about MultiCharts or PowerLanguage, the right skill activates.

## Verifying keyword signatures (maintainer only)

`tests/test_indicator.txt`, `tests/test_signal.txt`, and `tests/test_function.txt` are plain-text PowerLanguage source files that exercise every keyword inside an unreachable `If False Then Begin … End;` block — so the compiler verifies syntax without executing anything. They are NOT `.pla` archives; they cannot be imported via File → Import.

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

https://github.com/KasperChenGH/Multicharts-Powerlanguage-skill
