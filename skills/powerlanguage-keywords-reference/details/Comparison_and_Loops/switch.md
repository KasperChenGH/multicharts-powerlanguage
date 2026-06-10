# switch

**Category:** Comparison_and_Loops
**Signature:** `switch expr begin`

**Example (illustrative)**
```
// switch is used in expressions, e.g. If Close > Open Then ... ;
```

**Rules:**
- Every `Case` must contain at least one executable statement — an empty body (even with a comment) causes a syntax error
- No fallthrough — each Case runs only its own body (unlike C/C++ which needs `break`)
- Use `Value1 = Value1;` as a no-op placeholder for cases that should do nothing

*Official docs:* https://www.multicharts.com/trading-software/index.php?title=switch
