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





