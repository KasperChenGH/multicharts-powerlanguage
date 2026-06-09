# switch

**Category:** Comparison_and_Loops
**Signature:** `switch expr begin`

**Example (illustrative)**
```
Switch (n) Begin
    Case 0: Value1 = Value1;   // no-op — empty case body is a compile error
    Case 1: Buy next bar at market;
    Case 2: SellShort next bar at market;
    Default: ; // default must also have a statement
End;
```

**Rules:**
- Every `Case` must contain at least one executable statement — an empty body (even with a comment) causes a syntax error
- No fallthrough — each Case runs only its own body (unlike C/C++ which needs `break`)
- Use `Value1 = Value1;` as a no-op placeholder for cases that should do nothing

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=switch
