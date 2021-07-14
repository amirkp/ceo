import excel "/Users/amir/github/ceo/Misc Data/past_experience_2019.xlsx", sheet("Sheet1")  firstrow clear


drop if missing(execid)
count if !missing(O)



count if (!missing(O) & !missing(date1to)) | FinalStat=="NO" | founder==1
list coname exec_name  if !missing(O) & missing(date1to)

*returns nothing previously the following comment applied
/* in the new update all the below is fixed


	/*
     +--------------------------------------------------+
     |                    coname              exec_name |
     |--------------------------------------------------|
 28. |                 NEWS CORP      Robert J. Thomson | --fixed
 31. | LIVE NATION ENTERTAINMENT         Michael Rapino | --fixed
 34. |                MASCO CORP        Keith J. Allman | --fixed 
 36. |  EXPEDITORS INTL WASH INC      Jeffrey S. Musser | --fixed
 50. |               EQUIFAX INC          Mark W. Begor | --fixed
     |--------------------------------------------------|
 51. |   ZIONS BANCORPORATION NA   Harris Henry Simmons | --fixed 
     +--------------------------------------------------+
*/

count if !(!missing(O) | founder==1) & missing(salesifmissinggveky)
*12 observations are not founders but no gvkey in the data and no other record for them 



list coname exec_name  if !(!missing(O) | founder==1) & missing(salesifmissinggveky) & FinalStat!="NO" & FinalStat!="FIXED"
/*
     +----------------------------------------------------------------+
     |                    coname                            exec_name |
     |----------------------------------------------------------------|
  6. |      ROBERT HALF INTL INC              Harold Max Messmer, Jr. |NO
 11. |     ROYAL CARIBBEAN GROUP                      Richard D. Fain |NO
 16. |                   AON PLC                Gregory Clarence Case |NO
 22. |      HOWMET AEROSPACE INC                        John C. Plant |execid fix it 
 32. |         IRON MOUNTAIN INC   William L. Meaney, BSc, MEng, MSIA |NO
     |----------------------------------------------------------------|
 33. |                DOVER CORP                 Richard Joseph Tobin |Fixed 
 42. |      ALIGN TECHNOLOGY INC                      Joseph M. Hogan |Fixed
 45. | KEYSIGHT TECHNOLOGIES INC                  Ronald S. Nersesian |Fixed
 47. |       GILEAD SCIENCES INC                      Daniel P. O'Day |Fixed
 49. |               TRIMBLE INC                   Steven W. Berglund |NO 
     |----------------------------------------------------------------|
 56. |             CELANESE CORP                     Lori J. Ryerkerk |Fixed (Dutch Shell gvkey added)
 72. |   SBA COMMUNICATIONS CORP                    Jeffrey A. Stoops | Fixed
      +----------------------------------------------------------------+
*/


count if !(!missing(O) | founder==1) & missing(salesifmissinggveky) & FinalStat!="NO" 

*use "/Users/amir/Data/execucomp_tomerge.dta", replace


/*
These are the overcounted CEOS, I will drop them from the spreadsheet
       +--------------------------------------------------------------------------+
        |           exec_name   execid                      coname    gvkey   year |
        |--------------------------------------------------------------------------|
  3958. |    Leslie H. Wexner    00555                L BRANDS INC   006733   2019 |
 54166. |      Alan B. Miller    08337   UNIVERSAL HEALTH SVCS INC   011032   2019 |
120871. | Richard A. Gonzalez    18569                  ABBVIE INC   016101   2019 |
192763. |    Gary R. Heminger    29019     MARATHON PETROLEUM CORP   186989   2019 |
228713. | Ronald S. Nersesian    34854   KEYSIGHT TECHNOLOGIES INC   020232   2019 |
        |--------------------------------------------------------------------------|
301185. |   Lorenzo Simonelli    55154             BAKER HUGHES CO   032106   2019 |
        +--------------------------------------------------------------------------+	
		
		
Further I drop  John C Plant from the spreadsheet; the execucomp do file is edited to fix the inconsistency in execid
	
	*/

*/

**********************************************************************************
**********************************************************************************
**********************************************************************************
**********************************************************************************
**********************************************************************************

/*
There are 75 observations in the spreadsheet:
count if !missing(O) 
48 --> we have gvkey for their past position. 

count if FinalStat=="NO"
6 --> we have no past records for them

count if founder==1
21 --> foudners with no past records 

This would account for all the missing cases. 

*/
**********************************************************************************
**********************************************************************************
**********************************************************************************
**********************************************************************************
**********************************************************************************



/*

Next would be to keep 
- an indicator of the above three cases, 
- last year of work at the position 
- gvkey 

*/

gen char_stat = 0 

replace char_stat=1 if FinalStat=="NO" 
replace char_stat=2 if founder ==1

rename O past_gvkey
rename date1to past_year
replace past_year = . if FinalStat=="NO" |founder ==1
replace past_gvkey = "" if FinalStat=="NO" |founder ==1

keep gvkey execid year past_gvkey past_year char_stat

/*

. count if missing(past_gvkey) & char_stat ==0
  0
*/


save missing_ceo, replace

/*

use "/Users/amir/Data/execucomp_tomerge.dta", replace
bysort gvkey execid year (co_per_rol): gen _seq=_n
drop if _seq >1
* (10 observations deleted)
drop _seq

* isid gvkey execid year


merge 1:1 gvkey execid year using "/Users/amir/Data/missing_ceo.dta", keepusing(past_gvkey past_year char_stat)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       311,752
        from master                   311,752  (_merge==1)
        from using                          0  (_merge==2)

    matched                                75  (_merge==3)
    -----------------------------------------


*/








*/
