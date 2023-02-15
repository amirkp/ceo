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


bysort execid (year gvkey):gen n_occ=_n

*tab year if n_occ==1 & ceoann =="CEO"
* besides the initial date each year there are 28-30 CEO with 25-50 CEOs with first appearance in the data
/*
       2004 |         34        1.78       39.72
       2005 |         22        1.15       40.87
       2006 |        197       10.31       51.18
       2007 |        402       21.04       72.21
       2008 |         59        3.09       75.30
       2009 |         50        2.62       77.92

	   
There seems to be something wrong with year 2006 and 2007 where there are as many as 10 times new CEOs with no previous appearance showing up 

*/



* the goal is to figure out how many CEOs per year do have the past experience in the following sense:
* they are observed in the panel, prior to date, working at another company as a CEO or Executive 
* OR at own company as a NON CEO executive
* Then we record the date and the company

* sort by year. 
sort year 

*However, using the CEOANN variable, some ﬁrm-year observations have no CEO in Execucomp. We are however able in some cases to infer the CEO’s identity from the BECAMECEO variable indicating the date at which the individual became CEO. Speciﬁcally, when the CEOANN variable indicates no CEOs for a given ﬁrm-year, we consider an executive as the CEO of the ﬁrm in year t when (i) the BECAMECEO variable indicates that the executive was appointed as the CEO in year t or before and (ii) the dummy variable CEOANN indicates the executive as the CEO of the ﬁrm in year t + 1 or after.





* goal 1: create indicator whether the current CEO at year t, has been an executive but not CEO prior to t

* 1.1 create sequence indicator for each ceo over time 
bysort execid (year): gen ex_seq=_n

* 1.2 - create  mfirm to check whether executive shows at multiple firms, mfirm is the number of distinct companies 

* if mfirm ==1, executive has always been with one firm
* if mfirm > 2, executive has been with multiple firms, 

bysort execid (year): egen mfirm = nvals(co_per_rol) 
 
*board before ceo on own company 
gen boardbceo =0 

gen _gvkey =""
gen _year=.
gen _pastposition=""


* do not include year 1993, since many firms do not report CEO status on the first year of dataset which is 1992 

bysort execid (gvkey year):replace boardbceo=1 if (mfirm ==1 & ex_seq>1 & ceoann=="CEO" & ceoann[_n-1]!="CEO" & gvkey== gvkey[_n-1] )
bysort execid (gvkey year):replace _gvkey=gvkey[_n-1] if (mfirm ==1 & ex_seq>1 & ceoann=="CEO" & ceoann[_n-1]!="CEO" & gvkey== gvkey[_n-1] )
bysort execid (gvkey year):replace _year=year[_n-1] if (mfirm ==1 & ex_seq>1 & ceoann=="CEO" & ceoann[_n-1]!="CEO" & gvkey== gvkey[_n-1] )
bysort execid (gvkey year):replace _pastposition=ceoann[_n-1] if (mfirm ==1 & ex_seq>1 & ceoann=="CEO" & ceoann[_n-1]!="CEO" & gvkey== gvkey[_n-1] )


*use the following instead if want to account for becoming ceo the year after joining company 
*bysort execid (gvkey year):replace boardbceo=1 if (mfirm ==1 & ex_seq>1 & ceoann=="CEO" & ceoann[_n-1]!="CEO" & gvkey== gvkey[_n-1] & (year >= (year(becameceo)+1) | missing(becameceo)))

*(3647 real changes made)
*list execid exec_name coname  year boardbceo if execid=="02047"

*(1605 real changes made)

* keep the indiciator 1 if they stay CEO in subsequent years
 
bysort execid (gvkey year):replace boardbceo=1 if mfirm==1 & boardbceo[_n-1]==1 & ceoann=="CEO" & gvkey== gvkey[_n-1] 
bysort execid (gvkey year):replace _gvkey=_gvkey[_n-1] if (mfirm ==1 & !missing(_gvkey[_n-1]) & ceoann=="CEO" & gvkey== gvkey[_n-1] )
bysort execid (gvkey year):replace _year=_year[_n-1] if (mfirm ==1 & !missing(_year[_n-1]) & ceoann=="CEO"  & gvkey== gvkey[_n-1] )
bysort execid (gvkey year):replace _pastposition=_pastposition[_n-1] if (mfirm ==1 & !missing(_year[_n-1]) & ceoann=="CEO"  & gvkey== gvkey[_n-1] )



