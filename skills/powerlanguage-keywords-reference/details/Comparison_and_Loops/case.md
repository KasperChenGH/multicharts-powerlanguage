# case

**Category:** Comparison_and_Loops
**Signature:** `Case value: statement;`

**Example (illustrative)**
```
// case is used in expressions, e.g. If Close > Open Then ... ;
```

**Rules:**
- Must appear inside a `Switch ... Begin ... End;` block
- Every Case must have at least one executable statement after the colon — an empty body is a compile error
- Use `Value1 = Value1;` as a no-op if the case should do nothing

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=case
