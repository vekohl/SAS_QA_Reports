
/* CORONER MORTALITY DATA QUALITY REPORT */


/*Environment & Macro Set Up*/
%let month = May; *for report title;
%let dsn=24; *dsn = dataset number; 
%let DND=V:\VITAL RECORDS\Program Support\RDI Unit\Statistical Analyst\SAS Programs\DND; *where the logo file for the branding is saved;

%let filedate = %sysfunc(today(), yymmddn8.);
%let file='V:\VITAL RECORDS\Program Support\RDI Unit\Statistical Analyst\Quality Assurance Processes\Death\Coroner QA Reports';
option dlcreatedir; libname Folder "&file.\Coroner QA for &filedate";

%let output=\Coroner QA for &filedate; 


goptions device=png;

/*Libraries (might be previously set)*/
libname death base "W:\death\master";

/*Macro Sort dataset by variable*/
%macro sort (v1,v2);
	proc Sort data=&v1;
		by &v2;
	run;
%mend sort;



/* Data pull, clean, count */
/*pull*/
%sort (death.death&dsn, deathstate);  

DATA deathtempdf;
	set death.death&dsn;
	where deathstate in ('COLORADO'); 
RUN;


/* Data pull, clean, count */
/*clean*/
data cleandf;
	set deathtempdf;
if dod <= intnx("month", today(), -1, "end");*Limits report to before the end of last month;
	acmecode = catx(',', acmecode1, acmecode2, acmecode3, acmecode4, acmecode5, acmecode6, acmecode7, acmecode8, acmecode9, acmecode10, acmecode11, ',');
	coroner = index(CertifierOfficeName, "CORONER");
	daysdiff = intck("day", dod, (datepart(dcertifieddate)));
	drugover=.;
	unspecdrug=.;
	mechdeath=.;
	illdefined=.;
	Ntime=.;
run; 

/* Data pull, clean, count */
/*count*/
data counteddf; 
	set cleandf; 

/*1 Drug Overdose without drug*/
	if (UnderCauseDeath>="X40" and UnderCauseDeath<="X44") or (UnderCauseDeath>="X60" and UnderCauseDeath<="X64") or (UnderCauseDeath>="X85" and UnderCauseDeath<="X85") or (UnderCauseDeath>="Y10" and UnderCauseDeath<="Y14") then
		drugover=1;
	else drugover=0;

	if drugover = 1 then
		do;
			if (find(acmecode,'T509')) then
				do;
					unspecdrug=1;
				end;

			if	(find(acmecode,'T36') or find(acmecode,'T37') or  find(acmecode,'T38') or find(acmecode,'T39') or find(acmecode,'T40') or find(acmecode,'T41') or find(acmecode,'T42') or find(acmecode,'T43') or find(acmecode,'T44') or find(acmecode,'T45') or find(acmecode,'T46') or find(acmecode,'T47') or  find(acmecode,'T48') or  find(acmecode,'T49') or find(acmecode,'T50,') or find(acmecode,'T501') or find(acmecode,'T502') or find(acmecode,'T503') or find(acmecode,'T504') or find(acmecode,'T505') or find(acmecode,'T506') or find(acmecode,'T507') or find(acmecode,'T508')) then
				do;
					unspecdrug=0;
				end;
		end;

/*2 Mechanism of Death*/
	if mannerofdeath ne "P" and UnderCauseDeath>="I46" and UnderCauseDeath<="I469" then
		mechdeath=1;
	else if mannerofdeath ne "P" and UnderCauseDeath>="J96" and UnderCauseDeath<="J969" then
		mechdeath=1;
	else if mannerofdeath ne "P" and UnderCauseDeath="P285" then
		mechdeath=1;
	else if mannerofdeath ne "P" and UnderCauseDeath="R092" then
		mechdeath=1;
	else mechdeath=0;


/*3 Ill-Defined Conditions*/
	if UnderCauseDeath>="R00" and UnderCauseDeath<="R949" then
		illdefined=1;
	else if UnderCauseDeath >= 'R96' and UnderCauseDeath <= 'R99' then
		illdefined=1;
	else illdefined=0;


