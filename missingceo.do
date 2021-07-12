 import excel "/Users/amir/github/ceo/Misc Data/past_experience_2019.xlsx", sheet("Sheet1")  firstrow clear


drop if missing(execid)
count if !missing(O)

list coname exec_name  if !missing(O) & missing(date1to)


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
 33. |                DOVER CORP                 Richard Joseph Tobin |
 42. |      ALIGN TECHNOLOGY INC                      Joseph M. Hogan |
 45. | KEYSIGHT TECHNOLOGIES INC                  Ronald S. Nersesian |
 47. |       GILEAD SCIENCES INC                      Daniel P. O'Day |
 49. |               TRIMBLE INC                   Steven W. Berglund |
     |----------------------------------------------------------------|
 56. |             CELANESE CORP                     Lori J. Ryerkerk |
 72. |   SBA COMMUNICATIONS CORP                    Jeffrey A. Stoops |
     +----------------------------------------------------------------+
*/

list coname exec_name  if !(!missing(O) | founder==1) & missing(salesifmissinggveky)