* boardbceo=1 if ceo was on the board but not ceo at current company but also other companies
bysort execid (gvkey year):replace boardbceo=2 if (mfirm >1 & ex_seq>1 & ceoann=="CEO" & ceoann[_n-1]!="CEO" & gvkey== gvkey[_n-1]) 
bysort execid (gvkey year):replace _gvkey=gvkey[_n-1] if (mfirm >1 & ex_seq>1 & ceoann=="CEO" & ceoann[_n-1]!="CEO" & gvkey== gvkey[_n-1] )
bysort execid (gvkey year):replace _year=year[_n-1] if (mfirm >1 & ex_seq>1 & ceoann=="CEO" & ceoann[_n-1]!="CEO" & gvkey== gvkey[_n-1] )
bysort execid (gvkey year):replace _pastposition=ceoann[_n-1] if (mfirm >1 & ex_seq>1 & ceoann=="CEO" & ceoann[_n-1]!="CEO" & gvkey== gvkey[_n-1] )

*(1202 real changes made)

* make the rest also equal 2 
bysort execid (gvkey year):replace boardbceo=2 if mfirm>1 & boardbceo[_n-1]==2 & ceoann=="CEO" & gvkey== gvkey[_n-1] 
bysort execid (gvkey year):replace _gvkey=_gvkey[_n-1] if (mfirm >1 & !missing(_gvkey[_n-1]) & ceoann=="CEO" & gvkey== gvkey[_n-1] )
bysort execid (gvkey year):replace _year=_year[_n-1] if (mfirm >1 & !missing(_year[_n-1]) & ceoann=="CEO"  & gvkey== gvkey[_n-1] )
bysort execid (gvkey year):replace _pastposition=_pastposition[_n-1] if (mfirm >1 & !missing(_year[_n-1]) & ceoann=="CEO"  & gvkey== gvkey[_n-1] )


*(4302 real changes made)



* goal 2: create an indicator whether the CEO shows at ANOTHER firm in any capacity prior to year t 
* we would like to know the ceostatus at another company as well, i.e. whether the CEO was a ceo or just an executive at another company
* how many ceos have been at another companies 
sort execid co_per_rol year 
gen exec_past=0
gen _gvkey_last =""
gen _year_last =. 
bysort execid (year co_per_rol): replace exec_past=1 if co_per_rol != co_per_rol[_n-1] & year>=year[_n-1]-1 
bysort execid (year co_per_rol): replace _gvkey_last=gvkey[_n-1] if co_per_rol != co_per_rol[_n-1] & year>=year[_n-1]-1 
bysort execid (year co_per_rol): replace _year_last=year[_n-1] if co_per_rol != co_per_rol[_n-1] & year>=year[_n-1]-1 
bysort execid (year co_per_rol): replace _pastposition=ceoann[_n-1] if co_per_rol != co_per_rol[_n-1] & year>=year[_n-1]-1 


bysort execid co_per_rol (year): replace exec_past=1 if exec_past[_n-1]==1 & year>=year[_n-1] 
bysort execid co_per_rol (year): replace _gvkey_last=_gvkey_last[_n-1] if !missing(_gvkey_last[_n-1]) & year>=year[_n-1]-1 
bysort execid co_per_rol (year): replace _year_last=_year_last[_n-1] if !missing(_year_last[_n-1]) & year>=year[_n-1]-1 




*distinct execid if ceoann=="CEO" & (exec_past==1 | boardbceo>0) & year == 2013






* run the missingceo .do file before continuing 


bysort gvkey execid year (co_per_rol): gen _seq=_n
drop if _seq >1
* (10 observations deleted)
drop _seq



merge 1:1 gvkey execid year using "/Users/amir/Data/missing_ceo.dta", keepusing(past_gvkey past_year char_stat)
drop _merge





save execucomp_tomerge1, replace



* isid gvkey execid year










/*

* annual_SP is the fundamental annual file
* TO DO: bring back data prep for the file in here. 
merge m:1 gvkey year using "/Users/amir/Data/annuals_SP"

drop if _merge ==2


gen joinedco =0 

bysort execid (year co_per_rol): replace joinedco=year[1]


/* jeremy's email*/
*count if SP500==1 & year==2019 & ceoann =="CEO" & !(boardbceo >0 | exec_past==1)

* export excel execid exec_name gvkey coname year using "/Volumes/GoogleDrive/My Drive/Courses/coa_paper/CEO Work/Scope Diversification Literature/Data/missing.xls" if SP500==1 & year==2019 & ceoann =="CEO" & !(boardbceo >0 | exec_past==1), firstrow(variables)


*/
