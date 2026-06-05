---
name: powerlanguage-cpp-conversion
description: >-
  Use when converting, translating, porting, or migrating code between
  MultiCharts PowerLanguage and C++, in either direction. Contains a
  lightweight Strategy base class scaffold, concept mapping tables, semantic
  difference documentation, and pre/post-conversion checklists. References
  powerlanguage-syntax for PowerLanguage-specific details. Recommends
  TA-Lib for technical indicators.
---

# PowerLanguage ↔ C++ Conversion

## How to use

This skill covers the structural and semantic differences between MultiCharts PowerLanguage and C++ for algorithmic trading. It does not duplicate the syntax rules of PowerLanguage — for declarations, bar references, control flow, and built-in function signatures use the `powerlanguage-syntax` skill. When performing a conversion in either direction, work through Part 0 (structural template) to set up the boilerplate, then Part 1 (concept mapping) for line-by-line translation, then review Part 2 (semantic differences and gotchas), and finally run through the relevant checklist in Part 3 before calling the output complete.

---

## Part 0: Structural Template

PowerLanguage runs the entire script top-to-bottom on each bar close automatically. C++ has no implicit bar loop, no built-in OHLCV type, and no order submission mechanism. Every PL-to-C++ conversion targets the framework-agnostic scaffold below.

### Bar struct

```cpp
#include <cstdint>
#include <string>
#include <vector>

struct Bar {
    double open;
    double high;
    double low;
    double close;
    double volume;
    int64_t time;       // Unix epoch seconds
    size_t bar_number;  // 1-based to match PL convention
};
```

### Order types

```cpp
enum class Side { Long, Short };

enum class OrderType { Market, Limit, Stop };

struct Order {
    std::string label;
    Side side;
    OrderType type;
    double price;  // 0.0 for Market
    double qty;
};
```

### Strategy base class

```cpp
class Strategy {
public:
    virtual ~Strategy() = default;
    virtual void on_bar(const std::vector<Bar>& bars,
                        std::vector<Order>& orders) = 0;
};
```

### Strategy subclass skeleton

```cpp
#include "ta_libc.h"  // TA-Lib

class MyStrategy : public Strategy {
public:
    // Inputs (PL: Inputs: Length(20))
    MyStrategy(int length, double threshold)
        : length_(length), threshold_(threshold) {}

    void on_bar(const std::vector<Bar>& bars,
                std::vector<Order>& orders) override;

private:
    // Inputs (immutable after construction)
    int length_;
    double threshold_;

    // Variables (PL: Variables: my_var(0))
    double my_var_ = 0.0;

    // Position state (PL: MarketPosition, EntryPrice, etc.)
    int position_ = 0;           // -1, 0, +1
    double entry_price_ = 0.0;
    int bars_since_entry_ = 0;
    double current_contracts_ = 0.0;
};
```

### TA-Lib call pattern

```cpp
// Extract close prices into a contiguous array (TA-Lib needs parallel arrays)
std::vector<double> closes(bars.size());
for (size_t i = 0; i < bars.size(); ++i) closes[i] = bars[i].close;

// Batch API: compute SMA over the full close array
int outBeg = 0, outNBElement = 0;
std::vector<double> sma_out(bars.size());
TA_SMA(0, static_cast<int>(closes.size()) - 1,
       closes.data(), length_,
       &outBeg, &outNBElement, sma_out.data());

// Current bar's SMA is the LAST valid output element
double current_sma = sma_out[outNBElement - 1];
```

The output array is NOT aligned with the input array. The first valid output is at `sma_out[0]`, which corresponds to `closes[outBeg]`. The current value is always `sma_out[outNBElement - 1]`.

### Main loop

```cpp
int main() {
    std::vector<Bar> bars = load_bars("data.csv"); // user-provided
    MyStrategy strategy(20, 0.5);
    std::vector<Order> orders;

    for (size_t i = 0; i < bars.size(); ++i) {
        orders.clear();
        std::vector<Bar> history(bars.begin(), bars.begin() + i + 1);
        strategy.on_bar(history, orders);
        // execute orders against simulated book...
    }
    return 0;
}
```

The `history` vector up to and including bar `i` mirrors PL's implicit bar-by-bar execution. `bars.back()` inside `on_bar()` is the current bar.

### Incremental alternative (TA-Lib RT)

TA-Lib RT is a community fork that adds streaming APIs: `TA_SMA_StateInit()`, `TA_SMA_State()`, `TA_SMA_StateFree()`. These maintain internal state across calls, avoiding full-array recomputation on each bar. Use TA-Lib RT when performance matters for large bar counts.

---

## Part 1: Concept Mapping

### Table 1 — Declarations

