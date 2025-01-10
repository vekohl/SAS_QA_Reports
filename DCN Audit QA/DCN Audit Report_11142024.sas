
LIBNAME WrkBk EXCEL "\\dphe.local\cheis\Programs\HSVR\VITAL RECORDS\Program Support\RDI Unit\Fraud & Security\Security Paper\All Offices DCN Monitoring Log 2019.xlsx" 
                       MIXED=YES TEXTSIZE=32767;
DATA WORK.source_data;
SET WrkBk."2024 Q3$"n;
*rename contact=email1;
RUN;
LIBNAME WrkBk CLEAR;

/*
proc import datafile="\\dphe.local\cheis\Programs\HSVR\VITAL RECORDS\Program Support\RDI Unit\Fraud & Security\Security Paper\All Offices DCN Monitoring Log 2019.xlsx" 
  out=source_data dbms=XLSX;
getnames=yes;
sheet="2020 Q1";
run;

data source_data; 
 set source_data; 
  rename contact=email1;
run; 
*/

data contacts; 
length county email1 email2 $50 Specific_Discrepancies $1500;
 set source_data (drop=response--Percentage_After_Corrected); 

 if email2 EQ ' ' then email2 = email1;

 if email1 NE ' ' then do;
 email_1 = cats("'",email1,"'");
 end;
 if email2 NE ' ' then do;
 email_2 = cats("'",email2,"'");
 end;

 drop email1 email2;
 if email_1 NE ' ' or email_2 NE ' ' then do; 
   email = catx("  ",email_1,email_2);
 end;

drop email_1 email_2;
*length Unaccounted_for $6;
*Unaccounted_for = __Unaccounted_for;

county = UPCASE(County);
today=today();
tdate=PUT(today,WEEKDATE29.);
  call symput('tdate',trim(left(put(tdate,$29.))));

/*Test Only*/
*email="'vanessa.kohl@state.co.us'";

/*if __Unaccounted_for EQ 'n/a' then delete*/

tot_iss=PUT(Total_Issuance,comma8.); 
if county NE ' ' ; 
drop f12-f42;

/*Define Qtr and Year)*/
  date = today()-25; format date mmddyy10.;
  qtr = cat('Q',qtr(date));
  month = month(date);
  year = year(date);
  length yr_qtr $7;
  yr_qtr = catx(' ',year,qtr);
  call symput('yr_qtr',trim(left(put(yr_qtr,$7.))));
run; 
proc sort data = contacts; by county Name email __Unaccounted_for tot_iss __Missing_DCNs Specific_Discrepancies; run;
%put &yr_qtr ;

data ck1 ck2; /*CHECK for distribution of __Unaccounted_for*/
 set contacts;
if  __Unaccounted_for EQ "0.00%" then output ck1;
else if __Unaccounted_for NE "0.00%" then output ck2;
run;

/*Send to County Offices that DO NOT have Discrepancies*/
 
%macro loopit(dsn,byvar,byvar2,byvar3,byvar4,byvar5,byvar6,byvar7);

proc sort data=&dsn out=sorted;
where __Unaccounted_for EQ "0.00%";
by &byvar;
run;

data _null_;
set sorted;
   call symputx("val"||left(_n_),&byvar);
   call symputx("name"||left(_n_),&byvar2);
   call symputx("email"||left(_n_),&byvar3);
   call symputx("UAfor"||left(_n_),&byvar4);
   call symputx("TotIss"||left(_n_),&byvar5);
   call symputx("MissDCNs"||left(_n_),&byvar6);
   call symputx("SpecDescr"||left(_n_),&byvar7);
   call symputx("last",_n_);

run;

%do i = 1 %to &last;

options emailsys="smtp" emailhost="10.48.200.202" emailport=25;

FILENAME mail1 EMAIL 
                     TO=(&&email&i)
                     SUBJECT="&&val&i -Quarterly Security Paper Report Results for &yr_qtr"
					 FROM = "tami.rodriguez@state.co.us" 
					 CC=('vanessa.kohl@state.co.us')
					 ;


DATA _NULL_;
          /* Use the E-mail access method to send a message to the           */
          /* listed E-mail address. Multiple E-mail addresses may be used    */
        FILE mail1;

		PUT @1 "Date: &tdate";
		PUT @1 " ";
 		PUT @1 "Greetings &&Name&i,";
		PUT @1 " ";
		PUT @1 "As part of our ongoing efforts to prevent fraud, each quarter the Field and Fraud units are reviewing security paper ";
        PUT @1 "logging at all vital records offices. We are striving to improve the logging of security paper in COVES throughout the"; 
        PUT @1 "state with the goal of 100% of paper accounted for."; 
		PUT @1 " ";
        PUT @1 "Quarter report dates: "; 
	    PUT @1 "     o	1st Quarter: Jan 1   Mar 31";
        PUT @1 "     o	2nd Quarter: Apr 1   Jun 30";
        PUT @1 "     o	3rd Quarter: Jul 1   Sept 30";
        PUT @1 "     o	4th Quarter: Oct 1   Dec 31";
        PUT @1 " "; 
        PUT @1 "For the previous quarter our report shows that &&val&i issued &&TotIss&i sheets of security paper";
        PUT @1 "with EVERY SHEET ACCOUNTED for in COVES.";
        PUT @1 " ";
        PUT @1 "GREAT JOB!";
        PUT @1 "We appreciate your office s hard work and attention to detail in accurately maintaining your paper"; 
        PUT @1 "logging in COVES."; 
		PUT @1 " ";
        PUT @1 "If you have any questions about the report or your office s DCN logging please contact me and I will be happy to assist."; 
        PUT @1 " ";
        PUT @1 "Many thanks,";
        PUT @1 "Tami";
		PUT @1 " " ;
        PUT @1 "Tami L. Rodriguez                                                                                  "
           /@1 "Records & Data Integrity Supervisor                                                                "
           /@1 "Office of the State Registrar of Vital Statistics                                                  "
           /@1 "Colorado Department of Public Health & Environment                                                 "
           /@1 "P 303.692.3328 | F 303.691.7945                                                                    "
           /@1 "4300 Cherry Creek Drive South, Denver, CO 80246                                                    "
           /@1 "tami.rodriguez@state.co.us  |  www.colorado.gov/cdphe                                              ";
		PUT @1 " ";
