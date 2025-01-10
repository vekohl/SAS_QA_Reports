

***********************************************************************
This SAS program was created to query and report to funeral home directors. 
Any questions about this program should be referred to vanessa.kohl@state.co.us
/* Overview: 
Set Up Environment (libraries, macros)
Pull Data from backend database

Query Data for: 
Count & Percentages
Total
Drop to Paper
Corrections
Inside City Limits (Unknown)
Timeliness (5-7 Days in/out)
Occupation Unknowns/Retired									
/********************************************************************************/

*****************CHANGE EVERY MONTH;

%let month = August;

/********************************************************************************/;

*Macro variable dsn = dataset number;
%let dsn=24;

*Output Destination;
%let OUT=V:\VITAL RECORDS\Program Support\RDI Unit\Statistical Analyst\Quality Assurance Processes\Death\Funeral Home QA Reports;

*Do Not Delete Files: Images, Imports;
%let DND=V:\VITAL RECORDS\Program Support\RDI Unit\Statistical Analyst\SAS Programs\DND;

*Macro program to sort dataset by variable;
%macro sort (v1/*data source*/,v2/*variable*/);

	proc Sort data=&v1;
		by &v2;/*variable*/
	run;

%mend sort;

LIBNAME DEATH BASE "W:\death\master";

/**************LOAD ALL DATA SOURCES**********/
%sort(death.death&dsn,deathstate);

DATA deathdfpull;
	set death.death&dsn;
	where deathstate in ('COLORADO');
RUN;

proc import 
	datafile="&DND\Death DND\COVESCorrections24.xlsx"
	out=correctionsdf
	dbms=excel
	replace;
run;

data correctionsdf; 
set correctionsdf; 
EDRUniqueIdentifier = substr(StateFileNumber, 1, 13);
run; 

data correctioncount;
set correctionsdf; 
	if CorrectionType = "Amendment" then
		corr_count = 1;
run;

proc sql;
	create table correctionfreq as
		select EDRUniqueIdentifier,sum(corr_count) as corr_count
			from correctioncount
				group by EDRUniqueIdentifier;
quit;

proc import
	datafile="&DND\Death DND\FHNsRandomIDs.xlsx"
	out=randomids
	dbms=excel
	replace;
run;

/* */
%sort(deathdfpull,edruniqueidentifier);
%sort (correctionfreq,edruniqueidentifier);
data mergeddf; 
	merge deathdfpull (in=a) correctionfreq (in=b);
	by EDRUniqueIdentifier; 
run; 


/********************************************************************************************************************************************/
/************** Mark QAs **************/
proc print data=mergeddf; 
where funeralhomename = "RESTHAVEN FUNERAL HOME"; 
RUN; 

DATA rawcount;
	set mergeddf;
	length DTP_count 5 citylimits_count 5 daysdiff 5 daysdiffperc 5 retire 5 c 5 r 5 clear 5;
	daysdiff = intck("day", dod, (datepart(State_register_dt)));
	c = index(FuneralHomeName, "CORONER");
	r = index(FuneralHomeName, "RESIDENCE");
	clear = sum(c, r);

	if FuneralHomeName = ' ' then
		delete;

	if FuneralHomeName = 'FAMILY' then
		delete;

	if dod = "." then
		delete;

	if dDroptoPaper = "." then
		DTP_count = 0;
	else DTP_count = 1;

	if ResideZipCode not in (" ", "?") AND citylimits  not in ("Y", "N") then
		CityLimits_count = 1;
	else CityLimits_count = 0;

	if Occupation = "RETIRED" then
		retire = 1;
	else retire = 0;

	if daysdiff ge 8 then
		daysdiffperc = 0;
	else daysdiffperc=1;

	if clear ne 0 then
		delete;
run;

