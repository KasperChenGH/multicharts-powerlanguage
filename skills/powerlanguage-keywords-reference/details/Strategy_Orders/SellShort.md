# SellShort

**Category:** Strategy_Orders
**Signature:** `SellShort[("EntryLabel")][TradeSize]Entry`

Opens a short position with the size and timing given by the parameters.

**Parameters**
- `EntryLabel` *(string, optional)* — see official docs
- `TradeSize` *(numeric, optional)* — see official docs
- `Entry` *(order phrase, required)* — `next bar at market`, `this bar on close`, or `next bar at <price> Stop` / `next bar at <price> Limit`

**Example (illustrative)**
```
SellShort ( "SellShort_Demo" ) 1 Contract Next Bar at Market;
```

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=SellShort
