---
name: powerlanguage-syntax
description: Use when reading or writing PowerLanguage code — declarations (Inputs, Variables, Arrays), data types (numeric, string, truefalse), the begin/end semicolon rules, control flow (If/Then/Else, For, While, Switch), bar references (Close, Close[N], Date, Time, BarNumber), operators, comments, the built-in trade-state variables (MarketPosition, EntryPrice, BarsSinceEntry, CurrentContracts), and common gotchas like MarketPosition(N) being position history (NOT bar offset) and bars being labeled by their close time (NOT open time).
---

# PowerLanguage Syntax

## Declarations

Every script starts with declarations. Order matters: `Inputs:` comes before `Variables:` (or its aliases `Vars:`, `Var:`); both come before code.

```pascal
Inputs:
    Length(20),
    Threshold(0.0);

Variables:
    avg(0),
    triggered(False);

Arrays:
    buffer[10](0);
```

- **Inputs** — parameters exposed in the script's Format window. Each gets a default value in parentheses. Read-only inside the script.
- **Variables / Vars / Var** — script state. Each gets an initial value. Persist across bars within the same chart.
- **Arrays** — fixed-size collections. `[size]` is the index of the last element (zero-based by default), `(initial)` initializes every slot.

## Data types

PowerLanguage is loosely typed but each value is one of:

| Type | What it is | Literal examples |
|---|---|---|
| Numeric | Floating-point number | `0`, `1.5`, `-3.14` |
| String | Text | `"hello"`, `"LE"` |
| TrueFalse (bool) | Boolean | `True`, `False` |

Type is inferred from initial value in `Variables:` / `Inputs:` declarations.

## The `begin … end` rule and semicolons

`begin` opens a block; `end` closes it. **Every `end` gets a semicolon EXCEPT when followed by `else`.**

```pascal
If condition Then Begin
    statement1;
    statement2;
End                     // NO semicolon — else follows
Else Begin
    statement3;
End;                    // semicolon — outer statement boundary
```

Forgetting a semicolon on a terminal `End` is the most common compile error new PowerLanguage users hit. The rule is mechanical: if the next token is `Else`, no semicolon; otherwise yes.

## Control flow

```pascal
If x > 0 Then Begin ... End;

If x > 0 Then ... Else If x = 0 Then ... Else ... ;

For i = 1 To 10 Begin
    sum = sum + i;
End;

While condition Begin ... End;

Switch (n) Begin
    Case 1: ... ;
    Case 2: ... ;
    Default: ... ;
End;
```

## Bar references

`Close` is the close price of the current bar; `Close[1]` is the close one bar ago; `Close[N]` is N bars ago. Same indexing for `Open`, `High`, `Low`, `Volume`, `OpenInterest`.

| Built-in | Meaning |
|---|---|
| `Close`, `Open`, `High`, `Low` | OHLC of current bar |
| `Volume` | Volume of current bar |
| `OpenInterest` | OI of current bar (futures/options) |
| `Date` | Bar date as `YYYMMDD` integer (note: only 7 digits for years up to 2099, format is `(YYYY-1900)*10000 + MM*100 + DD`) |
| `Time` | Bar **close** time as `HHMM` integer — see gotcha below |
| `BarNumber` | Sequential count, same as `CurrentBar` |

## Operators

- Arithmetic: `+`, `-`, `*`, `/`
- Comparison: `=`, `<>`, `>`, `<`, `>=`, `<=`
- Logical: `and`, `or`, `not` (lowercase; `and` is a keyword, not `&&`)

## Comments

- Line comment: `// up to end of line`
- Block comment: `{ braces — can span multiple lines }`

The `{ … }` block-comment form is also how PowerLanguage code authors traditionally write file headers.

## Built-in trade-state variables (Signal scripts)

Inside a Signal script, these are always available — no declaration needed:

| Variable | Meaning |
|---|---|
| `MarketPosition` | `1` if long, `-1` if short, `0` if flat |
| `CurrentContracts` | Absolute size of current position |
| `EntryPrice` | Average fill price of the current position |
| `BarsSinceEntry` | Bars since the current position was entered |
| `BarsSinceExit(N)` | Bars since the Nth-most-recent exit |

## Order syntax (high-level recap)

```pascal
Buy ("LE") 1 Contract Next Bar at Market;
Sell ("LX") 1 Contract Next Bar at Market;
SellShort ("SE") 1 Contract Next Bar at Market;
BuyToCover ("SX") 1 Contract Next Bar at Market;
```

Quantities use `Contract` / `Contracts` (futures, FX) or `Share` / `Shares` (equities). The price-placement keyword (`Market`, `Limit`, `Stop`, `This Bar on Close`) determines when the fill happens. See `powerlanguage-keywords-reference` for each order keyword's full signature.

## Gotchas

### `MarketPosition(N)` is position history, NOT bar offset

A natural-looking expression like `MarketPosition(1)` reads as "the market position one bar ago" — but it actually returns the position **one trade ago**. So `MarketPosition(1)` on bar 50, when the strategy has been flat for the last 30 bars, returns whatever the previous closed position was (long or short), not `0`.

To detect a position transition between bars (e.g. "did we just enter long?"), store the previous bar's position at the END of each bar:

```pascal
Variables:
    _prevMP(0);

If MarketPosition <> _prevMP Then Begin
    // transition just happened this bar
    ...
End;

_prevMP = MarketPosition;     // end of bar
```

This is the canonical pattern. Don't rely on `MarketPosition(1)` for transition detection.

### Bars are labeled by their CLOSE time, not open time

A 60-minute bar covering 15:00–16:00 has `Time = 1600`, not `Time = 1500`. A filter like `If Time = 1500 Then …` will never match that bar.

To check whether the current bar is the first bar of the night session at 15:00, write:

```pascal
If Time = 1600 Then ...     // for 60-min bars
If Time = 1505 Then ...     // for 5-min bars (first close after 15:00)
If Time = 1501 Then ...     // for 1-min bars
```

Add one bar's worth of minutes to the session-start clock time.

### Inputs are read-only

You cannot assign to an Input inside a script. If you need a mutable copy, declare a Variable and copy from the Input once.

### Variable types are fixed at first assignment

`Variables: x(0);` makes `x` numeric for the life of the script. You can't later assign a string to it. Same for `True`/`False` initial values (bool) and `""` (string).