/*4 Over days from DOD to certifier date for Timeliness*/
if daysdiff lt 60 then
		Ntime = 1;
	else Ntime = 0;
run;


/* Dataset created using frequencies by coroner office and month of death */
proc sql; 
	create table CoronersCountdf as
	select CertifierOfficeName, 
				DeathDtMonth, count(*) as Total, 
				sum(case when coroner gt 0 then 1 else 0 end) as CoronerN,
				sum(case when coroner gt 0 then Ntime else 0 end) as Timeliness, 
				sum(case when coroner gt 0 then drugover else 0 end) as DrugOverdoseN, 
				sum(case when coroner gt 0 then unspecdrug else 0 end) as UnSpecifiedDrugN, 
				sum(case when coroner gt 0 then mechdeath else 0 end) as MechDeathN,
				sum(case when coroner gt 0 then illdefined else . end) as IlldefinedN,
				sum(case when mannerofdeath = "N" then 1 else 0 end) as Natural,
				sum(case when mannerofdeath = "H" then 1 else 0 end) as Homicide,
				sum(case when mannerofdeath = "S" then 1 else 0 end) as Suicide,
				sum(case when mannerofdeath = "A" then 1 else 0 end) as Accident,
				sum(case when mannerofdeath = "C" then 1 else 0 end) as Undetermined,
				sum(case when mannerofdeath = "P" then 1 else 0 end) as Pending
	from counteddf
		group by CertifierOfficeName, DeathDtMonth;
quit;


/* Report Formating */
/* Month for DOD */
data CoronersCountdf;
	length monthf $15;
	set CoronersCountdf;
certifierofficename= propcase(certifierofficename); 

	if DeathDtMonth in ('01') then monthf = "Jan";
	if DeathDtMonth in ('02') then monthf = "Feb";
	if DeathDtMonth in ('03') then monthf = "Mar";
	if DeathDtMonth in ('04') then monthf = "Apr";
	if DeathDtMonth in ('05') then monthf = "May";
	if DeathDtMonth in ('06') then monthf = "Jun";
	if DeathDtMonth in ('07') then monthf = "Jul";
	if DeathDtMonth in ('08') then monthf = "Aug";
	if DeathDtMonth in ('09') then monthf = "Sep";
	if DeathDtMonth in ('10') then monthf = "Oct";
	if DeathDtMonth in ('11') then monthf = "Nov";
	if DeathDtMonth in ('12') then monthf = "Dec";
run;

/* Report Formating */
/* Percentages */
proc format;
	picture pctfmt (round) other='009.99%';
run;

/* Report Formating */
/* Sorting & PDF options */
%sort (coronerscountdf, deathdtmonth);

title; 
title2; 
goptions reset=goptions;
goptions device=png;
ods escapechar='^';


