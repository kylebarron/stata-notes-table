# Stata-notes-table

This code will create and export summary tables into a pipe-delimited file. You can optionally export the table with a header readable in Markdown format. This format can be read by [Pandoc](http://pandoc.org/MANUAL.html#tables) and converted into TeX, Word, HTML, or PDF format.

## Syntax

The general syntax of this script is

**make_notes _varname_ [_if_] [_in_] [, _options_]**

where the options are as follows.

### Options

| Options                | Description                                                             |
|:-----------------------|:------------------------------------------------------------------------|
| **Summary Statistics** |                                                                         |
| **Process Options**    |                                                                         |
| `process(str)`         | Type of summary statistics to calculate; can be `basic`, `date`, `dtm`, `range`, `sum`, or `count`. |
| `process("basic")`     |                                                                         |
| `process("date")`      |                                                                         |
| `process("dtm")`       |                                                                         |
| `process("range")`     | Prints `min` to `max`                                                   |
| `process("sum")`       | Prints `Mean (Std) = mean (std), Range min to max`                      |
| `process("count")`     | Prints `count`                                                          |
| **Varlist Options**    |                                                                         |
| `regex(str)`           |                                                                         |
| `dates(numlist)`       |                                                                         |
| **File**               |                                                                         |
| `out(str)`             | Path to save table                                                      |
| `replace`              | Whether to replace file                                                 |
| `markdown`             | To save table with markdown table header                                |

- `top(integer)`
    - Options used only with `top()`:
    - `group(string)`
    - `ordersporder(string)`
    - `orderspnames(string)`
    - `sortvar`
    - `other(string)`
    - `addmissing(string)`
    - `sumvar(varname)`
    - `proportions`
    - `topkwargs(string)` - (Deprecated)
- `text(string)`
- `short(string)`
- `order(real)`
- `pctmiss`
- `addobs`

## Output

The output is a pipe-delimited table like the following:

name|notes|pct_miss|obs|dups|label|short|type|order

