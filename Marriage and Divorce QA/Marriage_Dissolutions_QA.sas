
/*Annual Marriage & Divorce Numbers CO Total*/

%let year=2022;
libname mdware odbc dsn=mdwarehouse schema=dbo;

data marriage;
set mdware.tblmarriagedata;
where ceremonyyear=&year AND RecordType ne "C" AND (voidind in (.,0));
run;

data divdf;
set mdware.tblDissolutiondata;
where Decreeyear = &year AND void in (.,0);
run;

proc freq data=marriage; 
table ceremonymonth / missing nocol norow nopercent;
run;

proc freq data=divdf; 
table decreemonth / missing nocol norow nopercent;
run;
