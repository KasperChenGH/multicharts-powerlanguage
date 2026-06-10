# BarsSinceEntry

**Category:** Strategy_Position
**Signature:** `BarsSinceEntry(PosBack)`

Returns the number of bars elapsed since the position's entry. Called without an argument (or with 0), it refers to the **current** open position.

> **Warning:** `PosBack` is **position history, not a bar offset**. `BarsSinceEntry(1)` counts bars since entry of the position *one position ago* (the previous closed trade) — NOT a value from one bar back.

**Example (illustrative)**
```
If MarketPosition = 1 and BarsSinceEntry >= 20 Then
    Sell ("TimeExit") next bar at market;
```

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=BarsSinceEntry
