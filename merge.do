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

keep gvkey year HHI conm
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

/*
        +---------------------------------------------------------------------------------+
        | execid                 exec_name    gvkey   year                    ex_conm_ceo |
        |---------------------------------------------------------------------------------|
264840. |  20948         Charles W. Scharf   002019   2017   BANK OF NEW YORK MELLON CORP |
266999. |  43625    Richard Mitchell McVey   002968   2000            JPMORGAN CHASE & CO |
267002. |  03766               James Dimon   002968   2005            JPMORGAN CHASE & CO |
267865. |  36815     Curtis Chatman Farmer   003231   2018                   COMERICA INC |
270864. |  33048       Donald C. Wood, CPA   004605   2003   FEDERAL REALTY INVESTMENT TR |
        |---------------------------------------------------------------------------------|
270998. |  27451     Gregory D. Carmichael   004640   2015            FIFTH THIRD BANCORP |
271060. |  35764       John M. Turner, Jr.   004674   2018         REGIONS FINANCIAL CORP |
271205. |  30821         Ren F. Jones, CPA   004699   2017                M & T BANK CORP |
271244. |  21046             Andrew Cecere   004723   2016                     US BANCORP |
274987. |  29522            Steven J. Kean   006310   2014              KINDER MORGAN INC |
        |---------------------------------------------------------------------------------|
278046. |  25970     Brian Thomas Moynihan   007647   2009           BANK OF AMERICA CORP |
279015. |  42590         Michael G. OGrady   007982   2017            NORTHERN TRUST CORP |
279660. |  24423        William S. Demchak   008245   2012   PNC FINANCIAL SVCS GROUP INC |
283243. |  23128            Beth E. Mooney   009783   2010                        KEYCORP |
283704. |  23041     Ronald Philip OHanley   010035   2018              STATE STREET CORP |
        |---------------------------------------------------------------------------------|
287589. |  07587      Harris Henry Simmons   011687   1986        ZIONS BANCORPORATION NA |
287739. |  10662         Kelly Stuart King   011856   2008          TRUIST FINANCIAL CORP |
292717. |  21673            John P. Barnes   016245   2010       PEOPLE'S UNITED FINL INC |
293316. |  26254         Gregory W. Becker   017120   2010            SVB FINANCIAL GROUP |
294489. |  36912       Stephen D. Steinour   021825   2014   CITIZENS FINANCIAL GROUP INC |
        |---------------------------------------------------------------------------------|
294490. |  14582   Bruce Winfield Van Saun   021825   2014   CITIZENS FINANCIAL GROUP INC |
301019. |  26553    Michael J. Schall, CPA   030293   2010           ESSEX PROPERTY TRUST |
304749. |  37577        Strauss H. Zelnick   064630   2010     TAKE-TWO INTERACTIVE SFTWR |
        +---------------------------------------------------------------------------------+
*/
merge 1:m gvkey year using "/Users/amir/Data/execucomp_tomerge.dta"
keep if _merge==3 
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       276,437
        from master                   273,962  (_merge==1)
        from using                      2,475  (_merge==2)

    matched                           309,352  (_merge==3)
    -----------------------------------------

*/

*count if year ==2019 & ceoann=="CEO" & SP500==1 & !missing(HHI_prev)

*count if year ==2019 & ceoann=="CEO" & SP500==1 & (missing(_gvkey) &missing(_gvkey_last )& missing(past_gvkey))


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



