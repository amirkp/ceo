* merging all three files execucomp, fundamentals, segmentss (tomerge versions)


*Load executive compensation data 
*use "/Users/amir/Data/execucomp_tomerge.dta", replace



* we use segments file to merge ceo with segments then we should just keep one 
use "/Users/amir/Data/segments_tomerge.dta",replace

keep gvkey year HHI nseg
duplicates drop
*(104,261 observations deleted)

* create a variable for last year's HHI and nseg as company's characteristic
bysort gvkey (year):gen HHI_prev = HHI[_n-1]
bysort gvkey (year):gen nseg_prev = nseg[_n-1]



save segments_final, replace

use "/Users/amir/Data/fundamentals_tomerge.dta",replace

merge 1:1 gvkey year using "/Users/amir/Data/segments_final.dta"

