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
