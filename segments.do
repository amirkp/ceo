* keep the earliest reporting
keep if srcdate==datadate
* (430,614 observations deleted)

keep gvkey datadate stype sales SICS1 SICS2 emps nis ops geotp snms soptp1 soptp2 conm tic sic 


* remaining observations
count
* 278,869


* dropping geographic segment records
keep if stype=="BUSSEG"| stype=="OPSEG"
* (135,446 observations deleted)


sort gvkey datadate

keep if sales>0
*(26,282 observations deleted)

drop if missing(sales)
*(758 observations deleted)

*drop missing SIC observations
drop if missing(SICS1)

*four digit sale per segment
*egen segsale =total(sales), by(gvkey datadate SICS1)


gen year =year(datadate)


gen SICS2d = substr(SICS1,1,2)
la var SICS2d "2 Digit SIC Code"

egen segsale2d =total(sales), by(gvkey year SICS2d)
la var segsale2d "Total SaleS per 2 digit SIC"

keep gvkey year segsale2d SICS2d conm 

duplicates drop

egen totsale =total(segsale2d), by(gvkey year )
la var totsale "Total Sales per year "

gen segsaleratio =segsale2d/totsale
la var segsaleratio "Ratio of Segment Sales per Total Sales"

egen HHI = total(segsaleratio^2), by(gvkey year)
la var HHI "Herfindahl–Hirschman Index"

format conm %-20s 




bysort gvkey year: gen nseg =_N
la var nseg "Number of Segments"


bysort gvkey year: gen fyid =_n
la var fyid "firm-year id"

drop if year==2020

destring SICS2d, replace

merge m:1 SICS2d using "/Volumes/GoogleDrive/My Drive/Courses/coa_paper/CEO Work/Scope Diversification Literature/Data/SIC2d.dta"
drop _merge
rename description SICdesc















****

**AFTER MERGE* 
keep if _merge ==3
*(30,399 observations deleted)




gen emp_n =emp/2300
bysort year: egen max_emp = max(emp) 