| PowerLanguage | C++ | Notes |
|---|---|---|
| `Inputs: Length(20)` | `int length_` member + constructor param | Inputs become const or private members set at construction |
| `Variables: myVar(0)` | `double my_var_ = 0.0` member | Mutable members; initialize in-class or in the constructor initializer list |
| `Value1` .. `Value99` | named member (e.g., `double rsi_val_ = 0.0`) | Must rename to meaningful identifiers |
| `Condition1` .. `Condition99` | named member (e.g., `bool is_oversold_ = false`) | Same: rename to typed `bool` members |
| `Arrays: buf[10](0)` | `double buf_[11] = {};` or `std::vector<double> buf_(11, 0.0)` | PL `[10]` means last index is 10 (11 elements) |
| `IntraBarPersist myVar(0)` | `double my_var_ = 0.0` member (same as Variables) | C++ has no bar-close vs intra-bar distinction; all members persist |

---

### Table 2 — Data Access

| PowerLanguage | C++ | Notes |
|---|---|---|
| `Open`, `High`, `Low`, `Close`, `Volume` | `bars.back().open`, `.high`, `.low`, `.close`, `.volume` | `bars.back()` for current bar |
| `Close[1]` | `bars[bars.size() - 2].close` | Lookback N: `bars[bars.size() - 1 - n].close`. Check `bars.size() > n` to avoid UB. |
| `Close of Data2` | separate `const std::vector<Bar>& bars2` parameter | PL Data2 is a second chart feed; pass a second vector reference |
| `Date` | `std::gmtime(&bar.time)` → `tm_year`, `tm_mon`, `tm_mday` | PL `Date` is YYMMDD integer; C++ uses `<ctime>` or `<chrono>` |
| `Time` | `std::gmtime(&bar.time)` → `tm_hour`, `tm_min` | PL `Time` is HHMM integer |
| `BarNumber` / `CurrentBar` | `bar.bar_number` or `i + 1` (loop index) | PL is 1-based |

---

### Table 3 — Technical Indicators

| PowerLanguage | C++ (TA-Lib) | Notes |
|---|---|---|
| `Average(Close, Length)` | `TA_SMA(0, endIdx, inClose, length, &outBeg, &outNB, outSma)` | Current value: `outSma[outNB - 1]` |
| `XAverage(Close, Length)` | `TA_EMA(0, endIdx, inClose, length, &outBeg, &outNB, outEma)` | Same batch pattern |
| `RSI(Close, Length)` | `TA_RSI(0, endIdx, inClose, length, &outBeg, &outNB, outRsi)` | Returns 0–100 range |
| `Stochastic(...)` | `TA_STOCH(0, endIdx, inHigh, inLow, inClose, fastK, slowK, slowKMAType, slowD, slowDMAType, &outBeg, &outNB, outSlowK, outSlowD)` | Full %K/%D smoothing control — maps better to PL's 11-param version than Pine's simple `ta.stoch` |
| `ADX(Length)` | `TA_ADX(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outAdx)` | Direct equivalent |
| `CCI(Close, Length)` | `TA_CCI(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outCci)` | Note: TA-Lib CCI uses HLC, not just Close |
| `AvgTrueRange(Length)` | `TA_ATR(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outAtr)` | Requires HLC arrays |
| `BollingerBand(Close, Length, 2)` | `TA_BBANDS(0, endIdx, inClose, length, 2.0, 2.0, TA_MAType_SMA, &outBeg, &outNB, outUpper, outMiddle, outLower)` | Returns three arrays: upper, middle, lower |
| `Close Crosses Over MA` | `prev_close <= prev_ma && close > ma` | No built-in crossover in TA-Lib; implement as two-bar comparison |
| `Close Crosses Under MA` | `prev_close >= prev_ma && close < ma` | Same pattern |
| `Highest(Close, Length)` | `TA_MAX(0, endIdx, inClose, length, &outBeg, &outNB, outMax)` | Direct equivalent |
| `Lowest(Close, Length)` | `TA_MIN(0, endIdx, inClose, length, &outBeg, &outNB, outMin)` | Direct equivalent |
| `MomentumFunc(Close, Length)` | `TA_MOM(0, endIdx, inClose, length, &outBeg, &outNB, outMom)` | Direct equivalent |

---

### Table 4 — Strategy Orders

