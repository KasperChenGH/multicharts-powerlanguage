---
name: multicharts-fundamentals
description: Use when you need to understand what MultiCharts is, which PowerLanguage script type to write (Indicator vs Signal vs Function), how scripts execute (bar-close vs intra-bar-order-generation), how to reference multiple data series (data1, data2, ...), how Buy/Sell/SellShort/BuyToCover orders are issued, or what the unique-signal-name compile rule is. Triggers for orientation questions about the MultiCharts platform and the structural choices in a PowerLanguage script.
---

# MultiCharts Fundamentals

## What MultiCharts is

MultiCharts is a Windows trading platform from MCT Limited (Gibraltar). It connects to multiple data feeds and brokers, runs technical analysis and discretionary trading from charts and DOM, and executes algorithmic strategies written in PowerLanguage. It also includes QuoteManager (local market-data storage) and Market Scanner (multi-symbol monitoring).

## What PowerLanguage is

PowerLanguage (PL) is the scripting language inside MultiCharts. Source code is edited inside the PowerLanguage Editor and stored in MultiCharts's internal studio database — it doesn't have a standalone source-file extension. Exported study bundles use the `.pla` extension (PowerLanguage Archive — a ZIP-based binary format), and these are brought into another machine via PowerLanguage Editor → File → Import. When sharing or pasting raw source code outside the studio, plain text (`.txt`) is the convention. PowerLanguage is functionally compatible with TradeStation's EasyLanguage — most EasyLanguage scripts run unmodified in MultiCharts, and MultiCharts adds a few of its own keywords (FileAppend, PMM, FormatDate, …) that don't exist in EasyLanguage.

Key characteristics:
- Pascal-flavored syntax (begin/end blocks, semicolon statement terminators).
- Event-driven: the entire script runs top-to-bottom on each bar close (or on each tick when IOG is enabled).
- Compiled by the PowerLanguage Editor; can call external DLLs for C++ / VB integration.

## Editions

| Edition | Language | Notes |
|---|---|---|
| MultiCharts (Standard) | PowerLanguage | The original; what most users mean by "MultiCharts" |
| MultiCharts .NET | C# / VB.NET | Same engine, .NET 4.8 hosting, real-time debugging in Visual Studio |
| MultiCharts Portfolio Trader | PowerLanguage + portfolio APIs | Multi-instrument backtesting & live trading module |

This skill covers Standard (PowerLanguage). The .NET edition uses different language but the same platform concepts apply.

## The three script types

Every PowerLanguage script is exactly one of these:

- **Indicator** — visual analysis. Can `Plot1`, draw trendlines, paint bars, display text. **Cannot** issue orders.
- **Signal** — automated trading logic. Can `Buy`, `Sell`, `SellShort`, `BuyToCover`. A **Strategy** in MultiCharts is one or more Signals applied to a chart; each Signal contributes orders.
- **Function** — reusable calculation. Returns a value by assigning to its own name: `MyFunc = result;`. Called from Indicators, Signals, or other Functions.

A Signal can't plot. An Indicator can't trade. A Function can't do either; it just returns a number, boolean, or string. Picking the right script type before you start writing avoids large rewrites.

## How scripts execute

By default, the entire script runs once per bar, at the bar's close. References like `Close[1]` mean "the close of the bar before this one." Order placement keywords schedule orders for the *next* bar — `Buy ... Next Bar at Market` is the standard idiom.

For tick-level execution, enable **Intra-bar Order Generation (IOG)** in script properties. With IOG on, the script runs on every incoming tick, and the values of `Open`/`High`/`Low`/`Close` reflect the developing bar in real time. IOG is needed when you want orders that depend on intra-bar price changes (e.g. stop-orders that should fire as soon as price touches a level, not at the next bar close).

## Multi-data series

A chart can host more than one data series — `data1` is the primary, `data2`/`data3`/… are additional series mapped through chart properties. Access them by suffix:

```
Close of data2          // close of the second series
Average(Close of data2, 20)
```

Common uses: pair-trading (data2 = the second leg), regime filters (data2 = a higher-timeframe series of the same instrument), or cross-market signals (data2 = a related contract).

## Order keywords (Signal scripts only)

- `Buy` — opens / adds to a long position. Cancels any open short on fill.
- `Sell` — exits a long position.
- `SellShort` — opens / adds to a short position. Cancels any open long on fill.
- `BuyToCover` — exits a short position.

General shape:

```
Buy ( "EntryLabel" ) <quantity> Contract[s]|Share[s] Next Bar at Market;
Buy ( "EntryLabel" ) <quantity> Contract[s] Next Bar at <price> Limit;
Buy ( "EntryLabel" ) <quantity> Contract[s] Next Bar at <price> Stop;
Buy ( "EntryLabel" ) <quantity> Contract[s] This Bar on Close;
```

Each form is documented in detail in the `powerlanguage-keywords-reference` skill — invoke that for full signatures and parameter rules.

## The unique-signal-name compile rule

**Every order name within one Signal script must be unique.** If you write:

```
Buy ("LE") 1 Contract Next Bar Market;
// ... later ...
Buy ("LE") 1 Contract Next Bar 100 Stop;
```

…the script will not compile. MultiCharts uses the order name string to track which order produced which fill, so duplicate names are rejected at compile time. Pick distinct labels — `"LE_Market"` and `"LE_Stop"`, or `"LE"` and `"LE_Pyramid"`. This rule applies to all four order keywords (`Buy`, `Sell`, `SellShort`, `BuyToCover`), and is enforced per-Signal — two different Signals on the same chart can each have their own `"LE"`.

## When to invoke other skills

- **`powerlanguage-syntax`** — for grammar questions: semicolons in `begin/end`, control flow, declarations, common gotchas.
- **`powerlanguage-keywords-reference`** — for any specific keyword: signature, parameters, what category it belongs to.
