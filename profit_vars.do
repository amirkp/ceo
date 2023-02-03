keep  gvkey year GAI emp HHI tdc1 ni 

duplicates drop


bys gvkey (year): gen ni_av = 1000*(ni[_n-1]+ni +ni[_n+1])/3
bys gvkey (year): gen tdc1_av = (tdc1[_n-1]+tdc1 +tdc1[_n+1])/3


drop if year !=2014
egen minGAI = min(GAI)
gen GAIpos = GAI - minGAI

replace tdc1_av = tdc1_av+1
replace ni_av = ni_av+1
replace emp= emp+1 








drop if missing(ni_av) | missing(tdc1_av)
drop if ni_av<0 

gen lni = log(ni_av)
gen ltdc = log(tdc1_av)
gen lprod = log(ni_av + tdc1_av)
gen lemp = log(emp)

keep GAIpos lemp HHI ltdc lni lprod
keep if !missing(HHI)

export delimited GAIpos lemp HHI ltdc lni lprod using "/Users/amir/github/NPSML-Estimator-Price-Data/Profit Estimation/data.csv", replace





