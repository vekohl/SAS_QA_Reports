*////////////////////////////////////////////////////////////////////////////

  tblmarriagedata is the main table which contains all marriage data
          Monthly Marriage Counts

/////////////////////////////////////////////////////////////////////////////
                                                   
              SUMMARY TABLE BY COUNTY AND YEAR               |
             Change ceremonyyear and Title Year              |
==============================================================

             Change ceremonyyear and Title Year              |
==============================================================;

%let filedate=%sysfunc(today(),mmddyy6.);
%let year=2023;

libname mdware odbc dsn=mdwarehouse schema=dbo;
data marriage;
set mdware.tblmarriagedata;
where ceremonyyear=&year AND RecordType ne "C" AND (voidind in (.,0));
run;

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

					  
VALUE CountyCodef 1 = "Adams" 2 = "Alamosa" 3 = "Arapahoe" 4 = "Archuleta" 5 = "Baca"
				  6 = "Bent"  7 = "Boulder"  8 = "Chaffee"  9 = "Cheyenne" 10 = "Clear Lake"
                 11 = "Conejos" 12 = "Costilla"  13 = "Crowley" 14 = "Custer" 15 = "Delta" 
                 16 = "Denver"  17 = "Dolores"  18 = "Douglas"  19 = "Eagle"  20 = "Elbert"
                 21 = "El Paso" 22 = "Fremont"  23 = "Garfield"  24 = "Gilpin" 25 = "Grand"
                 26 = "Gunnison" 27 = "Hindsdale"  28 = "Huerfano"  29 = "Jackson"  30 = "Jefferson"
                 31 = "Kiowa" 32 = "Kit Carson" 33 = "Lake" 34 = "La Plata" 35 = "Larimer"
                 36 = "Las Animas" 37 = "Lincoln" 38 = "Logan" 39 = "Mesa" 40 = "Miner"
                 41 = "Moffat" 42 = "Montezuma" 43 = "Montrose" 44 = "Morgan" 45 = "Otero"
                 46 = "Ouray" 47 = "Park" 48 = "Phillips" 49 = "Pitkin" 50 = "Prowers"
                 51 = "Pueblo" 52 = "Rio Blanco" 53 = "Rio Grande" 54 = "Routt" 55 = "Saguache"
                 56 = "San Juan" 57 = "San Miguel" 58 = "Sedgwick" 59 = "Summit" 60 = "Teller"
                 61 = "Washington" 62 = "Weld" 63 = "Yuma" 80 = "Broomfield";

run;

Options NOCENTER nobyline orientation=portrait papersize=letter topmargin=0.5 in;
ODS LISTING CLOSE;

ODS PDF File="C:\Users\vakohl\Documents\TestDev SAS\Reports\2023 Marriage Summary by County.pdf" style=minimal notoc;

proc freq data = marriage;
  Format CeremonyMonth CeremonyMonthf. Countycode Countycodef.;
table Countycode*Ceremonymonth / missing norow nocol nopercent;
   Title "Marriage Counts by County and Month For Year &year";

run;
ods pdf close;
ODS listing;
run;

/*To search for specific data::::::::::
Options NOCENTER nobyline orientation=portrait papersize=letter topmargin=0.5 in;
ODS LISTING CLOSE;

ODS PDF File="V:\VITAL RECORDS\Program Support\RDI Unit\Statistical Analyst\Quality Assurance Processes\Marriage\Marriage Garfield.pdf" style=minimal notoc;

/*proc print data=marriage; 
where County = ("GARFIELD") AND CeremonyMonth = 11; 
var county countyfilenumber partyonefn partyonemn partyoneln partyonedob partytwofn partytwomn partytwoln partytwodob ceremonydate;
   Title "Garfield County Nov 2023";

run;
ods pdf close;
ODS listing;

title;*/*/
