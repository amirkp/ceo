* Data for Fox, Kazempour, and Tang 
* Amir Kazempour 

* Version 0.0.5 July 2021
* Version 0.6 Feb 2023

* testing version change in github, delete
* Run on the raw executive compensation file, downloaded from WRDS. 
use "/Users/amir/Data/execucomp.dta", replace




* dealing with an inconsistent execid for John C. Plant
* execid should be unique for every executive
/*. list gvkey execid coname year   if exec_fullname =="John C. Plant"

        +-----------------------------------------------+
        |  gvkey   execid                 coname   year |
        |-----------------------------------------------|
120998. | 010301    20932                TRW INC   1999 |
121004. | 010301    20932                TRW INC   2000 |
121010. | 010301    20932                TRW INC   2001 |
216408. | 028192    59000   HOWMET AEROSPACE INC   2019 |
        +-----------------------------------------------+
*/

replace execid ="20932" if exec_fullname =="John C. Plant"




* variable names in the new data file are all capitalized. include the following line if capitalized var names appear in the raw data

* run the following line if not installed previously
* ssc install tsspell
* ssc install egenmore

*rename *, lower
*run the following if name not changed in the original file 
rename exec_fullname exec_name

* calculating CEO's tenure Cox tsspell

sort co_per_rol year
xtset co_per_rol year
tsfill
tsspell co_per_rol
rename _seq tenure



* create an indicator for CEOs to show according to the count of their appearance in the data to date. starting from 92. 

drop if missing(execid)
drop spindex spcode




bysort gvkey year: egen nceoy = max(ceoann=="CEO") 

*. count if nceoy==0
* 20,965
* There are companies-year with no CEO identified in the data
* if executive's becameceo is before the observation year and firm has no CEO identified use the executive as the CEO in for that year 

replace ceoann="CEO" if nceoy==0 & year(becameceo)<=year 
*(3,414 real changes made)



*calculate total number of ceo per firm per year
bysort gvkey year: egen tceon = total(ceoann=="CEO") 

*. count if tceo>1
*  957

* if more than 1 ceo per firm year then choose the ceo with the latest becameceo date as ceo (if available) 
bysort gvkey ceo year (becameceo): replace ceoann="" if _n!=_N & ceoann=="CEO"
bysort gvkey year: egen tceon1 = total(ceoann=="CEO") 



keep if ceoann=="CEO"


keep gvkey exec_name execid title execrank ceoann age salary bonus tdc1 tdc2 gender ticker year




save execucomp_tomerge1, replace



* isid gvkey execid year




* Data for Fox, Kazempour, and Tang 
* Amir Kazempour 
* 
* Version 0.1; July, 2021
* Version 0.2; February, 2023 
* Version 0.3: February 17, 2023
*** Second commented output is reported when GEOSEG is included in the sample



* code to run on segments_all.do in /Users/amir/Data
* download data from Compustat Historical Segments on WRDS


use "/Users/amir/Data/segments.dta",replace
* keep the earliest reporting for the data point, 
* This is supposed to be the most consistent, given that companies may change segment reporting over time
keep if srcdate==datadate
*(1,068,340 observationis deleted)

*keep gvkey datadate stype sales SICS1 SICS2 emps nis ops geotp snms soptp1 soptp2 conm tic sic 


* remaining segment observations
* count
* 1,226,888


* we excludes the geographical scope of the company
* dropping geographic segment records
*keep if stype=="BUSSEG"| stype=="OPSEG" | stype=="GEOSEG" 
* (634,569 observations deleted) (no GEOSEG)
* (1,643 observations deleted) (when including GEOSEG)

sort gvkey datadate

keep if sales>0
*(61,790 observations deleted)
*(182,504 observations deleted)/ GEOSEG


drop if missing(sales)
*(2,949 observations deleted)
// (34,764 observations deleted)

// . tab soptp1 stype 
//
//  Operating |
//    Segment |                Segment Type
//     Type 1 |    BUSSEG     GEOSEG      OPSEG      STSEG |     Total
// -----------+--------------------------------------------+----------
//        DIV |     3,780         29        336          0 |     4,145 
//        GEO |        49    173,601      6,635      1,257 |   181,542 
//     MARKET |       129     88,601        150          5 |    88,885 
//       OPER |        22         19     19,709         93 |    19,843 
//    PD_SRVC |   228,977        439     14,215         86 |   243,717 
// -----------+--------------------------------------------+----------
//      Total |   232,957    262,689     41,045      1,441 |   538,132 


* based on the table above and inspection of data, 
* we partition the data into goeographical segments and business segments 

gen ind_GEO = 1 if stype == "GEOSEG" | stype=="STSEG"
replace ind_GEO =1 if soptp1 == "GEO"
replace ind_GEO =0 if missing(ind_GEO)

