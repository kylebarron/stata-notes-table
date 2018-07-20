*! version 0.2 2018-01-05 Kyle Barron, barronk@nber.org
*! version 0.1 created by Mauricio Caceres, caceres@nber.org
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
            replace           /// Whether to replace the file
            markdown          /// To be rendered as a pipe table readable by Pandoc https://pandoc.org
            colwidths(numlist integer) ///
            cols(str)         /// Columns to export
                              ///     name, notes, pct_miss, obs, dups, label, short, type, order, all
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

    if ("`outdata'" != "") {
        * Determine which columns to write
        if ("`cols'" == "" | "`cols'" == "all") local cols "all"
        else {
            forval i = 1 / `:word count `cols'' {
                local word = "`:word `i' of `cols''"
                local `word' = "`word'"
            }
        }

        if ("`name'" == "name" | "`cols'" == "all")         local 1 "True"
        if ("`notes'" == "notes" | "`cols'" == "all")       local 2 "True"
        if ("`pct_miss'" == "pct_miss" | "`cols'" == "all") local 3 "True"
        if ("`obs'" == "obs" | "`cols'" == "all")           local 4 "True"
        if ("`dups'" == "dups" | "`cols'" == "all")         local 5 "True"
        if ("`label'" == "label" | "`cols'" == "all")       local 6 "True"
        if ("`short'" == "short" | "`cols'" == "all")       local 7 "True"
        if ("`type'" == "type" | "`cols'" == "all")         local 8 "True"
        if ("`order'" == "order" | "`cols'" == "all")       local 9 "True"

        if ("`replace'" != "") {
            file open filein using `outdata', write replace
            local mdheader `"Name|Notes|Percent Missing|Obs|Duplicates|Label|Short label|Type|order"'
            local rawheader `"name|notes|pct_miss|obs|dups|label|short|type|order"'

            foreach header in mdheader rawheader {
                qui di ustrregexm("``header''", "^(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)$")

                local head
                forval i = 1/9 {
                    if ("``i''" == "True") {
                        local str = ustrregexs(`i')
                        local head "`head'`str'|"
                    }
                }
                local head = substr("`head'", 1, length("`head'") - 1)
                local new_`header' "`head'"
            }

            if ("`colwidths'" != "") {
                local breakln
                foreach val of local colwidths {
                    local dashes = "-" * `val'
                    local breakln "`breakln'`dashes'|"
                }
                local breakln = substr("`breakln'", 1, length("`breakln'") - 1)
            }
            else {
                local breakln = ustrregexra("`head'", "(?<=\||^)[^-]*?(?=\||$)", "--")
            }

            if ("`markdown'" != "") {
                file write filein `"`new_mdheader'"' _n
                file write filein `"`breakln'"' _n
            }
            else {
                file write filein `"`rawheader'"' _n
            }
            file close filein
        }
        file open filein using `outdata', write append
        local would_be_final_text `"`output'|`:variable label `varlist''|`short'|`:type `varlist''|`order'"'

        qui di ustrregexm("`would_be_final_text'", "^(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)$")
        local final_text
        forval i = 1 / 9 {
            if ("``i''" == "True") {
                local str = ustrregexs(`i')
                local final_text "`final_text'`str'|"
            }
        }
        local final_text = substr("`final_text'", 1, length("`final_text'") - 1)
        di `"`final_text'"'

        file write filein `"`final_text'"' _n
        file close filein
    }
end
