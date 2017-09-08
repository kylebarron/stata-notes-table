*! version 0.1 16Sep2016 Mauricio Caceres, caceres@nber.org
*! Custom tabular based on collapse

* Custom tabular (useful when the number of categories is really large
* and you still want to see the distribution of the largest groups
cap program drop tabcustom
program tabcustom, rclass
    syntax varlist(max = 1) [if] [in], ///
    [                                  ///
        group(str)                     ///
        ordersporder(str)              ///
        orderspnames(str)              ///
        sortvar                        ///
        other(str)                     ///
        ADDMissing(str)                ///
        sumvar(varname)                ///
        PROPortions                    ///
    ]
    preserve
    cap keep `if'

    tempvar missing
    gen byte `missing' = mi(`varlist')

    marksample touse, strok
    markout `touse' `varlist', strok
    qui if ("`addmissing'" != "") {
        if ("`sumvar'" == "") {
            qui count if `missing'
            local miss_total = `r(N)'
        }
        else {
            qui sum `sumvar' if `missing'
            local miss_total = `r(sum)'
        }
        replace `touse' = 1 if `missing'
    }

    if ("`sumvar'" == "") {
        qui count if `touse'
        local all = `r(N)'
    }
    else {
        qui sum `sumvar' if `touse'
        local all = `r(sum)'
    }

    * Collapse by varlist
    * -------------------

    qui drop if mi(`varlist')
    local varname: variable label `varlist'
    qui keep if `touse'

    if ("`sumvar'" == "") {
        qui collapse (sum) total = `touse', by(`varlist')
    }
    else {
        qui collapse (sum) total = `sumvar', by(`varlist')
    }

    * Sort from largest to smallest
    * -----------------------------

    qui gen pct = 100 * total / `all'
    gsort -total
    qui gen pct_cum = sum(pct)

    format %15.0gc total
    format %5.1fc  pct pct_cum

    * Keep only largest by count/pct
    * ------------------------------

    local topmatch = regexm("`group'", "top([1-9][0-9]?)")
    if `topmatch' {
        local topreg `:di regexs(1)'
    }
    local pctmatch = regexm("`group'", "pct([1-9][0-9]?)")
    if `pctmatch' {
        local pctreg `:di regexs(1)'
    }

    if "`group'" == "pct" local subsets pct < 10
    else if "`group'" == "top" local subsets _n > 5
    else if `topmatch' local subsets _n > `topreg'
    else if `pctmatch' local subsets pct < `pctreg'
    else local subsets _n > 10
    local nrows = `:di _N'

    * Grouping the rest into "Other"
    * ------------------------------

    local dispvars dummy
    qui if ("`subsets'" != "") {
        sum total if `subsets'
        local restobs = r(sum)
        if (`r(sum)' > 0) {
            drop if `subsets'
            forvalues i = 1 / `:di %21.0g _N' {
                local dispvars `dispvars' `"`:di `varlist'[`i']'"'
            }

            if ("`other'" != "") {
                if ("`addmissing'" != "") {
                    local total = `:di %5.1f 100 - 100 * (`miss_total' / `all')'
                }
                else {
                    local total = 100.0
                }
                count if !(`subsets') & (strpos(`varlist', "`other'") > 0)
                if `r(N)' == 0 & regexm("`:type `varlist''", "str") {
                    set obs `:di _N + 1'
                    replace `varlist' = "`other'" in `:di _N'
                    replace total   = `restobs' in `:di _N'
                    replace pct     = `total' - pct_cum[_N - 1] in `:di _N'
                    replace pct_cum = `total' in `:di _N'
                }
                else {
                    tempvar order
                    gen `order' = _n
                    replace `order' = _N + 1 if (strpos(`varlist', "`other'") > 0)
                    sort `order'
                    replace pct_cum = sum(pct)
                    replace total   = total[_N] + `restobs' in `:di _N'
                    replace pct     = `total' - pct_cum[_N - 1] in `:di _N'
                    replace pct_cum = `total' in `:di _N'
                }
                local dispvars `dispvars' `"`other'"'
            }
        }
        else {
            forvalues i = 1 / `:di %21.0g _N' {
                local dispvars `dispvars' `"`:di `varlist'[`i']'"'
            }
        }
    }
    else {
        forvalues i = 1 / `:di %21.0g _N' {
            local dispvars `dispvars' `"`:di `varlist'[`i']'"'
        }
    }

    qui if ("`addmissing'" != "") {
        set obs `:di _N + 1'
        replace `varlist' = "`addmissing'" in `:di _N'
        replace total     = `miss_total' in `:di _N'
        replace pct       = 100.0 - pct_cum[_N - 1] in `:di _N'
        replace pct_cum   = 100.0 in `:di _N'
        local dispvars `dispvars' `"`addmissing'"'
    }

    qui if "`proportions'" != "" {
        replace pct     = pct     / 100
        replace pct_cum = pct_cum / 100
    }

    * Special Order, if requested
    * ---------------------------

    qui if ("`ordersporder'" != "") {
        tempvar order
        gen `order' = .
        forvalues i = 1 / `:word count `ordersporder'' {
            gettoken ospn orderspnames: orderspnames
            gettoken ospo ordersporder: ordersporder
            local svtype = "`:type `varlist''"
            di `"`ospo', `ospn', `svtype'"'

            if regexm("`svtype'", "byte|int|long|float|double") {
                replace `order' = `ospo' if (`varlist' == `ospn')
            }
            else if regexm("`svtype'", "str") {
                replace `order' = `ospo' if (`varlist' == `"`ospn'"')
            }
        }
        sort `order'
        replace pct_cum = sum(pct)
    }

    * Display results
    * ---------------

    qui if ("`sortvar'" != "") {
        sort `varlist'
        replace pct_cum = sum(pct)
    }
    list `varlist' total pct pct_cum
    mkmat total pct pct_cum, mat(tabcustom)
    restore

    gettoken dummy dispvars: dispvars
    return matrix tabcustom = tabcustom
    return local  dispvars  = `"`dispvars'"'
    return local  nrows     = `nrows'
end