/*


       +-----------------------------------------------------------------------------------------------------------------------+
        |                         conm                          exec_name   ex_gvkey   ex_year   char_s~t   ex_sal~o   ex_emp~o |
        |-----------------------------------------------------------------------------------------------------------------------|
 74723. |                 L BRANDS INC                   Leslie H. Wexner     063643      1995          .          .          . | change to 1996
158635. |                   ZOETIS INC                    Juan Ramn Alaix     013721      2011          .          .          . | change to 2013 
185486. | CITIZENS FINANCIAL GROUP INC            Bruce Winfield Van Saun     021825      2013          .          .          . | change to 2014 
211793. |                 FORTIVE CORP                      James A. Lico     026590      2014          .          .          . | chnage to 2016 
237715. |              BAKER HUGHES CO                  Lorenzo Simonelli     001976      2017          .          .          . | change to GE in 2017
        |-----------------------------------------------------------------------------------------------------------------------|
238049. |                  CORTEVA INC              James C. Collins, Jr.     035168      2018          .          .          . |change ex_gvkey to 004060 (dupont) and year =2016 (Bloomberg)
265324. |                    AMCOR PLC   Ronald Stephen Delia, B.Sc., MBA     100243      2015          .          .          . |change ex_year to 2006
278304. |    EDWARDS LIFESCIENCES CORP               Michael A. Mussallem     133366      1999          .          .          . | change ex_gvkey to 002086, change year to 1999
296761. |     AMERIPRISE FINANCIAL INC                James M. Cracchiolo     164708      2004          .          .          . |change gvkey to 001447, year to 2005
305425. |      ACTIVISION BLIZZARD INC                   Robert A. Kotick     001111      2008          .          .          . | Cchange year to 2007 
        +-----------------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------------------------+
        |                         conm   co_per~l                          exec_name   ex_gvkey   ex_year   char_s~t   ex_sal~o   ex_emp~o |
        |----------------------------------------------------------------------------------------------------------------------------------|
 74723. |                 L BRANDS INC       1329                   Leslie H. Wexner     063643      1995          .          .          . |
158635. |                   ZOETIS INC      47879                    Juan Ramn Alaix     013721      2011          .          .          . |
185486. | CITIZENS FINANCIAL GROUP INC      52186            Bruce Winfield Van Saun     021825      2013          .          .          . |change to 2014
211793. |                 FORTIVE CORP      53683                      James A. Lico     026590      2014          .          .          . |chnage to 2016 
237715. |              BAKER HUGHES CO      60148                  Lorenzo Simonelli     001976      2017          .          .          . |change to GE in 2017
        |----------------------------------------------------------------------------------------------------------------------------------|
238049. |                  CORTEVA INC      63410              James C. Collins, Jr.     035168      2018          .          .          . |change ex_gvkey to 004060 (dupont) and year =2016 (Bloomberg)
265324. |                    AMCOR PLC      62690   Ronald Stephen Delia, B.Sc., MBA     100243      2015          .          .          . |change ex_year to 2006
278304. |    EDWARDS LIFESCIENCES CORP      21690               Michael A. Mussallem     133366      1999          .          .          . |change ex_gvkey to 002086, change year to 1999
296761. |     AMERIPRISE FINANCIAL INC      35939                James M. Cracchiolo     164708      2004          .          .          . |change gvkey to 001447, year to 2005
305425. |      ACTIVISION BLIZZARD INC      51675                   Robert A. Kotick     001111      2008          .          .          . |change year to 2007 
        +----------------------------------------------------------------------------------------------------------------------------------+

*/

replace ex_year=1996 if co_per_rol==1329 & year==2019

replace ex_year=2013 if co_per_rol==47879 & year==2019

replace ex_year=2014 if co_per_rol==52186 & year==2019

replace ex_year=2016 if co_per_rol==53683 & year==2019

replace ex_gvkey="005047" if co_per_rol==60148 & year==2019
replace ex_year=2017 if co_per_rol==60148 & year==2019

replace ex_gvkey="004060" if co_per_rol==63410 & year==2019
replace ex_year=2019 if co_per_rol==63410 & year==2019

replace ex_year=2006 if co_per_rol==62690 & year==2019

replace ex_gvkey="002086" if co_per_rol==21690 & year==2019
replace ex_year=1999 if co_per_rol==21690 & year==2019

replace ex_gvkey="001447" if co_per_rol==35939 & year==2019
replace ex_year=2005 if co_per_rol==35939 & year==2019

replace ex_year=2007 if co_per_rol==51675 & year==2019



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

