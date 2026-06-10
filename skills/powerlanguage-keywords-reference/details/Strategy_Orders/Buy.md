# Buy

**Category:** Strategy_Orders
**Signature:** `Buy[("EntryLabel")][TradeSize]EntryType;`

Opens a long position with the size and timing given by the parameters.

**Parameters**
- `EntryLabel` *(string, optional)* — see official docs
- `TradeSize` *(numeric, optional)* — see official docs
- `EntryType` *(order phrase, required)* — `next bar at market`, `this bar on close`, or `next bar at <price> Stop` / `next bar at <price> Limit`

**Example (illustrative)**
```
Buy ( "Buy_Demo" ) 1 Contract Next Bar at Market;
```

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=Buy