* if ind_GEO and missing(geotp): most likely misc corporate expenses
* drop, as it is negligible and due to data entry inaccuracies

drop if missing(geotp) & ind_GEO==1
*(724 observations deleted)

* similarly if ind_GEO ==0 and SIC code is missing 
* most likely scenario is:
* corporate; other; unallocated; 
* in total it accounts for 2 percent of ind_GEO ==0 
* we drop these as they are neglibile and not possible to be classified.
drop if missing(SICS1) & ind_GEO ==0
*(12,585 observations deleted)

* at this point every ind_GEO==0 has SIC code
* and, every ind_GEO ==1 has geotp code (i.e., domestics vs non-domestic)


////////////////////////////////////////////////////
//////////// SALES by IND_GEO ///////////////////
////////////////////////////////////////////////////
gen year =year(datadate)
keep if year>2010

egen sales_BUS =total(sales)  if ind_GEO==0, by(gvkey year SICS1)
la var sales_BUS "Total annual Sales per SICS1"


egen sales_GEO =total(sales)  if ind_GEO==1, by(gvkey year geotp)
la var sales_GEO "Total annual Sales by DOMESTIC OR FOREIGN"



keep gvkey year ind_GEO geotp SICS1 conm tic snms sales_BUS sales_GEO 
duplicates drop gvkey year ind_GEO geotp SICS1 sales_BUS sales_GEO, force 


format conm %-20s 
format snms %-20s 

sort gvkey year ind_GEO 

egen tot_sales_BUS =total(sales_BUS), by(gvkey year)
la var tot_sales_BUS "Total annual Sales Bus side"


egen tot_sales_GEO =total(sales_GEO), by(gvkey year)
la var tot_sales_GEO "Total annual Sales GEO side"


////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////// seg sales to total sales ratio //////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////


gen ratio_sales_BUS =sales_BUS/tot_sales_BUS
la var ratio_sales_BUS "Ratio of Industry Segment Sales per Total Sales"


gen ratio_sales_GEO =sales_GEO/tot_sales_GEO
la var ratio_sales_GEO "Ratio of Geographic Segment Sales per Total Sales"












////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
//////////// /////        HHI        ///////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

egen HHI_BUS = total(ratio_sales_BUS^2), by(gvkey year)
la var HHI_BUS "Industry Herfindahl–Hirschman Index"


egen HHI_GEO = total(ratio_sales_GEO^2), by(gvkey year)
la var HHI_GEO "Geographic Herfindahl–Hirschman Index"

replace HHI_BUS =1 if HHI_BUS ==0 
replace HHI_GEO =1 if HHI_GEO ==0




* Average HHI
gen HHI = (HHI_BUS + HHI_GEO)/2







keep gvkey year conm tic HHI_BUS HHI_GEO HHI 
duplicates drop gvkey year HHI, force


isid gvkey year


merge 1:1 tic year using "/Users/amir/Data/SP_historical.dta", keepusing(conm SP500)

// keep if SP500 ==1 
// keep if _merge ==3
drop if _merge==2 
drop _merge

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
//////////////// END ///////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////





///////////////////////////////////////

*drop missing SIC observations
*drop if missing(SICS1) & stype != "GEOSEG"
*(12,609 observations deleted)
// (12,609 observations deleted)



*four digit sale per segment
*egen segsale =total(sales), by(gvkey datadate SICS1)



//
//
// * going with the 4 digit SIC code for BUSSEG for now 
// gen SICS3d = substr(SICS1,1,3)
// la var SICS2d "2 Digit SIC Code"
//
//
//
//
// duplicates drop gvkey year geotp segsalegeo segsale2d SICS2d conm tic,force
// *(117,385 observations deleted)
// *three digit sic version : (84,052 observations deleted)
//
//
// * total sale is defined at the total sales for each firm  per 2 digit SIC per year
// egen totsaleseg =total(segsale2d) if !missing(segsale2d), by(gvkey year)
// la var totsaleseg "Total Sales per year SIC SEG "
//
// * total sales for GEOgraphic 
// egen totsalegeo =total(segsalegeo) if !missing(segsalegeo), by(gvkey year)
// la var totsalegeo "Total Sales per year GEO SEG "
//
//
//
// format conm %-20s 
// format snms %-20s 
//
//
//
// sort gvkey year geotp
//
//
// gen segsaleratio =segsale2d/totsaleseg if !missing(totsaleseg) 
// la var segsaleratio "Ratio of Segment Sales per Total Sales"
// replace segsaleratio =segsalegeo/totsalegeo if !missing(totsalegeo)  
//
// *HHI would be the same for all observations of segments in a year 
// egen HHIind = total(segsaleratio^2), by(gvkey year)
// la var HHI "Herfindahl–Hirschman Index Industry"
//
// *HHI would be the same for all observations of segments in a year 
// egen HHI = total(segsaleratio^2), by(gvkey year)
// la var HHI "Herfindahl–Hirschman Index"
//
// format conm %-20s 
// format snms %-20s 
//
//
//
// keep gvkey HHI tic year  conm
// duplicates drop
//
// bysort gvkey year: gen nseg =_N
// la var nseg "Number of Segments"
//
//
// bysort gvkey year: gen fyid =_n
// la var fyid "firm-year id"
//
// drop if year==2020
// *(545 observations deleted)
//
//
// destring SICS2d, replace


