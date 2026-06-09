# case

**Category:** Comparison_and_Loops
**Signature:** `Case value: statement;`

**Example (illustrative)**
```
Switch (direction) Begin
    Case 0: Value1 = Value1;   // no-op — body CANNOT be empty
    Case 1: Buy next bar at market;
    Case 2: SellShort next bar at market;
End;
```

**Rules:**
- Must appear inside a `Switch ... Begin ... End;` block
- Every Case must have at least one executable statement after the colon — an empty body is a compile error
- Use `Value1 = Value1;` as a no-op if the case should do nothing

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=case