merge m:1 gvkey year using "/Users/amir/Data/fundamentals_tomerge.dta", keepusing(conm sale emp)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       525,432
        from master                   265,226  (_merge==1)
        from using                    260,206  (_merge==2)

    matched                            46,601  (_merge==3)
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
rename conm ex_conm_ceo
keep gvkey year execid ex_sale_ceo ex_emp_ceo  ex_conm_ceo
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
list conm exec_name ex_gvkey ex_year char_stat ex_sale_ceo ex_emp_ceo if  year ==2019 & ceoann=="CEO" & SP500==1 & (missing(ex_sale_ceo) | missing(ex_emp)) & !inlist(char_stat, 1,2)
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

		
		
		
		updated list after fixing missing employee: 
		. list conm exec_name ex_gvkey ex_year char_stat ex_sale_ceo ex_emp_ceo if  year ==2019 & ceoann=="CEO" & SP500==1 & (missing(ex_sale_ceo) | missing(ex_emp)) & !inlist(char_stat, 1,2)

        +-----------------------------------------------------------------------------------------------------------------------+
        |                         conm                          exec_name   ex_gvkey   ex_year   char_s~t   ex_sal~o   ex_emp~o |
        |-----------------------------------------------------------------------------------------------------------------------|
 74723. |                 L BRANDS INC                   Leslie H. Wexner     063643      1995          .          .          . | change to 1996
158635. |                   ZOETIS INC                    Juan Ramn Alaix     013721      2011          .          .          . | change to 2013 
185486. | CITIZENS FINANCIAL GROUP INC            Bruce Winfield Van Saun     021825      2013          .          .          . | change to 2014 
211793. |                 FORTIVE CORP                      James A. Lico     026590      2014          .          .          . | chnage to 2016 
237715. |              BAKER HUGHES CO                  Lorenzo Simonelli     001976      2017          .          .          . | change to GE in 2017
        |-----------------------------------------------------------------------------------------------------------------------|
238049. |                  CORTEVA INC              James C. Collins, Jr.     035168      2018          .          .          . |change ex_gvkey to 004060 (dupont) and year =2016 (Bloomberg)
265324. |                    AMCOR PLC   Ronald Stephen Delia, B.Sc., MBA     100243      2015          .          .          . |change ex_year to 2006
278304. |    EDWARDS LIFESCIENCES CORP               Michael A. Mussallem     133366      1999          .          .          . | change ex_gvkey to 002086, change year to 1999
296761. |     AMERIPRISE FINANCIAL INC                James M. Cracchiolo     164708      2004          .          .          . |change gvkey to 001447, year to 2005
305425. |      ACTIVISION BLIZZARD INC                   Robert A. Kotick     001111      2008          .          .          . | Cchange year to 2007 
        +-----------------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------------------------+
        |                         conm   co_per~l                          exec_name   ex_gvkey   ex_year   char_s~t   ex_sal~o   ex_emp~o |
        |----------------------------------------------------------------------------------------------------------------------------------|
 74723. |                 L BRANDS INC       1329                   Leslie H. Wexner     063643      1995          .          .          . |
158635. |                   ZOETIS INC      47879                    Juan Ramn Alaix     013721      2011          .          .          . |
185486. | CITIZENS FINANCIAL GROUP INC      52186            Bruce Winfield Van Saun     021825      2013          .          .          . |
211793. |                 FORTIVE CORP      53683                      James A. Lico     026590      2014          .          .          . |
237715. |              BAKER HUGHES CO      60148                  Lorenzo Simonelli     001976      2017          .          .          . |
        |----------------------------------------------------------------------------------------------------------------------------------|
238049. |                  CORTEVA INC      63410              James C. Collins, Jr.     035168      2018          .          .          . |
265324. |                    AMCOR PLC      62690   Ronald Stephen Delia, B.Sc., MBA     100243      2015          .          .          . |
278304. |    EDWARDS LIFESCIENCES CORP      21690               Michael A. Mussallem     133366      1999          .          .          . |
296761. |     AMERIPRISE FINANCIAL INC      35939                James M. Cracchiolo     164708      2004          .          .          . |
305425. |      ACTIVISION BLIZZARD INC      51675                   Robert A. Kotick     001111      2008          .          .          . |
        +----------------------------------------------------------------------------------------------------------------------------------+

*new update: after making changes: 

. count if  year ==2019 & ceoann=="CEO" & SP500==1 & (missing(ex_sale_ceo) | missing(ex_emp)) & !inlist(char_stat, 1,2)
  0


*/
drop _merge
save merged_dta, replace


*merging again with segment file this time for ceo type 
keep gvkey execid exec_name year ex_gvkey ex_year ceoann SP500 char_stat ex_conm_ceo

