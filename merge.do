* merging all three files execucomp, fundamentals, segmentss (tomerge versions)


*Load executive compensation data 
*use "/Users/amir/Data/execucomp_tomerge.dta", replace



* we use segments file to merge ceo with segments then we should just keep one 
use "/Users/amir/Data/segments_tomerge.dta",replace

keep gvkey year HHI nseg conm
duplicates drop
*(104,261 observations deleted)

* create a variable for last year's HHI and nseg as company's characteristic
bysort gvkey (year):gen HHI_prev = HHI[_n-1]
bysort gvkey (year):gen nseg_prev = nseg[_n-1]



save segments_final, replace

use "/Users/amir/Data/fundamentals_tomerge.dta",replace

merge 1:1 gvkey year using "/Users/amir/Data/segments_final.dta"

drop _merge
*count if year==2019 & SP500==1 & _merge==1

/* These are the companies with missing records in the segments file
mostly financial firms and banks 

. list conm gvkey if year==2019 & SP500==1 & _merge==1

        +---------------------------------------+
        |                         conm    gvkey |
        |---------------------------------------|
 10244. | BANK OF NEW YORK MELLON CORP   002019 | segfile: no record
 19336. |          JPMORGAN CHASE & CO   002968 | segfile: no record
 22145. |                 COMERICA INC   003231 |
 36401. |          FIFTH THIRD BANCORP   004640 |
 36637. |       REGIONS FINANCIAL CORP   004674 |
        |---------------------------------------|
 36994. |              M & T BANK CORP   004699 |
 37207. |                   US BANCORP   004723 |
 47722. |        HUNTINGTON BANCSHARES   005786 |
 53084. |            KINDER MORGAN INC   006310 | segfile: upto 2006 
 66533. |         BANK OF AMERICA CORP   007647 | segfile: no record
        |---------------------------------------|
 70020. |          NORTHERN TRUST CORP   007982 | 
 70398. |             WELLS FARGO & CO   008007 |
 73043. | PNC FINANCIAL SVCS GROUP INC   008245 |
 88319. |                      KEYCORP   009783 |
 90843. |            STATE STREET CORP   010035 |
        |---------------------------------------|
107741. |      ZIONS BANCORPORATION NA   011687 | segfile: no record
108921. |        TRUIST FINANCIAL CORP   011856 |
127450. |          FIRST REPUBLIC BANK   014275 | segfile: no record
135050. |     PEOPLE'S UNITED FINL INC   016245 |
138858. |          SVB FINANCIAL GROUP   017120 | segfile: no record
        |---------------------------------------|
148629. | CITIZENS FINANCIAL GROUP INC   021825 |
202512. |        BOSTON PROPERTIES INC   064925 |

*/

merge 1:m gvkey year using "/Users/amir/Data/execucomp_tomerge.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       276,437
        from master                   273,962  (_merge==1)
        from using                      2,475  (_merge==2)

    matched                           309,352  (_merge==3)
    -----------------------------------------

*/

count if year ==2019 & ceoann=="CEO" & SP500==1 & !missing(HHI_prev)

count if year ==2019 & ceoann=="CEO" & SP500==1 & (missing(_gvkey) &missing(_gvkey_last )& missing(past_gvkey))


*need to create variables that point to the gvkey and year of the past experience. 
* currently there are multiple variables created in different data preparation stages for different purposes
* now we create two variables ex_gvkey, ex_year, they simply point to the gvkey and the year of the past experience. We then use these two variables to populate the scale and scope variables for CEOs from the dataset. 
*(i) _gvkey, _year, (created from serving on board before CEO variable)
*(ii) _gvkey_last, _year_last, (created from the past experience varibale potentially from the previous firms)
*(iii) past_gvkey, past_year coming from manual data collection. 
* proceed in the following order:
* populate the variables from (i) 
* if still missing, from (ii) 
* if still missing, from (iii)

gen ex_gvkey=""
gen ex_year=.

*(25,387 real changes made)


replace ex_gvkey=_gvkey
replace ex_year=_year 


replace ex_gvkey=_gvkey_last if missing(ex_gvkey)
replace ex_year=_year_last if missing(ex_year)
*(23,982 real changes made)

replace ex_gvkey=past_gvkey if missing(ex_gvkey)
replace ex_year=past_year if missing(ex_year)
*(48 real changes made)

*count if year ==2019 & ceoann=="CEO" & SP500==1 & missing(ex_year)
*27

*list ex_gvkey  ex_year  if year ==2019 & ceoann=="CEO" & SP500==1 & char_stat !=2 &char_stat !=1
drop _merge
save merged_dta, replace

keep gvkey execid year ex_gvkey ex_year
drop if missing(execid)

