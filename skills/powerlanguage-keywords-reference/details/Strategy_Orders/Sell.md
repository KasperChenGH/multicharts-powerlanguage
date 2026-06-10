# Sell

**Category:** Strategy_Orders
**Signature:** `Sell[("ExitLabel")][From Entry("EntryLabel")][TradeSize[Total]] Exit;`

Closes part or all of any open long entries per the given parameters. Never opens a short position. If `EntryLabel` is not specified, all open long entries are closed. With `From Entry("EntryLabel")`, the exit applies only to that entry. `TradeSize` followed by `Total` closes only the given number of contracts/shares, first-in-first-out.

**Parameters**
- `ExitLabel` *(string, optional)* — names the exit order (must be unique within the script)
- `EntryLabel` *(string, optional)* — ties the exit to a specific named entry (`From Entry("...")`)
- `Exit` *(order phrase, required)* — `next bar at market`, `this bar on close`, or `next bar at <price> Stop` / `next bar at <price> Limit`

**Example (illustrative)**
```
Sell ( "Sell_Demo" ) 1 Contract Next Bar at Market;
Sell ( "TrailExit" ) From Entry ( "LE" ) Next Bar at EntryPrice + 10 Stop;
```

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=Sell
