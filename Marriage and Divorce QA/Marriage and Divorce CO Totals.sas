
/*Annual Marriage & Divorce Numbers CO Total*/

%let year=2023;
libname mdware odbc dsn=mdwarehouse schema=dbo;

data marriage;
set mdware.tblmarriagedata;
where ceremonyyear=&year AND RecordType ne "C" AND (voidind in (.,0));
run;

data divdf;
set mdware.tblDissolutiondata;
where Decreeyear = &year AND void in (.,0);
run;
title;

Proc format;
   VALUE CeremonyMonthf  1 = "Jan"
                      2 = "Feb"
         		      3 = "Mar"
	                  4 = "Apr"
		              5 = "May"
		              6 = "Jun"
		              7 = "Jul"
		              8 = "Aug"
		              9 = "Sep"
		              10 = "Oct"
		              11 = "Nov"
	                  12 = "Dec";
run;

Options NOCENTER nobyline orientation=portrait papersize=letter topmargin=0.5 in;
ODS LISTING CLOSE;

ODS PDF File="C:\Users\vakohl\Documents\TestDev SAS\Reports\Marriage & Divorce Summary.pdf" style=minimal notoc;

proc freq data = marriage;
  Format CeremonyMonth CeremonyMonthf.;
table Ceremonymonth / missing norow nocol nopercent;
   Title "Marriage Counts by Month For &year";
run;

proc freq data = divdf;
  Format decreemonth CeremonyMonthf.;
table decreemonth / missing norow nocol nopercent;
   Title "Dissolution Counts by Month For &year";
run;

ods pdf close;
ODS listing;
run;