/* Report Macro */
/*create macro*/
%macro mecountyreport;
	%do i = 1 %to &numcoron;
		ods pdf file = "&output\&&CertifierOfficeName&i MDQ.pdf" pdftoc=1; options nodate nonumber;
			title1 "^S={preimage='&DND\cdpheVRlogo.jpg'}";
			title2 ^{newline} "&month 2023 Mortality Data Report for &&CertifierOfficeName&i";
				ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]Below you will find new Mortality Data Quality Assurance & Timeliness Reports tailored to coroners. We are excited about these new reports and hope you will find them useful and insightful. This report will be shared monthly along with its companion report showing breakdown for manner of death. This report shows timeliness, drug overdose without drug specification, mechanism of death as underlying cause, and ill-defined cause of death. Goals or thresholds are provided where appropriate. If you have any questions please contact Vanessa Kohl at vanessa.kohl@state.co.us ^{newline}}";

				ods pdf text="^{style [just=left font_face=calibri fontsize=10pt font_weight=bold]Report Format}";
				ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]The first table presents state totals and the subsequent table is specific to your county. Table rows show monthly data by date of death. Columns of the report reflect a count and a percentage of the total for each data item (Timeliness, Drug Overdoses total, number of drug overdoses without a drug specified, mechanism of death as the underlying cause, and ill-defined COD). The first column shows the number of total deaths in the state of Colorado, the second column lists the total number of coroner registered deaths for each month. For example, in Colorado in January 2023, there were 945 total deaths registered by county coroners' offices.  ^{newline}}";

				ods pdf text="^{style [just=left font_face=calibri fontsize=10pt font_weight=bold]Timeliness}";
				ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]This refers to registrations where death is certified within 60 days of death. The intended threshold for this item is 95%. ^{newline}}";

				ods pdf text="^{style [just=left font_face=calibri fontsize=10pt font_weight=bold]Mechanism of Death as COD}";
				ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]This refers to deaths classified with codes for cardiac arrest (I46), respiratory failure (J96), respiratory failure of a newborn (P28.5), or respiratory arrest (R09.2). For this item, the threshold should be under 1.1%.   ^{newline}}";

				ods pdf text="^{style [just=left font_face=calibri fontsize=10pt font_weight=bold]Ill-defined conditions as COD}";
				ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]This refers to deaths classified with codes in the R Chapter: Symptoms signs and abnormal clinical and laboratory findings, not elsewhere classified (R00:R94, R96:R99) R95 is excluded from this count. For this item, the threshold should be under 1.1% as well. ^{newline}}";

				ods pdf text="^{style [just=left font_face=calibri fontsize=10pt font_weight=bold]N of Drug Overdoses & Unspecified Drug}";
				ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]N of Drug Overdoses refers to deaths classified as drug overdoses (ICD-10 codes X40:44, X60:64, X85, Y10:14). Unspecified drug refers to drug overdose deaths coded with T509, count is presented first, second is percentage of drug overdoses with unspecified drug. The threshold for this item is under 12.3%. ^{newline}}";

				ods pdf text="^{style [just=left font_face=calibri fontsize=10pt font_weight=bold]Manner of Death Breakdown}";
				ods pdf text="^{style [just=left font_face=calibri fontsize=8pt]The last two pages of the report show the CO and county breakdown for manner of death. Columns of this table reflect a count and percentage of the total for each data item (natural, accident, homicide, suicide, underdetermined, and pending). Our goal is to clear all deaths from 'pending' as the manner of death, bringing the total to zero %.  ^{newline}}";

ods pdf text="^{style [just=center font_face=calibri fontsize=14pt] Timeliness & Data Quality Report: Colorado Totals ^{newline}}";

ods proclabel="Data Quality: Colorado";
PROC TABULATE
							data=CoronersCountdf format=best5.;
							var Total coronerN Timeliness DrugOverdoseN UnSpecifiedDrugN MechDeathN IlldefinedN;
								class  Monthf /	ORDER= DATA;
									keylabel sum='Count' pctsum='% of coroner total';
								table Monthf='Month' all="Total YTD",
										(Total *sum={label="in Colorado"})
										(coronerN={label="Coroner Certified"} *(sum pctsum<Total>={label="% of CO total"} *f=pctfmt. ))
										(Timeliness={label="Timeliness < 60 Days"}* (sum pctsum<coronerN> *f=pctfmt. ))
										(MechDeathN={label="Mechanism of Death as COD"}* (sum pctsum<coronerN> *f=pctfmt. ))
										(IlldefinedN={label="Illdefined COD"}*  (sum pctsum<coronerN> *f=pctfmt. ))
										(DrugOverdoseN={label="N of Drug Overdoses"}* (sum))
										(UnSpecifiedDrugN={label="Unspecified Drug"}* (sum pctsum<DrugOverdoseN>={label= "% of DO total"} *f=pctfmt. ));
						RUN;

	ods pdf startpage=now;

ods pdf text="^{style [just=center font_face=calibri fontsize=14pt]Timeliness & Data Quality Report: County Totals ^{newline}}";

