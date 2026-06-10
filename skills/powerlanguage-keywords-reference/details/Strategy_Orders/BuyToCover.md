# BuyToCover

**Category:** Strategy_Orders
**Signature:** `BuyToCover[("ExitLabel")][From Entry("EntryLabel")][TradeSize[Total]]Exit`

Closes part or all of any open short entries per the given parameters.

**Parameters**
- `ExitLabel` *(string, optional)* — see official docs
- `EntryLabel` *(string, optional)* — see official docs
- `TradeSize` *(numeric, optional)* — see official docs
- `Exit` *(order phrase, required)* — `next bar at market`, `this bar on close`, or `next bar at <price> Stop` / `next bar at <price> Limit`

**Example (illustrative)**
```
BuyToCover ( "BuyToCover_Demo" ) 1 Contract Next Bar at Market;
```

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=BuyToCover