| PowerLanguage | C++ | Notes |
|---|---|---|
| `Buy("label") next bar market` | `orders.push_back({"label", Side::Long, OrderType::Market, 0.0, 1.0})` | Push to the orders vector |
| `SellShort("label") next bar market` | `Order{"label", Side::Short, OrderType::Market, 0.0, 1.0}` | `Side::Short` for short entry |
| `Sell("label") next bar market` | Close long: set `position_ = 0` or push a close-position variant | **WARNING: PL `Sell` exits a long — do NOT map to `Side::Short`** |
| `BuyToCover("label") next bar market` | Close short: set `position_ = 0` | PL `BuyToCover` exits an existing short |
| `Buy("label") next bar at price limit` | `Order{"label", Side::Long, OrderType::Limit, price, 1.0}` | Limit order |
| `Buy("label") next bar at price stop` | `Order{"label", Side::Long, OrderType::Stop, price, 1.0}` | Stop order |
| `SetStopLoss(dollars)` | `stop_price = entry_price_ - dollars / (qty * point_value)` | PL takes a dollar amount; C++ must convert to price level |
| `SetProfitTarget(dollars)` | `target_price = entry_price_ + dollars / (qty * point_value)` | Same dollar-to-price conversion |

---

### Table 5 — Plotting

| PowerLanguage | C++ | Notes |
|---|---|---|
| `Plot1(value, "label")` | `std::cout << label << ": " << value << "\n"` or log to file | No chart in C++; output to stdout, file, or results container |
| `SetPlotColor(1, Red)` | N/A | No visual output; skip or store as metadata |
| `SetPlotWidth(1, 2)` | N/A | Skip |
| `NoPlot(1)` | skip output for that bar | Conditional: don't write to results |

---

### Table 6 — Control Flow

| PowerLanguage | C++ | Notes |
|---|---|---|
| `If cond Then Begin ... End;` | `if (cond) { ... }` | C++ requires parentheses around condition |
| `If cond Then ... Else ...` | `if (cond) { ... } else { ... }` | Direct mapping |
| `For i = 1 to n Begin ... End;` | `for (int i = 1; i <= n; ++i) { ... }` | PL `For` is inclusive; use `<=` in C++ |
| `While cond Begin ... End;` | `while (cond) { ... }` | Direct mapping |
| `Switch (expr) Begin Case 1: ... End;` | `switch (expr) { case 1: ... break; default: break; }` | C++ `switch` requires `break;` to prevent fallthrough |
| `Once Begin ... End;` | `if (first_bar_) { ... first_bar_ = false; }` | Use a bool member; PL `Once` runs on first bar only |

---

### Table 7 — Other Built-ins and Features

| PowerLanguage | C++ | Notes |
|---|---|---|
| `MarketPosition` | `position_` (int: −1/0/+1) | Track manually as member; update on fills |
| `EntryPrice` | `entry_price_` (double) | Track manually |
| `CurrentContracts` | `current_contracts_` (double) | Track manually |
| `BarsSinceEntry` | `bars_since_entry_` (int) | Increment each bar while in position; reset on entry |
| `Print("text")` | `std::cout << "text" << std::endl` | Use iostream or fprintf |
| `#BeginCmtry ... #EndCmtry` | No equivalent | Skip or log |
| `Alert("msg")` | `std::cerr << "ALERT: msg" << std::endl` or callback | Design depends on framework |

---

## Part 2: Semantic Differences and Gotchas

1. **`Sell` does not mean "go short".** In PowerLanguage, `Sell` exits an existing long position. The C++ equivalent is closing the position (setting `position_` to 0). Do not create a new short entry as a translation of `Sell`.

2. **PL is implicitly bar-driven; C++ requires an explicit loop.** PowerLanguage executes the entire script top-to-bottom on each bar close automatically. In C++, you must write the `for (size_t i = 0; i < bars.size(); ++i)` loop and call `on_bar()` on each iteration.

3. **Bar lookback causes undefined behavior without bounds checking.** PL `Close[5]` silently returns 0 if fewer than 6 bars exist. C++ `bars[bars.size() - 6]` is undefined behavior when `bars.size() < 6` — likely a crash, but possibly silent corruption. Always check `bars.size() > n` before lookback access.

4. **TA-Lib uses batch computation, not streaming.** TA-Lib functions like `TA_SMA` process an entire array at once and return `outBegIdx` (first valid output index) and `outNBElement` (count of valid outputs). Calling TA-Lib on every bar with a growing history slice recomputes the entire series each time. For performance, consider TA-Lib RT's streaming API or caching previous results.

5. **TA-Lib `outBegIdx` offset is the most common TA-Lib mistake.** The output array is NOT aligned with the input array. The first valid output is at `output[0]`, which corresponds to `input[outBegIdx]`. The current bar's value is `output[outNBElement - 1]`. Ignoring this offset and reading `output[inputIndex]` produces incorrect indicator values.

6. **Crossover/crossunder has no TA-Lib built-in.** PL `Crosses Over` / `Crosses Under` are language keywords. TA-Lib has no crossover function. Implement as: `bool crossed_over = prev_a <= prev_b && a > b;`. Store previous-bar values as member variables.

7. **Dollar amounts versus price levels for stops.** `SetStopLoss` and `SetProfitTarget` in PL accept a dollar amount. C++ must convert to price levels explicitly: `stop_price = entry_price_ - stop_dollars / (qty * point_value)`.

