---
name: pinescript-visual
description: >-
  Pine Script plotting and drawing — plot(), plotshape(), plotchar(),
  plotarrow(), bgcolor(), barcolor(), fill(), hline(), label.* (create,
  set, get, styles), line.* (segments, rays, extend), box.* (rectangles,
  supply/demand zones), table.* (fixed-position grids), map.* (key-value
  dictionaries), matrix.* (2D arrays, linear algebra), log.* (debugging),
  alerts (alert, alertcondition), and drawing object limits. Use when
  adding visual output to Pine Script. For language fundamentals, see
  pinescript-core. For built-in namespaces (ta.*, strategy.*), see
  pinescript-builtins.
---

# Pine Script Plotting & Drawing

## 1. Plotting Functions

### `plot()` — lines and value series

```pine
//@version=5
indicator("plot() demo", overlay = true)

ma_fast = ta.ema(close, 9)
ma_slow = ta.ema(close, 21)

plot(ma_fast, title = "EMA 9",  color = color.blue,   linewidth = 2)
plot(ma_slow, title = "EMA 21", color = color.orange,  linewidth = 1,
     style = plot.style_line)
```

**Plot styles:**

| Constant | Appearance |
|---|---|
| `plot.style_line` | Continuous line (default) |
| `plot.style_linebr` | Line that breaks at `na` values |
| `plot.style_histogram` | Vertical bars from a baseline (default 0) |
| `plot.style_columns` | Filled columns from a baseline |
| `plot.style_area` | Filled area below the line |
| `plot.style_areabr` | Filled area, breaks at `na` |
| `plot.style_circles` | Dots at each bar |
| `plot.style_cross` | Cross marks at each bar |
| `plot.style_stepline` | Staircase (holds value until next bar) |

### `plotshape()` — marker shapes at specific bars

```pine
plotshape(buy,  title = "Buy signal",  shape = shape.triangleup,
          location = location.belowbar, color = color.green,
          text = "BUY", textcolor = color.white, size = size.small)
```

Common `shape.*` constants: `shape.triangleup`, `shape.triangledown`, `shape.circle`, `shape.square`, `shape.diamond`, `shape.cross`, `shape.xcross`, `shape.arrowup`, `shape.arrowdown`, `shape.flag`, `shape.labelup`, `shape.labeldown`.

Common `location.*` constants: `location.abovebar`, `location.belowbar`, `location.top`, `location.bottom`, `location.absolute`.

### `plotchar()` — single Unicode character as marker

```pine
plotchar(gap_up, title = "Gap up", char = "▲",
         location = location.abovebar, color = color.teal, size = size.tiny)
```

### `plotarrow()` — directional arrows scaled by value

```pine
// Positive values → up arrows; negative values → down arrows
// Arrow height scales with the absolute value of series
plotarrow(momentum, title = "Momentum arrow",
          colorup = color.green, colordown = color.red)
```

### `bgcolor()` — color the chart background

```pine
bgcolor(overbought_zone ? color.new(color.red, 85) : na, title = "Overbought")
```

### `barcolor()` — recolor the price bars

```pine
barcolor(close > open ? color.new(color.teal, 20)
       : close < open ? color.new(color.maroon, 20)
       :                color.gray)
```

`barcolor()` affects only the primary chart bars — no effect in a sub-pane indicator.

### `fill()` — shade area between two plots

```pine
p_upper = plot(bb_upper, "BB Upper", display = display.none)
p_lower = plot(bb_lower, "BB Lower", display = display.none)
fill(p_upper, p_lower, color = color.new(color.blue, 88))
```

A common pattern is to create "invisible" helper plots (`display = display.none`) solely for use as `fill()` boundaries.

### `hline()` — static horizontal reference line

```pine
hline(70,  "Overbought", color = color.red,   linestyle = hline.style_dashed)
hline(50,  "Midpoint",   color = color.gray,  linestyle = hline.style_dotted)
hline(30,  "Oversold",   color = color.green, linestyle = hline.style_dashed)
```

`hline()` takes a `simple float` — the price level cannot vary bar by bar.

---

## 2. label.* — Labels

Labels attach text annotations to specific chart coordinates.

### Constructor

```pine
label.new(
    x,                   // bar index (int) or timestamp if xloc = xloc.bar_time
    y,                   // price level (float)
    text         = "",
    xloc         = xloc.bar_index,
    yloc         = yloc.price,
    color        = color.blue,
    style        = label.style_label_down,
    textcolor    = color.white,
    size         = size.normal,
    textalign    = text.align_center,
    tooltip      = ""
)
```

### Setter functions

