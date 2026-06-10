# EntryPrice

**Category:** Strategy_Position
**Signature:** `EntryPrice(PosBack)`

Returns the entry price of the position. Called without an argument (or with 0), it refers to the **current** open position.

> **Warning:** `PosBack` is **position history, not a bar offset**. `EntryPrice(1)` is the entry price of the position *one position ago* (the previous closed trade) — NOT the entry price one bar back.

**Example (illustrative)**
```
If MarketPosition = 1 and Close > EntryPrice + 10 Then
    Sell ("TakeProfit") next bar at market;
```

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=EntryPrice
