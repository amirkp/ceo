* Data for Fox, Kazempour, and Tang 
* Amir Kazempour 
* July, 2021
* Version 0.0.1


* code to run on segments_all.do in /Users/amir/Data
* download data from Compustat Historical Segments on WRDS


use "/Users/amir/Data/segments.dta",replace
* keep the earliest reporting for the data point, 
* This is supposed to be the most consistent, given that companies may change segment reporting over time
keep if srcdate==datadate
*(1,068,340 observations deleted)

*keep gvkey datadate stype sales SICS1 SICS2 emps nis ops geotp snms soptp1 soptp2 conm tic sic 


* remaining segment observations
* count
* 1,226,888


* dropping geographic segment records
keep if stype=="BUSSEG"| stype=="OPSEG"
* (634,569 observations deleted)


sort gvkey datadate

keep if sales>0
*(61,790 observations deleted)

drop if missing(sales)
*(2,949 observations deleted)


*drop missing SIC observations
drop if missing(SICS1)
*(12,609 observations deleted)



*four digit sale per segment
*egen segsale =total(sales), by(gvkey datadate SICS1)


gen year =year(datadate)


gen SICS2d = substr(SICS1,1,4)
la var SICS2d "2 Digit SIC Code"

egen segsale2d =total(sales), by(gvkey year SICS2d)
la var segsale2d "Total Sales per 2 digit SIC"

keep gvkey year segsale2d SICS2d conm tic snms

duplicates drop gvkey year segsale2d SICS2d conm tic,force
*(117,385 observations deleted)
*three digit sic version : (84,052 observations deleted)

egen totsale =total(segsale2d), by(gvkey year )
la var totsale "Total Sales per year "

gen segsaleratio =segsale2d/totsale
la var segsaleratio "Ratio of Segment Sales per Total Sales"


*HHI would be the same for all observations of segments in a year 
egen HHI = total(segsaleratio^2), by(gvkey year)
la var HHI "Herfindahl–Hirschman Index"

format conm %-20s 
format snms %-20s 




bysort gvkey year: gen nseg =_N
la var nseg "Number of Segments"


bysort gvkey year: gen fyid =_n
la var fyid "firm-year id"

drop if year==2020
*(545 observations deleted)


destring SICS2d, replace


/* commented temmp to check for 3d sic
merge m:1 SICS2d using "/Users/amir/github/ceo/Misc Data/SIC2d.dta"

**AFTER MERGE* 
keep if _merge ==3
*(30,399 observations deleted)

drop _merge
rename description SICdesc
*/
save "/Users/amir/Data/segments_tomerge", replace


	



