# Plot

**Category:** Plotting
**Signature:** `PlotN[Offset](Expression[, "PlotName"[, PlotColor[, BgColor[, LineWidth]]]])` — N is the plot number 1..999; only Expression is required

**Parameters**
- `N` *(numeric, optional)* — see official docs
- `Expression` *(numeric, required)* — see official docs
- `PlotName` *(string, optional)* — see official docs
- `PlotColor` *(numeric, optional)* — see official docs
- `LineWidth` *(numeric, optional)* — see official docs
- `String` *(expression, required)* — see official docs

**Example (illustrative)**
```
Plot1(Average(Close, 20), "AvgC");
Plot2[1](Highest(High, 10), "HH10");  // offset: plot shifted 1 bar back
```

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=Plot
