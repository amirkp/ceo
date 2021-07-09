* Employee and assets and other data on COMPUSTAT ANNUALS


*changing the names of CRSP-Compustat variables to be consistent with execucomp
rename fyear year
rename GVKEY gvkey 



drop if missing(csho) 		//look into this later. many are listed multiple times/ check Berkshire Hathaway
* (1,660 observations deleted)
drop if missing(prcc_f)
*(1,660 observations deleted)
drop if missing(at)
*(19,178 observations deleted)



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

keep gvkey year tic conm at emp ibc ni revt sale prcc_f csho tic

duplicates drop
/*Duplicates in terms of all variables

(12,448 observations deleted)*/

drop if missing(emp) 


bysort gvkey year: gen obid = _n
bysort gvkey year: gen tobid = _N

drop if obid ==1 & tobid ==2
drop obid tobid 


merge m:1 tic using "/Volumes/GoogleDrive/My Drive/Courses/coa_paper/CEO Work/Scope Diversification Literature/Data/SP500.dta"

merge m:1 gvkey year using "/Volumes/GoogleDrive/My Drive/Courses/coa_paper/CEO Work/Scope Diversification Literature/Data/fundamentals_old.dta", keepusing(at sale ceq csho dp oibdp txdb prcc_f size1 size2 size3 size4)

 drop if _merge ==2 
*(88,750 observations deleted)