| Function | What it changes |
|---|---|
| `label.set_x(id, x)` | Bar index or timestamp |
| `label.set_y(id, y)` | Price level |
| `label.set_xy(id, x, y)` | Position in one call |
| `label.set_text(id, text)` | Label text string |
| `label.set_color(id, color)` | Label background/border color |
| `label.set_textcolor(id, color)` | Text color |
| `label.set_style(id, style)` | Label style constant |
| `label.set_size(id, size)` | Text/marker size |
| `label.set_tooltip(id, tooltip)` | Tooltip text on hover |

### Getter functions

| Function | Returns |
|---|---|
| `label.get_x(id)` | `series int` — current x |
| `label.get_y(id)` | `series float` — current y |
| `label.get_text(id)` | `series string` — current text |

### Other functions

`label.copy(id)`, `label.delete(id)`, `label.all` (array of all labels)

### `label.style_*` constants

| Constant | Appearance |
|---|---|
| `label.style_label_down` | Callout box pointing downward (default) |
| `label.style_label_up` | Callout box pointing upward |
| `label.style_label_left` | Callout box pointing left |
| `label.style_label_right` | Callout box pointing right |
| `label.style_circle` | Filled circle |
| `label.style_cross` | Plus sign |
| `label.style_xcross` | X mark |
| `label.style_diamond` | Diamond shape |
| `label.style_flag` | Flag marker |
| `label.style_square` | Filled square |
| `label.style_triangleup` | Upward-pointing triangle |
| `label.style_triangledown` | Downward-pointing triangle |
| `label.style_arrowup` | Arrow pointing up |
| `label.style_arrowdown` | Arrow pointing down |
| `label.style_none` | Invisible — text only |

### Supporting constants

| Group | Values |
|---|---|
| `size.*` | `size.auto`, `size.tiny`, `size.small`, `size.normal`, `size.large`, `size.huge` |
| `xloc.*` | `xloc.bar_index` (default), `xloc.bar_time` |
| `yloc.*` | `yloc.price` (default), `yloc.abovebar`, `yloc.belowbar` |
| `text.align_*` | `text.align_left`, `text.align_center`, `text.align_right` |

> **Gotcha — label count limit:** Default max is **50 labels**. Raise to 500 with `max_labels_count = 500` in the `indicator()` or `strategy()` declaration.

---

## 3. line.* — Lines

Lines draw a segment (or ray) between two chart coordinates.

### Constructor

```pine
line.new(
    x1, y1,               // start point
    x2, y2,               // end point
    xloc   = xloc.bar_index,
    extend = extend.none,
    color  = color.blue,
    style  = line.style_solid,
    width  = 1
)
```

### Setter and getter functions

| Function | Description |
|---|---|
| `line.set_x1/y1/x2/y2(id, val)` | Move individual coordinates |
| `line.set_xy1/xy2(id, x, y)` | Set point in one call |
| `line.set_color/style/width(id, val)` | Visual properties |
| `line.set_extend(id, extend)` | Change extend mode |
| `line.get_x1/y1/x2/y2(id)` | Read coordinates |
| `line.get_price(id, x)` | Price on the line at bar index `x` (interpolated) |
| `line.copy(id)`, `line.delete(id)`, `line.all` | Management |

### `line.style_*` constants

`line.style_solid`, `line.style_dashed`, `line.style_dotted`, `line.style_arrow_left`, `line.style_arrow_right`, `line.style_arrow_both`

### `extend.*` constants

| Constant | Description |
|---|---|
| `extend.none` | Line drawn only between x1 and x2 |
| `extend.left` | Ray extending infinitely to the left |
| `extend.right` | Ray extending infinitely to the right |
| `extend.both` | Full infinite line through both points |

> **Gotcha — line count limit:** Default max is **50 lines**. Raise to 500 with `max_lines_count = 500`.

---

## 4. box.* — Boxes

Boxes draw filled rectangles between two price levels over a range of bars.

### Constructor

```pine
box.new(
    left, top, right, bottom,
    border_color = color.blue,  border_width = 1,  border_style = line.style_solid,
    extend       = extend.none, xloc         = xloc.bar_index,
    bgcolor      = color.new(color.blue, 90),
    text         = "",          text_size    = size.auto,
    text_color   = color.black, text_halign  = text.align_center,
    text_valign  = text.align_center
)
```

### Setter functions

`box.set_left/top/right/bottom`, `box.set_lefttop/rightbottom`, `box.set_border_color/width/style`, `box.set_bgcolor`, `box.set_extend`, `box.set_text/text_color/text_size`

### Getter functions

`box.get_left/top/right/bottom`

### Other

`box.copy(id)`, `box.delete(id)`, `box.all`

> **Gotcha — box count limit:** Default max is **50 boxes**. Raise to 500 with `max_boxes_count = 500`.

---

## 5. table.* — Tables

Tables display text in a fixed grid anchored to a corner of the chart pane.

### Constructor

```pine
table.new(
    position     = position.top_right,
    columns      = 2,
    rows         = 3,
    bgcolor      = color.new(color.gray, 80),
    frame_color  = color.gray,
    frame_width  = 1,
    border_color = color.gray,
    border_width = 1
)
```