*isid gvkey execid year


*changing the name of gvkey and year, so we can merge using ex_gvkey ex_year 
rename gvkey gvkey_tmp
rename year year_tmp 


rename ex_gvkey gvkey
rename ex_year year

merge m:1 gvkey year using "/Users/amir/Data/fundamentals_tomerge.dta", keepusing(sale emp)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       502,695
        from master                   265,282  (_merge==1
> )
        from using                    237,413  (_merge==2
> )

    matched                            46,545  (_merge==3
> )
    -----------------------------------------

*/

drop if _merge==2

drop _merge 
rename gvkey ex_gvkey
rename year ex_year


rename gvkey_tmp gvkey
rename year_tmp year

rename emp ex_emp_ceo
rename sale ex_sale_ceo

keep gvkey year execid ex_sale_ceo ex_emp_ceo 
merge 1:1 gvkey execid year using "/Users/amir/Data/merged_dta.dta"

*list conm exec_name ex_gvkey ex_year char_stat if  year ==2019 & ceoann=="CEO" & SP500==1 & (missing(ex_sale_ceo)|missing(emp)) &char_stat ==0
/* check these guys
        +---------------------------------------------------------------------------------+
        |                     conm              exec_name   ex_gvkey   ex_year   char_s~t |
        |---------------------------------------------------------------------------------|
 31559. |        DXC TECHNOLOGY CO     Michael J. Salvino     014357      2016          0 |Fixed the number

 39849. |               DOVER CORP   Richard Joseph Tobin     063914      2018          0 |CNH Global was under a different name in 2018 (changed name) fixed in the file. 
 62121. |    HUNTINGTON BANCSHARES    Stephen D. Steinour     021825      2008          0 |was private in 2008, I will set the year to the first year available 
178073. |                NEWS CORP      Robert J. Thomson     018043      2012          0 |dropped, no records
200190. |      GILEAD SCIENCES INC        Daniel P. O'Day     025648      2018          0 |Roche not in fun
        |---------------------------------------------------------------------------------|
222832. |     REGENCY CENTERS CORP   Martin E. Stein, Jr.     029099      1993          0 |
230412. |       INGERSOLL RAND INC         Vicente Reynal     030098      2016          0 |Ingersol
267456. | COGNIZANT TECH SOLUTIONS        Brian Humphries     026156      2012          0 |HP
273604. |  SBA COMMUNICATIONS CORP      Jeffrey A. Stoops       5188      2002          0 |
        +---------------------------------------------------------------------------------+
*/ 



* The above CEOs are fixed. 

*Now we have the following coming from the data itself, but we do not have past history for them in the fundamentals file: 
/*
        +-----------------------------------------------------------------------------------------------------------------------+
        |                         conm                          exec_name   ex_gvkey   ex_year   char_s~t   ex_sal~o   ex_emp~o |
        |-----------------------------------------------------------------------------------------------------------------------|
 10511. |          AVERY DENNISON CORP                 Mitchell R. Butier     001913      2015          .     5966.9          . |
 74723. |                 L BRANDS INC                   Leslie H. Wexner     063643      1995          .          .          . |
 85773. |                  VIATRIS INC                     Heather Bresch     007637      2011          .   6129.825          . |
156439. |             DUKE REALTY CORP                    James B. Connor     013510      2015          .    950.795          . |
158635. |                   ZOETIS INC                    Juan Ramn Alaix     013721      2011          .          .          . |
        |-----------------------------------------------------------------------------------------------------------------------|
185486. | CITIZENS FINANCIAL GROUP INC            Bruce Winfield Van Saun     021825      2013          .          .          . |
211793. |                 FORTIVE CORP                      James A. Lico     026590      2014          .          .          . |
237715. |              BAKER HUGHES CO                  Lorenzo Simonelli     001976      2017          .          .          . |
238049. |                  CORTEVA INC              James C. Collins, Jr.     035168      2018          .          .          . |
265324. |                    AMCOR PLC   Ronald Stephen Delia, B.Sc., MBA     100243      2015          .          .          . |
        |-----------------------------------------------------------------------------------------------------------------------|
278304. |    EDWARDS LIFESCIENCES CORP               Michael A. Mussallem     133366      1999          .          .          . |
291740. |     MARKETAXESS HOLDINGS INC             Richard Mitchell McVey     002968      2000          0      58934          . |
296761. |     AMERIPRISE FINANCIAL INC                James M. Cracchiolo     164708      2004          .          .          . |
305425. |      ACTIVISION BLIZZARD INC                   Robert A. Kotick     001111      2008          .          .          . |
        +-----------------------------------------------------------------------------------------------------------------------+

*/