drop if missing(execid)

*isid gvkey execid year


*changing the name of gvkey and year, so we can merge using ex_gvkey ex_year 
rename gvkey gvkey_tmp
rename year year_tmp 


rename ex_gvkey gvkey
rename ex_year year

merge m:1 gvkey year using "/Users/amir/Data/segments_final.dta", keepusing(HHI nseg)
/*


    Result                           # of obs.
    -----------------------------------------
    not matched                       550,135
        from master                   265,915  (_merge==1)
        from using                    284,220  (_merge==2)

    matched                            45,912  (_merge==3)
    -----------------------------------------

. 



these are execs with missing segment datta for the firm where they worked at last

list execid exec_name gvkey year if year_tmp ==2019 & SP500==1 & ceoann =="CEO" & !inlist(char_stat, 1,2) & _merge!=3

        +--------------------------------------------------+
        | execid                 exec_name    gvkey   year |
        |--------------------------------------------------|
264840. |  20948         Charles W. Scharf   002019   2017 |
266999. |  43625    Richard Mitchell McVey   002968   2000 |
267007. |  03766               James Dimon   002968   2005 |
267865. |  36815     Curtis Chatman Farmer   003231   2018 |
270864. |  33048       Donald C. Wood, CPA   004605   2003 |
        |--------------------------------------------------|
270998. |  27451     Gregory D. Carmichael   004640   2015 |
271060. |  35764       John M. Turner, Jr.   004674   2018 |
271205. |  30821         Ren F. Jones, CPA   004699   2017 |
271245. |  21046             Andrew Cecere   004723   2016 |
274990. |  29522            Steven J. Kean   006310   2014 |
        |--------------------------------------------------|
278051. |  25970     Brian Thomas Moynihan   007647   2009 |
279016. |  42590         Michael G. OGrady   007982   2017 |
279659. |  24423        William S. Demchak   008245   2012 |
283241. |  23128            Beth E. Mooney   009783   2010 |
283704. |  23041     Ronald Philip OHanley   010035   2018 |
        |--------------------------------------------------|
287589. |  07587      Harris Henry Simmons   011687   1986 |
287736. |  10662         Kelly Stuart King   011856   2008 |
292710. |  21673            John P. Barnes   016245   2010 |
293313. |  26254         Gregory W. Becker   017120   2010 |
294489. |  14582   Bruce Winfield Van Saun   021825   2014 |
        |--------------------------------------------------|
294490. |  36912       Stephen D. Steinour   021825   2014 |
301018. |  26553    Michael J. Schall, CPA   030293   2010 |
304750. |  37577        Strauss H. Zelnick   064630   2010 |
        +--------------------------------------------------+

*/
*list execid exec_name gvkey year ex_conm_ceo if year_tmp ==2019 & SP500==1 & ceoann =="CEO" & !inlist(char_stat, 1,2) & _merge!=3


