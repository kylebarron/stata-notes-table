# Stata-notes-table

This code will export summary tables into pipe-delimited .txt files. This is close to a pipe-delimited table format that [Pandoc](http://pandoc.org/MANUAL.html#tables) can read (and then transform to TeX, Word, HTML, or PDF format), or you can also use another [package](https://github.com/mcaceresb/tablefill) to transform these into TeX/LyX format.

## Syntax

The general syntax of this package is 

**make_notes _varname_ [_if_] [_in_] [, _options_]**

where the options are as follows.

## Options

- `process(string)` - Type of summary statistics provided
    - `process("basic")` - 
    - `process("date")`
    - `process("dtm")`
    - `process("range")` - Prints `min to max`
    - `process("sum")` - Prints `Mean (Std) = mean (std), Range min to max`
    - `process("count")` - Prints `count`
- `regex(string)`
- `dates(numlist)`
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
- `out(string)` - Path to save table
- `pctmiss`
- `addobs`
- `replace`

## Output

The output is a pipe-delimited table like the following:

name|notes|pct_miss|obs|dups|label|short|type|order