/*this block exists two conflate similar locations that should be combined. It helps later to do this now. */
data rawcount; 
	set rawcount;
	funeralhomename = tranwrd(funeralhomename, "MILE HIGH FAMILY SERVICES AKA MILE HIGH EMBALMING AND SHIPPING", "MILE HIGH EMBALMING AND SHIPPING");
	funeralhomename = tranwrd(funeralhomename, "STORK FAMILY MORTUARY", "STORK-MORLEY FUNERAL & CREMATION");
	funeralhomename = tranwrd(funeralhomename, "RESTHAVEN COLORADO LLC.", "STORK-MORLEY FUNERAL & CREMATION");
run;


%sort(rawcount,dod);

/****************Does month limit thing ***********************/
data filteredcounted;
	set rawcount;

	if dod <= intnx("month", today(), -1, "end");

	* Before the end of last month;
run;

/****************Does month formatting thing ***********************/
data filteredcounted;
	length month 8;
	format month 2.;
	set filteredcounted;
	month=month(dod);
	put month=;
run;


data filteredcounted; 
set filteredcounted; 
if corr_count=0 then corr_count=.;
run; 

proc sql;
	create table fhcount as
		select FuneralHomeName, month, count(*) as Total, sum(DTP_Count) as DTP, sum(CityLimits_count) as City, sum(daysdiffperc) as Time,sum(retire) as Retire,sum(corr_count) as CorrectionItems,count(corr_count) as CorrectionCount 
			from  filteredcounted
				group by FuneralHomeName, month;
quit;

/*******************Merges Random IDs with Frequency DF*******************/

/*these next two/three blocks remove all spaces from the funeral home name, 
which resolves matching errors*/
data fhcount;
	set fhcount;
	fhn = strip(compress(funeralhomename));
run;

data randomids;
	set randomids;
	fhn = strip(compress(funeralhomename));
run;

%sort(fhcount,fhn);
%sort(randomids,fhn);

data finalmerge  noID nodata;
	merge fhcount (in=a) randomids (in=b);
	by fhn;

	if a and b then
		output finalmerge;
	else if a and not b then
		output noID;
	else if b and not a then
		output nodata;
run;

/************************************** Formatting for report **************************************/
data report;
	length monthf $15;
	set finalmerge;

	if month = 1 then
		monthf = "Jan";

	if month = 2 then
		monthf = "Feb";

	if month = 3 then
		monthf = "Mar";

	if month = 4 then
		monthf = "Apr";

	if month = 5 then
		monthf = "May";

	if month = 6 then
		monthf = "Jun";

	if month = 7 then
		monthf = "Jul";

	if month = 8 then
		monthf = "Aug";

	if month = 9 then
		monthf = "Sep";

	if month = 10 then
		monthf = "Oct";

	if month = 11 then
		monthf = "Nov";

	if month = 12 then
		monthf = "Dec";
run;

proc sort data=report;
	by ID Month;
run;

proc format;
	picture pctfmt (round) other='009.99%';
run;
%let filedate = %sysfunc(today(), mmddyy6.);
ods html close;
goptions reset=goptions;
goptions device=png;
ods listing close;
ods escapechar='^';

