# MarketPosition

**Category:** Strategy_Position
**Signature:** `MarketPosition(PosBack)`

Returns the strategy's market position: 1 = long, -1 = short, 0 = flat. Called without an argument (or with 0), it refers to the **current** position.

> **Warning:** the `PosBack` argument is **position history, not a bar offset**. `MarketPosition(1)` is the position of the *previous closed trade* (one position ago) — NOT the position one bar ago. To detect position changes bar-to-bar, store `MarketPosition` in a variable each bar and compare (see the `_prevMP` transition pattern in the `powerlanguage-syntax` skill).

**Example (illustrative)**
```
Variables: prevMP(0);
If MarketPosition = 1 and prevMP <> 1 Then
    Print("Opened long this bar");
prevMP = MarketPosition;
```

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=MarketPosition
