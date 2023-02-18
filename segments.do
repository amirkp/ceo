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

keep if SP500 ==1 
keep if _merge ==3
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


	



