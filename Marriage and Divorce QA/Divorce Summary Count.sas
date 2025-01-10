*////////////////////////////////////////////////////////////////////////////

    tblDissolutiondata is the main table which contains all Dissolution data
          Monthly Dissolution Counts

/////////////////////////////////////////////////////////////////////////////
                                                    
==============================================================
              SUMMARY TABLE BY COUNTY AND YEAR               |
             Change ceremonyyear and Title Year              |
==============================================================;
libname mdware odbc dsn=mdwarehouse schema=dbo;

%let filedate=%sysfunc(today(),mmddyy6.);
%let year=2023;

data divdf;
set mdware.tblDissolutiondata;
where Decreeyear = 2023 AND void in (.,0);
run;
Proc format; 
   VALUE DecreeMonthf 1 = "Jan"
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

Options orientation=landscape;

ODS PDF FILE = "H:\VK SAS\Reports\&year Divorce &filedate Summary.pdf" style=pearl notoc;
ods noproctitle;
proc freq data = divdf;
  Format DecreeMonth DecreeMonthf. Countycode Countycodef.;
table Countycode*Decreemonth / missing norow nocol nopercent;
   Title "Dissolutions County by Month For Year &year";
run;

ODS pdf close;
run;


/*To search/print for specific data::::::::::*/
data divdf; 
set divdf; 
one = 1; 
run; 

ods output summary = county; 
proc means data= divdf n completetypes; 
class CountyCode DecreeMonth; 
freq decreemonth;
var one; 
run; 







%let county = SUMMIT;

Options NOCENTER nobyline orientation=portrait papersize=letter topmargin=0.5 in;
ODS LISTING CLOSE;

ODS PDF File="H:\VK SAS\Reports\&county Divorce.pdf" style=minimal notoc;

proc freq data = county;
  Format DecreeMonth DecreeMonthf. Countycode Countycodef.;
table Decreemonth / missing norow nocol nopercent nocum;
weight one_N / zeros;
   Title "&&County Dissolutions by Month For Year 2023";
where countycode = 59;
run;
ods pdf close;
ODS listing;

title;