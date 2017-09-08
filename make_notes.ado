*! version 0.1 6Sep2016 Mauricio Caceres, caceres@nber.org
*! Make notes for my standard data description appendix table

capture program drop make_notes
program make_notes
    syntax varname [if] [in], ///
        [                     ///
            process(str)      ///
            regex(str)        ///
            sumvar(str)       ///
            dates(numlist)    ///
            top(int 0)        ///
            topkwargs(str)    ///
            text(str)         ///
            short(str)        ///
            order(real 0)     ///
            OUTdata(str)      ///
            pctmiss           ///
            addobs            ///
            replace           ///
        ]

    marksample touse, strok novarlist
    if ("`sumvar'" == "") {
        local sumvar `varlist'
    }

    if ("`process'" == "basic") {
        cap duplicates report `varlist' if `touse'
        if (_rc != 0) {
            qui count_uniques `varlist'
        }
        local uniques = trim("`:di %21.0gc `r(unique_value)''")
        if (`r(unique_value)' < `top') {
            local output = "`varlist'|"
            local semic  = ""
        }
        else {
            local output = trim("`varlist'|`uniques' `text'")
            local semic  = "; "
        }
    }
    else if ("`process'" == "date") {
        qui sum `varlist' if `touse'
        local nobs = `r(N)'
        local mean = trim("`:di %td_NN/CCYY `r(mean)''")
        local mind = trim("`:di %td_NN/CCYY `r(min)''")
        local maxd = trim("`:di %td_NN/CCYY `r(max)''")

        tempvar year
        qui gen `year' = year(`varlist') if `touse'
        if "`dates'" == "" {
            di "No dates specified to check. Only range reported."
            local ydates ""
        }
        else {
            foreach y of local dates {
                qui count if `year' == `y'
                local n1960 = trim("`:di %9.1f 100 * `r(N)' / `nobs''")
                local ydates `ydates', `y' (`n1960'%)
            }
            gettoken c ydates: ydates
            local ydates "`:di trim(`"`ydates'"')'; "
        }
        local output = "`varlist'|" + "`ydates'" + "Mean = `mean', Range = `mind' to `maxd'"
    }
    else if ("`process'" == "dtm") {
        qui sum `varlist' if `touse'
        local nobs = `r(N)'
        local mean = trim("`:di %tc_NN/CCYY `r(mean)''")
        local mind = trim("`:di %tc_NN/CCYY `r(min)''")
        local maxd = trim("`:di %tc_NN/CCYY `r(max)''")

        tempvar year
        qui gen `year' = year(`varlist') if `touse'
        if "`dates'" == "" {
            di "No dates specified to check. Only range reported."
            local ydates ""
        }
        else {
            foreach y of local dates {
                qui count if `year' == `y'
                local n1960 = trim("`:di %9.1f 100 * `r(N)' / `nobs''")
                local ydates `ydates', `y' (`n1960'%)
            }
            gettoken c ydates: ydates
            local ydates "`:di trim(`"`ydates'"')'; "
        }
        local output = "`varlist'|" + "`ydates'" + "Mean = `mean', Range = `mind' to `maxd'"
    }
    else if ("`process'" == "range") {
        qui sum `varlist' if `touse'
        local rmin = trim("`:di %15.2f `r(min)''")
        local rmax = trim("`:di %15.2f `r(max)''")
        local output = trim("`varlist'|`rmin' to `rmax' `text'")
    }
    else if ("`process'" == "sum") {
        qui sum `varlist' if `touse'
        local rmin   = trim("`:di %15.2f `r(min)''")
        local rmax   = trim("`:di %15.2f `r(max)''")
        local rmean  = trim("`:di %15.2f `r(mean)''")
        local rstd   = trim("`:di %15.2f `r(sd)''")
        local output = trim("`varlist'|Mean (Std) = `rmean' (`rstd'), Range = `rmin' to `rmax' `text'")
    }
    else if ("`process'" == "count") {
        qui count if `varlist' & `touse'
        local counts = trim("`:di %21.0gc `r(N)''")
        local output = trim("`varlist'|`counts' `text'")
    }

    if ("`regex'" != "") {
        tempvar regexvar
        gen `regexvar' = regexs(1) if regexm(upper(`varlist'), "`regex'")
        qui count if !mi(`regexvar')
        if (`r(N)' > 0) {
            local sumvar `regexvar'
        }
    }

    if (`top' > 0) & ("`process'" != "date") {
        cap tabcustom `sumvar' if `touse', group(top`top') `topkwargs'
        if (_rc == 0) {
            matrix tc = r(tabcustom)
            local topvars `"`r(dispvars)'"'

            gettoken topvar topvars: topvars
            local tp = tc[1, 2]
            local topout `"`topvar' (`:di trim("`:di %9.1f `tp''")'%)"'
            forvalues i = 2 / `:word count `:rownames tc'' {
                gettoken topvar topvars: topvars
                local tp = tc[`i', 2]
                local topout `"`topout', `topvar' (`:di trim("`:di %15.1f `tp''")'%)"'
            }
            local output = `"`output'`semic'`topout'"'
        }
    }

    if ("`pctmiss'" != "") {
        qui count if `touse' & mi(`varlist')
        local nmiss = `r(N)'
        qui count if `touse'
        local pmiss = trim("`:di %9.1g 100 * `nmiss' / `r(N)''")
        local output = `"`output'|`pmiss'"'
    }
    else {
        local output = `"`output'|"'
    }

    if ("`addobs'" != "") {
        qui duplicates report
        local output = `"`output'|`:di _N'|`:di r(N) - r(unique_value)'"'
    }
    else {
        local output = `"`output'||"'
    }

    di `"`output'"'
    if ("`outdata'" != "") {
        if ("`replace'" != "") {
            file open filein using `outdata', write replace
            file write filein `"name|notes|pct_miss|obs|dups|label|short|type|order"' _n
            file close filein
        }
        file open filein using `outdata', write append
        file write filein `"`output'|`:variable label `varlist''|`short'|`:type `varlist''|`order'"' _n
        file close filein
    }
end
