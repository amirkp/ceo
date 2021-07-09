* Employee and assets and other data on COMPUSTAT ANNUALS

keep gvkey fyear conm act emp tic
rename fyear year

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