/*One Report by ID*/
ods pdf file = "&OUT\Funeral Home QA Report &month 2024.pdf";
ods pdf startpage=no;
options nodate nonumber;
title1 "^S={preimage='&DND\cdpheVRlogo.png'}";
title2 ^{newline} "&month 2024 Mortality Data Quality & Timeliness";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]Below you will find the Mortality Data Quality Assurance & Timeliness Reports. We are excited about these new reports and hope you will find them useful and insightful for your facility. The goal is for each facility to review the report to determine if registration is being done timely and in a thorough manner. Goals or thresholds are provided where appropriate. If you have any questions please contact Vanessa Kohl at vanessa.kohl@state.co.us ^{newline}}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]This report will be shared monthly. The first table of the report contains Colorado totals, which reflect the state as a whole. Following the Colorado table, each facility’s totals are reported. Each funeral home has been assigned a unique ID and will use that ID to locate their facility’s report. IDs are listed in alphanumerical order (numbers first then letters A to Z). You can locate your ID using the Table of Contents in Adobe Acrobat or by using the search function within your browser/pdf viewer. ^{newline}}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt font_weight=bold]Report Format}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]Data are broken down into rows by month using date of death. Columns of the report reflect a count and a percentage of the total for each data item (Timeliness, Drop to Paper, Amendments, Unknown City Limits, and Occupation = Retired). The first column lists the total number of registered deaths for each month. ^{newline}}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt font_weight=bold]Timeliness}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]Statute requires registration within 5 days after the death occurs. To account for weekends and holidays, we used an overall window of 7 days to quantify timeliness. Our goal for timeliness is that 75% of deaths are registered within 7 days.  ^{newline}}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt font_weight=bold]Drop to Paper}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]This refers to registrations that were started electronically and then converted to paper form for completion. ^{newline}}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt font_weight=bold]Corrections}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]This refers to the legal corrections processed by the state office after certificates were complete. Corrected items refers to the items within a certificate that were corrected. Each correct certificate has at least one corrected item, but some may include more than one. ^{newline}}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt font_weight=bold]Unknown City Limits}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]This checks for data quality related to collecting complete address information whenever possible. Each count of “Unknown City Limits” reflects a registration with that boxed checked, but with a zip code (requiring a zip code removes those registrations in which an address is completely unknown). The acceptable threshold for this data item is under 1%.  ^{newline}}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt font_weight=bold]Occupation = Retired}";
ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]This item looks for “retired” as the decedent’s occupation. While the decedent may be retired, this data point is allocated for the decedent’s lifelong occupation, even if previous due to retirement. Our goal is to eliminate “retired” as an occupation, bringing the percentage to 0%.  ^{newline}}";
ods pdf startpage=no;
ods pdf text="^{style [just=center font_face=calibri fontsize=12pt]Colorado Totals}";

PROC TABULATE
	data=report format=best5.;
	var DTP City Time Retire CorrectionItems CorrectionCount Total;
	class  Month /	ORDER= DATA;
	keylabel sum='Total' pctsum='%';

	table Month='Month' 
		all="Total Year"
		, (Total *sum={label=" "})
		(Time={label="Timeliness < 7 Days"}* (sum pctsum<Total> *f=pctfmt.))
		(DTP={label="Drop to Paper"}* (sum pctsum<Total> *f=pctfmt. ))
		(CorrectionItems={label="Corrected Items"}* (sum))
		(CorrectionCount={label="Corrected Certificates"}* (sum pctsum<Total> *f=pctfmt. ))
		(City={label="Unknown City Limits"}*  (sum pctsum<Total> *f=pctfmt. ))
		(Retire={label="Occupation = Retired"}*  (sum pctsum<Total> *f=pctfmt.));
RUN;

/*************REPORTS BY ID************************************/
ods pdf startpage=now;
ods pdf text="^{style ^{newline}}";
ods pdf text="^{style [just=center font_face=calibri fontsize=12pt]Individual Facility Reports by ID }";

PROC TABULATE 
	data=report format=best5.;
	var DTP City Time Retire CorrectionItems CorrectionCount Total;
	class ID Month /	ORDER=DATA;
	keylabel sum='Total' pctsum='%';

	table ID, Month='Month'  all="Total YTD"
		, (Total *sum={label=" "})
		(Time={label="Timeliness < 7 Days"}* (sum pctsum<Total> *f=pctfmt. ))
		(DTP={label="Drop to Paper"}* (sum pctsum<Total> *f=pctfmt. ))
		(CorrectionItems={label="Corrected Items"}* (sum))
		(CorrectionCount={label="Corrected Certificates"}* (sum pctsum<Total> *f=pctfmt. ))
		(City={label="Unknown City Limits"}*  (sum pctsum<Total> *f=pctfmt. ))
		(Retire={label="Occupation = Retired"}*  (sum pctsum<Total> *f=pctfmt. ));
RUN;

ods pdf close;
title;
ods html;
ods results=on;