RUN;

%end;

%mend;

run; 
 
options mprint;
%loopit(contacts, county, name, email, __Unaccounted_for, tot_iss, __Missing_DCNs, Specific_Discrepancies)

/*Send to County Offices that DO HAVE Discrepancies*/

%macro loopit(dsn,byvar,byvar2,byvar3,byvar4,byvar5,byvar6,byvar7);

proc sort data=&dsn out=sorted;
where __Unaccounted_for NE "0.00%";
by &byvar;
run;

data _null_;
set sorted;
   call symputx("val"||left(_n_),&byvar);
   call symputx("name"||left(_n_),&byvar2);
   call symputx("email"||left(_n_),&byvar3);
   call symputx("UAfor"||left(_n_),&byvar4);
   call symputx("TotIss"||left(_n_),&byvar5);
   call symputx("MissDCNs"||left(_n_),&byvar6);
   call symputx("SpecDescr"||left(_n_),&byvar7);
   call symputx("last",_n_);

run;

%do i = 1 %to &last;

options emailsys="smtp" emailhost="10.48.200.202" emailport=25;

FILENAME mail1 EMAIL 
                     TO=(&&email&i)
                     SUBJECT="&&val&i -Quarterly Security Paper Report Results for &yr_qtr"
					 FROM = "tami.rodriguez@state.co.us" 
					 CC=('vanessa.kohl@state.co.us')
					 ;


DATA _NULL_;
          /* Use the E-mail access method to send a message to the           */
          /* listed E-mail address. Multiple E-mail addresses may be used    */
        FILE mail1;

		PUT @1 "Date: &tdate";
		PUT @1 " ";
 		PUT @1 "Greetings &&Name&i,";
		PUT @1 " ";
		PUT @1 "As part of our ongoing efforts to prevent fraud, each quarter the Field and Fraud units are reviewing security paper ";
        PUT @1 "logging at all vital records offices. We are striving to improve the logging of security paper in COVES throughout the"; 
        PUT @1 "state with the goal of 100% of paper accounted for."; 
		PUT @1 " ";
        PUT @1 "Quarter report dates: "; 
	    PUT @1 "     o	1st Quarter: Jan 1   Mar 31";
        PUT @1 "     o	2nd Quarter: Apr 1   Jun 30";
        PUT @1 "     o	3rd Quarter: Jul 1   Sept 30";
        PUT @1 "     o	4th Quarter: Oct 1   Dec 31";
        PUT @1 " "; 
        PUT @1 "For the previous quarter our report shows that &&val&i issued &&TotIss&i sheets of security paper";
        PUT @1 "with &&UAfor&i unaccounted for in COVES. ";
        PUT @1 " ";
        PUT @1 "There are a few areas in your county s report that show discrepancies in your paper log. After reviewing the report, ";
        PUT @1 "we have found that &&val&i has (&&MissDCNs&i) security paper Document Control Numbers for the last quarter. ";
		PUT @1 " ";
        PUT @1 "Please see below for the specific DCN discrepancies that need attention. ";
		PUT @1 " ";
        PUT @1 "Once you are able to correct the discrepancies, please let me know and I will adjust your office s percentage ";
        PUT @1 "in our monitoring log to reflect the changes. ";
		PUT @1 " " ;
        PUT @1 "If you would like to run a DCN report to check these discrepancies, the steps are as follows: ";
        PUT @1 "On the main COVES screen, go to the Fee menu item. Click on Reports, then <Document Control Listing Report>. Enter the range of ";
        PUT @1 "dates or the range of security paper document control numbers you wish to check. Click generate to view the report. Any gaps, ";
        PUT @1 "errors or duplications will be shown. ";
		PUT @1 " ";
		PUT @1 "Discrepancies:";
		PUT @1 "____________________________________________________________________________________";
		PUT @1 " ";
		PUT @1 "&&SpecDescr&i";
		PUT @1 "____________________________________________________________________________________";
		PUT @1 " ";
        PUT @1 "If you have any questions about the report or how to correct discrepancies, please contact me and I will be happy to assist."; 
        PUT @1 " ";
        PUT @1 "Many thanks,";
        PUT @1 "Tami";
		PUT @1 " " ;
        PUT @1 "Tami L. Rodriguez                                                                                  "
           /@1 "Records & Data Integrity Supervisor                                                                "
           /@1 "Office of the State Registrar of Vital Statistics                                                  "
           /@1 "Colorado Department of Public Health & Environment                                                 "
           /@1 "P 303.692.3328 | F 303.691.7945                                                                    "
           /@1 "4300 Cherry Creek Drive South, Denver, CO 80246                                                    "
           /@1 "tami.rodriguez@state.co.us  |  www.colorado.gov/cdphe                                              ";
		PUT @1 " ";
RUN;

%end;

%mend;

run; 
 
options mprint;
%loopit(contacts, county, name, email, __Unaccounted_for, tot_iss, __Missing_DCNs, Specific_Discrepancies)