/*
        +---------------------------------------------------------------------------------+
        | execid                 exec_name    gvkey   year                    ex_conm_ceo |
        |---------------------------------------------------------------------------------|
264840. |  20948         Charles W. Scharf   002019   2017   BANK OF NEW YORK MELLON CORP |
266999. |  43625    Richard Mitchell McVey   002968   2000            JPMORGAN CHASE & CO |
267002. |  03766               James Dimon   002968   2005            JPMORGAN CHASE & CO |
267865. |  36815     Curtis Chatman Farmer   003231   2018                   COMERICA INC |
270864. |  33048       Donald C. Wood, CPA   004605   2003   FEDERAL REALTY INVESTMENT TR |
        |---------------------------------------------------------------------------------|
270998. |  27451     Gregory D. Carmichael   004640   2015            FIFTH THIRD BANCORP |
271060. |  35764       John M. Turner, Jr.   004674   2018         REGIONS FINANCIAL CORP |
271205. |  30821         Ren F. Jones, CPA   004699   2017                M & T BANK CORP |
271244. |  21046             Andrew Cecere   004723   2016                     US BANCORP |
274987. |  29522            Steven J. Kean   006310   2014              KINDER MORGAN INC |
        |---------------------------------------------------------------------------------|
278046. |  25970     Brian Thomas Moynihan   007647   2009           BANK OF AMERICA CORP |
279015. |  42590         Michael G. OGrady   007982   2017            NORTHERN TRUST CORP |
279660. |  24423        William S. Demchak   008245   2012   PNC FINANCIAL SVCS GROUP INC |
283243. |  23128            Beth E. Mooney   009783   2010                        KEYCORP |
283704. |  23041     Ronald Philip OHanley   010035   2018              STATE STREET CORP |
        |---------------------------------------------------------------------------------|
287589. |  07587      Harris Henry Simmons   011687   1986        ZIONS BANCORPORATION NA |
287739. |  10662         Kelly Stuart King   011856   2008          TRUIST FINANCIAL CORP |
292717. |  21673            John P. Barnes   016245   2010       PEOPLE'S UNITED FINL INC |
293316. |  26254         Gregory W. Becker   017120   2010            SVB FINANCIAL GROUP |
294489. |  36912       Stephen D. Steinour   021825   2014   CITIZENS FINANCIAL GROUP INC |
        |---------------------------------------------------------------------------------|
294490. |  14582   Bruce Winfield Van Saun   021825   2014   CITIZENS FINANCIAL GROUP INC |
301019. |  26553    Michael J. Schall, CPA   030293   2010           ESSEX PROPERTY TRUST |
304749. |  37577        Strauss H. Zelnick   064630   2010     TAKE-TWO INTERACTIVE SFTWR |
        +---------------------------------------------------------------------------------+
		
	These are just not reported in the data
*/

*merge m:1 gvkey year using "/Users/amir/Data/segments_final.dta", keepusing(HHI nseg)





rename HHI ex_HHI_ceo
rename nseg ex_nseg_ceo
drop if _merge==2 

rename gvkey ex_gvkey
rename year ex_year
rename gvkey_tmp gvkey 
rename year_tmp year 

keep gvkey year execid ex_HHI_ceo ex_nseg_ceo
merge 1:1 gvkey execid year using "/Users/amir/Data/merged_dta.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       295,071
        from master                         0  (_merge==1)
        from using                    295,071  (_merge==2)

    matched                           311,827  (_merge==3)
    -----------------------------------------
*/

*count  if  year ==2019 & ceoann=="CEO" & SP500==1 & !(missing(HHI) | missing(ex_HHI_ceo) | missing(ex_emp)| missing(emp) ) & !inlist(char_stat, 1,2)



*corr emp ex_emp_ceo if year ==2019 & ceoann=="CEO" & SP500==1 & !(missing(HHI) | missing(ex_HHI_ceo) | missing(ex_emp)| missing(emp) ) & !inlist(char_stat, 1,2)

*list exec_name conm ex_conm_ceo ex_year if  year ==2019 & ceoann=="CEO" & SP500==1 & !(missing(HHI) | missing(ex_HHI_ceo) | missing(ex_emp)| missing(emp) ) & !inlist(char_stat, 1,2)



*keep if  year ==2019 & ceoann=="CEO" & SP500==1 & !(missing(HHI) | missing(ex_HHI_ceo) | missing(ex_emp)| missing(emp) ) 
drop _merge

la var ex_HHI_ceo "CEO Experience HHI" 
la var ex_nseg_ceo "CEO Experience Number of Segments"
la var ex_conm_ceo "CEO Experience Company Name"
la var ex_sale_ceo "CEO Experience Sale/Turnover (Net)"
la var ex_emp_ceo "CEO Experience Number of Employees"

la var HHI_prev "Company's Previous Year HHI"
la var nseg_prev "Company's Previous Year Number of Segments"


la var size1 "csho*prcc_f+at+ceq+txdb"
la var size2 "oibdp-dp"
la var size3 "sale"
la var size4 "csho*prcc_f"
la var size5 "emp"

la var outcome1 "csho*prcc_f+at+ceq+txdb"
la var outcome2 "oibdp-dp"
la var outcome3 "sale"
la var outcome4 "csho*prcc_f"

destring execid, replace
gen gvkey_str=gvkey

destring execid, replace
destring gvkey, replace





merge 1:1 gvkey execid year using "/Users/amir/github/ceo/Misc Data/gai1992-2016.dta", keepusing(GAI)
keep if _merge==3


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