/* commented temmp to check for 3d sic
merge m:1 SICS2d using "/Users/amir/github/ceo/Misc Data/SIC2d.dta"

**AFTER MERGE* 
keep if _merge ==3
*(30,399 observations deleted)

drop _merge
rename description SICdesc
*/


* Latest save: February 17, 2023
save "/Users/amir/Data/segments_tomerge", replace


	


* Employee and assets and other data on COMPUSTAT ANNUALS

* PREPARING SP file 500
***** NEED TO RUN IT ONLY ONCE TO COMPILE THE RAW SP500 FILE

// import delimited "/Users/amir/Data/SP_Hist.csv", varnames(1) clear 
// drop v1
// gen date2= date(date,"YMD")
// format date2 %td
//
// keep if month(date2)==12
// drop date 
// gen year = year(date2)
// drop date2
// rename name conm
// rename ticker tic
// duplicates drop tic year, force
// replace conm= upper(conm)
// gen SP500=1
// save "/Users/amir/Data/SP_historical", replace




*changing the names of CRSP-Compustat variables to be consistent with execucomp
use "/Users/amir/Data/fundamentals.dta",replace

rename fyear year
rename GVKEY gvkey 


/*
drop if missing(csho) 		//look into this later. many are listed multiple times/ check Berkshire Hathaway
* (1,660 observations deleted)
drop if missing(prcc_f)
*(1,660 observations deleted)
drop if missing(at)
*(19,178 observations deleted)
*/


*Gabaix and Landier (2008)
replace txdb = 0 if txdb >= .  //GL(2008)
*(21,451 real changes made)
replace ceq = 0 if ceq >= .	//GL(2008)
*(203 real changes made)



// isid gvkey year 
*linear interpolation for employee values missing in a sequence

bys gvkey (year):ipolate emp year , gen(emp1)

rename emp empdrop
rename emp1 emp
drop empdrop


* Size or scale measure are calculated using the firm's last year observed 
bysort gvkey (year): gen size1 = (csho[_n-1]*prcc_f[_n-1] +at[_n-1] - ceq[_n-1]- txdb[_n-1])
bysort gvkey (year): gen size2 = (oibdp[_n-1] - dp[_n-1])
bysort gvkey (year): gen size3 = sale[_n-1]
bysort gvkey (year): gen size4 = csho[_n-1]*prcc_f[_n-1]
bysort gvkey (year): gen size5 = emp[_n-1]


la var size1 "Size Market Cap + Assets and Taxes"
la var size2 "Size Operating Income Net Depreciation"
la var size3 "Size Sales"
la var size4 "Size Market Cap"
la var size5 "Size Employees"

bysort gvkey (year): gen outcome1 = (csho*prcc_f +at - ceq- txdb)
bysort gvkey (year): gen outcome2 = (oibdp - dp)
bysort gvkey (year): gen outcome3 = sale
bysort gvkey (year): gen outcome4 = csho*prcc_f


keep gvkey year tic conm at emp ibc ni revt sale prcc_f csho tic size1 size2 size3 size4 size5 outcome1 outcome2 outcome3 outcome4 


duplicates drop


*merge m:1 tic using "/Users/amir/github/ceo/Misc Data/SP500.dta"
merge m:1 tic year  using "/Users/amir/Data/SP_historical.dta"
*merge m:1 conm year using "/Users/amir/Data/SP_historical.dta"

*save tmp_fund, replace

*matchit year conm using SP_historical.dta , idu(year) txtu(conm)
drop if _merge==2 
drop _merge



drop if year== 1975
*(3,687 observations deleted)



* need to add observation for ROCHE AG; it is reported in the segment file but not in here
set obs `=_N+1'
replace gvkey="025648" if _n==_N
replace emp=94.4 if _n==_N
replace sale =60482 if _n==_N
replace year =2018 if _n==_N
replace SP500=1 if _n==_N





save fundamentals_tomerge, replace
*gvkey year is id 

* Version 2: February 19, 2023
* Version 3 : March 6, random sample instead of S&P 500



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

// keep if salesrank<350 |SP500 ==1

keep if year ==2013 

keep if logsize5>0
keep if logtdc1>0 


replace HHI = 1- HHI
generate random = runiform()
sort random
generate insample = _n <= 500

keep gvkey logsize5 logsize1 logtdc1 HHI pGAI insample


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



