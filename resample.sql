/*
start with table that has format like this:
Record_All:
Cust_ID   rcd_start   rcd_end       Status
1         2020-01-01  2020-03-20    A
1         2020-03-20  2020-03-22    A 
1         2020-03-22  2020-08-09    A
1         2020-08-09  2020-12-31    T
2         2020-05-03  2020-10-22    A
2         2020-10-22  2020-12-31    T
3         2020-06-02  2020-06-12    A
3         2020-06-12  2020-06-15    T
3         2020-06-15  2020-07-18    A
3         2020-07-18  2020-12-31    T

Goal:
create a table where each customer has a single row for each month designating what their status was for that month
(could be at beginning, end of month, most amount of time for that month, I will show most amount of time for one record)

output will be:
Cust_ID   Month     Status
1         January   A
1         February  A
1         March     A
1         April     A
1         May       A
1         June      A
1         July      A
1         August    T
1         September T
1         October   T
1         November  T
1         December  T
2         May       A
2         June      A
2         July      A
2         August    A
2         September A
2         October   A
2         November  T
2         December  T
3         June      A
3         July      A
3         August    T
3         September T
3         October   T
3         November  T
3         December  T


*/

/* first, create a reference table of months with start of month and end of month as columns */

DECLARE @StartDate  date = '20200101';

 

DECLARE @CutoffDate date = getdate(); -- or '20201231'

 

;WITH seq(n) AS

(

  SELECT 0 UNION ALL SELECT n + 1 FROM seq

  WHERE n < DATEDIFF(MONTH, @StartDate, @CutoffDate) 

),

d(d) AS

(

  SELECT DATEADD(MONTH, n, @StartDate) FROM seq

),

src AS

(

  SELECT

       yyyymm               = year(d) * 100 + month(d),

       beg_dt               = convert(date, d),

       end_dt               = dateadd(month, 1, convert(date,d))

  FROM d

)

SELECT *

into #yyyymm_map

FROM src

  ORDER BY yyyymm

  OPTION (MAXRECURSION 0);


/* 
next, do a many-many join with the reference table and the temp reference table
add a where clause to limit to rows relevent to each month
(for example, if a record started on June 22 and ended on August 5, it could potentially be relevent 
in June, July, and August)
*/

select

       A.*,

       B.*,

       DATEDIFF(day, case when A.rcd_start < B.beg_dt then B.beg_dt else A.rcd_start end, case when A.rcd_end > B.end_dt then B.end_dt else A.rcd_end end) as time_elapse

into #Record_All_1

from Record_All as A, #yyyymm_map as B

where

       A.rcd_start < B.end_dt 

       and A.rcd_end >= B.beg_dt
       
/*

next, give each row a number so we know which one to keep (there will potentially be multiple records associated with each month)

*/


select *, row_number()  over(partition by cust_id, yyyymm order by time_elapse desc) as row_num,        

into #Record_All_2

from #Record_All_1

/* 
last, choose the row with the longest span of time over a month.
*/

select cust_id, yyyymm as month, status
into FINAL_TABLE
from #Record_All_2
where row_num = 1