8. **Position state is not tracked automatically.** PL provides `MarketPosition`, `EntryPrice`, `CurrentContracts`, and `BarsSinceEntry` as built-in variables updated by the engine. In C++, you must maintain these as class members and update them manually on order fills.

9. **C++ has no `Value1..Value99` or `Condition1..Condition99`.** Replace with named, typed class members using descriptive identifiers.

10. **TA-Lib output arrays must be pre-allocated.** All `TA_*` functions write into caller-allocated arrays. Size them at least as large as the input array. Failing to allocate enough space causes a buffer overflow. Use `std::vector` instead of raw arrays to avoid this class of bugs.

11. **Multi-data series requires explicit design.** PL `Close of Data2` accesses a second feed bound to the chart. In C++, pass `const std::vector<Bar>& bars2` as a second parameter. There is no implicit secondary-feed mechanism.

12. **No Portfolio Money Management (PMM) equivalent.** PL's PMM allows a single script to govern position sizing across multiple instruments. C++ has no built-in portfolio abstraction. You must implement cross-instrument logic as a separate portfolio manager that calls individual strategy instances.

---

## Part 3: Conversion Checklists

### PL → C++ Pre-Conversion

- [ ] List every `Inputs:` declaration; note name, type, default — each becomes a constructor parameter and private member
- [ ] List every `Variables:` declaration; note initial values — each becomes a private member initialized in-class or in the constructor
- [ ] Identify all `Value1..Value99` and `Condition1..Condition99` usages; plan meaningful replacement names
- [ ] Identify all indicator calls; confirm each has a TA-Lib equivalent (check `ta_func.h` for the function name)
- [ ] Locate all `Data2` / `Data3` references; decide on multi-feed architecture
- [ ] Locate all `SetStopLoss`, `SetProfitTarget`, and dollar-based parameters; note point value for conversion
- [ ] Check for `IntraBarPersist` variables; decide whether tick-level behavior matters
- [ ] Identify all `.elf` function calls; plan conversion to C++ free functions or member functions

### PL → C++ Post-Conversion

- [ ] Every `Sell` maps to closing the long, not entering short — audit all order keywords
- [ ] Every `BuyToCover` maps to closing the short, not entering long
- [ ] All lookback accesses (`Close[N]`) guarded with `bars.size() > n`
- [ ] All TA-Lib output arrays properly pre-allocated (use `std::vector`, not raw arrays)
- [ ] All TA-Lib results read from `output[outNBElement - 1]`, not `output[inputIndex]` — `outBegIdx` offset accounted for
- [ ] `Crosses Over` / `Crosses Under` implemented as two-bar comparisons
- [ ] `MarketPosition`, `EntryPrice`, `CurrentContracts`, `BarsSinceEntry` tracked as manually updated members
- [ ] Dollar-based stop/target amounts converted to price levels
- [ ] `Value1..Value99` and `Condition1..Condition99` renamed to descriptive typed members
- [ ] Code compiles with `g++ -std=c++17 -Wall -Wextra -Werror` with zero errors and zero warnings
- [ ] Strategy back-tested on the same instrument and date range as PL original; trade count and net P&L in the same order of magnitude

### C++ → PL Pre-Conversion

- [ ] List all class members and categorize: inputs (const/set-once) vs variables (mutable) vs indicator state
- [ ] Identify all TA-Lib function calls; map each to the PL built-in (TA_SMA → Average, TA_EMA → XAverage, TA_RSI → RSI, etc.)
- [ ] Check for `switch` statements with fallthrough — PL `Switch` does not fallthrough
- [ ] Identify any C++ libraries beyond TA-Lib; plan PL equivalents or inline reimplementation
- [ ] Check for explicit position-tracking members; confirm they can be replaced by PL's built-in `MarketPosition`, `EntryPrice`, etc.

### C++ → PL Post-Conversion

- [ ] Every short entry maps to `SellShort`, not `Sell`
- [ ] Every long close maps to `Sell`, not `SellShort`
- [ ] All `bars[bars.size() - 1 - n].close` lookbacks converted to `Close[n]`
- [ ] All manual crossover comparisons converted to PL `Crosses Over` / `Crosses Under` keywords
- [ ] All class members categorized: const inputs → `Inputs:`, mutable state → `Variables:`
- [ ] All TA-Lib batch calls replaced with PL function calls (e.g., `TA_SMA(...)` → `Average(Close, Length)`)
- [ ] TA-Lib `outBegIdx` / `outNBElement` index arithmetic eliminated — PL handles lookback alignment internally
- [ ] Price-level stops/targets converted to dollar amounts for `SetStopLoss` / `SetProfitTarget`
- [ ] Script compiled in MultiCharts PowerEditor with zero errors before testing
