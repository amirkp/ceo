* Version 2: February 19, 2023




* merging all three files execucomp, fundamentals, segmentss (tomerge versions)


*Load executive compensation data 
*use "/Users/amir/Data/execucomp_tomerge.dta", replace
cd "/Users/amir/Data"


*gai file, drop one obs with missing execid 
use "/Users/amir/github/ceo/Misc Data/gai1992-2016.dta",replace 
drop if missing(execid)
drop if missing(gvkey)
save "/Users/amir/github/ceo/Misc Data/gai1992-2016.dta",replace

* we use segments file to merge ceo with segments then we should just keep one 
use "/Users/amir/Data/segments_tomerge.dta",replace

keep gvkey year HHI HHI_GEO HHI_BUS conm
duplicates drop 
*(104,261 observations deleted)
*(0 )
* create a variable for last year's HHI and nseg as company's  scope characteristic
bysort gvkey (year):gen HHI_prev = HHI[_n-1]
// bysort gvkey (year):gen nseg_prev = nseg[_n-1]

save segments_final, replace

use "/Users/amir/Data/fundamentals_tomerge.dta",replace

merge 1:1 gvkey year using "/Users/amir/Data/segments_final.dta"
keep if _merge ==3 
drop _merge

merge 1:1 gvkey year using "/Users/amir/Data/execucomp_tomerge1.dta"
keep if _merge==3 
drop _merge



*merging again with segment file this time for ceo type 
// keep gvkey execid exec_name year ex_gvkey ex_year ceoann SP500 char_stat ex_conm_ceo

drop if missing(execid)

*isid gvkey execid year




merge m:1 gvkey year using "/Users/amir/Data/segments_final.dta", keepusing(HHI)
keep if year <2019
keep if _merge ==3
drop _merge
//
// la var ex_HHI_ceo "CEO Experience HHI" 
// la var ex_nseg_ceo "CEO Experience Number of Segments"
// la var ex_conm_ceo "CEO Experience Company Name"
// la var ex_sale_ceo "CEO Experience Sale/Turnover (Net)"
// la var ex_emp_ceo "CEO Experience Number of Employees"
//
// la var HHI_prev "Company's Previous Year HHI"
// la var nseg_prev "Company's Previous Year Number of Segments"
//
//
// la var size1 "csho*prcc_f+at+ceq+txdb"
// la var size2 "oibdp-dp"
// la var size3 "sale"
// la var size4 "csho*prcc_f"
// la var size5 "emp"
//
// la var outcome1 "csho*prcc_f+at+ceq+txdb"
// la var outcome2 "oibdp-dp"
// la var outcome3 "sale"
// la var outcome4 "csho*prcc_f"
//
// destring execid, replace
// gen gvkey_str=gvkey
//
destring execid, replace
destring gvkey, replace





merge 1:1 gvkey execid year using "/Users/amir/github/ceo/Misc Data/gai1992-2016.dta", keepusing(GAI)
keep if _merge==3
drop _merge 


drop if missing(size1) | missing(size3) |missing(size5)



gen logsize1 = log(size1)

gen logsize2 = log(size2)

gen logsize3 = log(size3)

gen logsize4 = log(size4)

gen logsize5 = log(size5)


gen logtdc1 = log(tdc1)
gen logtdc2 = log(tdc2)



* positive GAI 
egen minGAI = min(GAI)
gen pGAI = GAI - minGAI 



gen negsale = -sale
bys year (negsale): gen salesrank = _n

keep if salesrank<350 |SP500 ==1

keep if year ==2013 


keep if logsize5>0
keep if logtdc1>0 

keep gvkey logsize5 logtdc1 HHI pGAI 


save estData, replace

export delimited using "/Users/amir/Data/est_data.csv", replace
 
 
// *For Jeremy's email
// listsome gvkey conm year execid HHI GAI sale emp  if year==2015 & ceoann=="CEO" & !missing(emp) & !missing(HHI) & !missing(sale) & !missing(GAI)
//
//
//
//
// // destring ex_year, replace
// // merge m:m execid ex_year using "/Users/amir/github/ceo/Misc Data/gai1992-2016.dta", keepusing(GAI)
// // keep if _merge==3not
//
// drop _merge
// gen negsale=-sale
// bys year (negsale): gen salerank =_n
//
// gen negat=-at
// bys year (negat): gen atrank =_n
//
// bys year: corr GAI HHI if salerank<501
// bys year: corr GAI HHI if salerank<1001



*keep exec_name execid ex_gvkey ex_year conm

*save current_ceo, replace 