### Cell functions

```pine
table.cell(table_id, column, row,
    text = "", text_color = color.black, text_size = size.normal,
    bgcolor = na, tooltip = "")
```

Partial updates: `table.cell_set_text`, `table.cell_set_bgcolor`, `table.cell_set_text_color`, `table.cell_set_text_size`

Other: `table.merge_cells(id, c1, r1, c2, r2)`, `table.clear(id, c1, r1, c2, r2)`, `table.delete(id)`

### `position.*` constants

`position.top_left`, `position.top_center`, `position.top_right`, `position.middle_left`, `position.middle_center`, `position.middle_right`, `position.bottom_left`, `position.bottom_center`, `position.bottom_right`

> **Gotcha — create with `var` or in `barstate.islast`:** Creating a new table on every bar wastes resources and flickers. Use `var table stats = table.new(...)` and update cells with `table.cell()`.

---

## 6. map.* — Maps

Maps store key-value pairs with O(1) lookup.

```pine
var map<string, float> tf_closes = map.new<string, float>()

map.put(tf_closes, "Daily", daily_close)
val = map.get(tf_closes, "Daily")         // na if not found
exists = map.contains(tf_closes, "Daily") // bool
```

Core functions: `map.put`, `map.put_all`, `map.get`, `map.contains`, `map.remove`, `map.keys`, `map.values`, `map.size`, `map.clear`, `map.copy`

Valid key types: `int`, `float`, `bool`, `string`, `color`. Max **50,000 pairs** per map.

---

## 7. matrix.* — Matrices

Two-dimensional typed arrays with linear algebra support.

```pine
m = matrix.new<float>(3, 3, 0.0)   // 3×3 float matrix, all zeros
matrix.set(m, 0, 0, 1.0)
val = matrix.get(m, 0, 0)
```

### Element access

`matrix.get/set/fill`, `matrix.row/col` (extract as array), `matrix.rows/columns/elements_count`, `matrix.reshape`

### Row/column manipulation

`matrix.add_row/add_col`, `matrix.remove_row/remove_col`, `matrix.swap_rows/swap_columns`, `matrix.submatrix`, `matrix.reverse`, `matrix.concat`

### Linear algebra

`matrix.transpose`, `matrix.det`, `matrix.inv`, `matrix.pinv`, `matrix.rank`, `matrix.trace`, `matrix.eigenvalues`, `matrix.eigenvectors`, `matrix.kron`, `matrix.mult`

### Statistics

`matrix.avg`, `matrix.max`, `matrix.min`, `matrix.sum`, `matrix.diff`, `matrix.median`, `matrix.mode`

### Boolean inspectors

`matrix.is_square`, `matrix.is_symmetric`, `matrix.is_diagonal`, `matrix.is_identity`, `matrix.is_zero`, `matrix.is_triangular`, `matrix.is_stochastic`, `matrix.is_binary`

> **Gotcha:** `matrix.det()`, `matrix.inv()`, `matrix.eigenvalues()` require **square matrices**. Row/column indices are **0-based**.

---

## 8. log.* — Logging

| Function | Severity |
|---|---|
| `log.info(message)` | Informational |
| `log.warning(message)` | Warning |
| `log.error(message)` | Error |

All accept format-string overloads: `log.info("RSI at bar {0}: {1}", bar_index, rsi_val)`

> **Gotcha:** Log output appears only in the **Pine Logs** panel (Pine Editor → Logs tab), not on the chart.

---

## 9. Alerts

### `alert()` — flexible, works in both indicators and strategies

```pine
if cross_up
    alert(str.format("BUY signal on {0}", syminfo.ticker), alert.freq_once_per_bar)
```

### `alertcondition()` — static, indicators only

```pine
alertcondition(cross_up, title = "EMA Cross Up", message = "Fast crossed above Slow")
```

- **Indicators only** — compile error in `strategy()`.
- Must be at **global scope** (not inside any `if` or function body).
- `title` and `message` must be **`const string`** — no dynamic construction.

### `alert.freq_*` constants

| Constant | Fires |
|---|---|
| `alert.freq_once_per_bar` | At most once per bar |
| `alert.freq_once_per_bar_close` | Only on confirmed close |
| `alert.freq_all` | Every matching tick |
| `alert.freq_once_per_alert` | Only one time ever |

---

## 10. Drawing Object Limits Summary

| Object | Default max | Max via declaration param |
|---|---|---|
| Labels | 50 | 500 (`max_labels_count = 500`) |
| Lines | 50 | 500 (`max_lines_count = 500`) |
| Boxes | 50 | 500 (`max_boxes_count = 500`) |
| Tables | No hard per-object limit | — |
| Maps | — | 50,000 pairs per map instance |
