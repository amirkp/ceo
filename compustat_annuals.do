* Employee and assets and other data on COMPUSTAT ANNUALS


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

* Size or scale measure are calculated using the firm's last year observed 
bysort gvkey (year): gen size1 = (csho[_n-1]*prcc_f[_n-1] +at[_n-1] - ceq[_n-1]- txdb[_n-1])
bysort gvkey (year): gen size2 = (oibdp[_n-1] - dp[_n-1])
bysort gvkey (year): gen size3 = sale[_n-1]
bysort gvkey (year): gen size4 = csho[_n-1]*prcc_f[_n-1]
bysort gvkey (year): gen size5 = emp[n-1]


bysort gvkey (year): gen outcome1 = (csho*prcc_f +at - ceq- txdb)
bysort gvkey (year): gen outcome2 = (oibdp - dp)
bysort gvkey (year): gen outcome3 = sale
bysort gvkey (year): gen outcome4 = csho*prcc_f


keep gvkey year tic conm at emp ibc ni revt sale prcc_f csho tic size1 size2 size3 size4 size5 outcome1 outcome2 outcome3 outcome4 


duplicates drop


merge m:1 tic using "/Users/amir/github/ceo/Misc Data/SP500.dta"
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


*linear interpolation for employee values missing in a sequence

bys gvkey (year):ipolate emp year , gen(emp1)

rename emp empdrop
rename emp1 emp
drop empdrop



save fundamentals_tomerge, replace
*gvkey year is id 