ods proclabel="Data Quality: County";
						PROC TABULATE
							data=CoronersCountdf format=best5.;
								where CertifierOfficeName = "&&CertifierOfficeName&i";
									var  coronerN Timeliness DrugOverdoseN UnSpecifiedDrugN MechDeathN IlldefinedN;
									class  CertifierOfficeName Monthf /	ORDER= DATA;
										label certifierofficename='Coroner';
										keylabel sum='Count' pctsum='% of coroner total';
									table Monthf='Month' all="Total YTD", 
											(coronerN={label="Coroner Certified"} *(sum ))
											(Timeliness={label="Timeliness < 60 Days"}* (sum pctsum<coronerN> *f=pctfmt. ))
											(MechDeathN={label="Mechanism of Death as COD"}* (sum pctsum<coronerN> *f=pctfmt. ))
											(IlldefinedN={label="Illdefined COD"}*  (sum pctsum<coronerN> *f=pctfmt. ))
											(DrugOverdoseN={label="N of Drug Overdoses"}* (sum))
											(UnSpecifiedDrugN={label="Unspecified Drug"}* (sum pctsum<DrugOverdoseN>={label= "% of DO total"} *f=pctfmt. ));					
						RUN;

	ods pdf startpage=now;
				ods pdf text="^{style [just=center font_face=calibri fontsize=14pt]Manner of Death: Colorado Totals ^{newline}}";
		ods proclabel="Manner of Death: Colorado";				
						PROC TABULATE
							data=CoronersCountdf format=best5. ;
								var total natural accident Homicide Suicide Undetermined Pending;
								class  CertifierOfficeName Monthf /	ORDER= DATA;
									label certifierofficename='Coroner';
									keylabel sum='Total' pctsum='%';
								table Monthf='Month' all="Total YTD",
										(Total *sum={label=" "})
										(Natural={label="Natural"}* (sum pctsum<Total> *f=pctfmt. ))
										(Accident={label="Accident"}* (sum pctsum<Total> *f=pctfmt. ))
										(Homicide={label="Homicide"}* (sum pctsum<Total> *f=pctfmt. ))
										(Suicide={label="Suicide"}* (sum pctsum<Total> *f=pctfmt. ))
										(Undetermined={label="Undetermined"}* (sum pctsum<Total> *f=pctfmt. ))
										(Pending={label="Pending"}* (sum pctsum<Total> *f=pctfmt. ));
						RUN;

				ods pdf startpage=now;
					ods pdf text="^{style [just=center font_face=calibri fontsize=14pt]Manner of Death: County Totals ^{newline}}";
				ods proclabel="Manner of Death: County";				

				PROC TABULATE
							data=CoronersCountdf format=best5. ;
								where CertifierOfficeName = "&&CertifierOfficeName&i";
									var coronerN natural accident Homicide Suicide Undetermined Pending;
									class  CertifierOfficeName Monthf /	ORDER= DATA;
										label certifierofficename='Coroner';
										keylabel sum='Total' pctsum='%';
									table Monthf='Month' all="Total YTD",
											(coronerN={label="Coroner Certified"} *(sum ))
											(Natural={label="Natural"}* (sum pctsum<coronerN> *f=pctfmt. ))
											(Accident={label="Accident"}* (sum pctsum<coronerN> *f=pctfmt. ))
											(Homicide={label="Homicide"}* (sum pctsum<coronerN> *f=pctfmt. ))
											(Suicide={label="Suicide"}* (sum pctsum<coronerN> *f=pctfmt. ))
											(Undetermined={label="Undetermined"}* (sum pctsum<coronerN> *f=pctfmt. ))
											(Pending={label="Pending"}* (sum pctsum<coronerN> *f=pctfmt. ));
						RUN;

		ods pdf close;
	%end;
%mend mecountyreport;


/* Report Macro */
/*create loop for macro*/

proc Sort data=coronerscountdf(where=(coronerN ne 0)) out=loop (keep=CertifierOfficeName) nodupkey;
	by CertifierOfficeName;
where coronern ne 0; 
run;


data _null_;
	set loop end=eof;
	call symputx(cats('CertifierOfficeName',_n_),CertifierOfficeName);
	if eof then call symputx('numcoron',_n_);
run;

/*run macro for report*/
%mecountyreport;


/*clean up options */
title; 
ods results=on; 
ods html; 
