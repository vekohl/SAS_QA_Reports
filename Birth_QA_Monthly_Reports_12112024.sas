
**********************************************************************************************;
***** MAIN NCHS QUERY																		  ;
*********************************************************************************************/;

data queried;
	set filtered;

/* Birth Weight Check 																		*/
/*	Identifies & flags records where the birth weight (newbwgr) exceeds 5896 grams 			*/

	if newbwgr ne . and newbwgr gt 5896 /*< 5896 grams is 13#s > */
	then do;
		issue="Birth weight high";
		value=catt("Baby Birth Weight: ",newbwgr); 
		output;
	end;

/* Gestational Age and Birth Weight Correlation:											*/
/*Flags combinations of gestational age and birth weight that are biologically improbable	*/
	if newbwgr ne . and newestgest ne . AND (
	(newestgest lt 20 and newbwgr ge 1000) /*Gestation  20 + bw > 1000g*/
	OR (newestgest in (20:23) and newbwgr ge 2000) /*Gestation 20-23 + bw > 2000g*/
	OR (newestgest in (24:27) and	newbwgr ge 3000) /*Gestation 24-27 + bw > 3000g*/
	OR (newestgest in (28:31) AND newbwgr ge 4000) /*Gestation 28-31 + bw > 4000g*/
		)
	then do;
		issue='Birth weight/gestation';
		value=cat("Est Gestation: ",newestgest," /"," Baby Birth Weight: ",newbwgr);
		output;
	end;

/*Estimated gestation improbable: 															*/
/*Identifies & flags gestation longer than 42 weeks											*/
	if newestgest ne . AND newestgest gt 42 
	then do; 
		issue="Gestation Long";
		value=cat("Gestation: ",newestgest, " weeks");
		output; 
	end; 

*Identifies & flags gestation shorter than 17 weeks							*;
	if newestgest ne . AND newestgest lt 17 AND childalive ="Y"
	then do; 
		issue="Gestation Short";
		value=cat("Gestation: ",newestgest, " weeks");
		output; 
	end; 

/*Hypospadias & sex: 																		*/
/*Identifies & flags hypospadias(male birth defect) and female sex           				*/
	if sex='F' AND cahypospad='True' 
	then do; 
			issue='hypospadias/sex';
			value=cat("Hypospadias & ",sex); 
		output; 
	end;

*Maternal Age; 
	*Age > 55 or < 11;
		if momage ne . AND
			(momage ge 55 OR
			momage le 11)
		then do; 
			issue="Maternal Age";
			value=cat("Maternal Age: ",momage);
			output; 
		end; 

	*Age compared to last live birth (10 years);
		if lastlivebirth not in (' ','?') AND matyob ne . 
		then do;
			if input(substr(lastlivebirth,1,4),4.)-matyob<11 
			then do;
				issue='Last live birth year/maternal age';
				value=cat("Date of Last Birth: ",lastlivebirth, "Mom Current Age: ",momage);
				output;
			end;
		end;


	*Age compared to last termination (10 years);
		if lasttermination not in (' ','?') AND matyob ne . 
		then do;
			if input(substr(lasttermination,1,4),4.)-matyob<11
			then do;
				issue='Last termination year/maternal age';
				value=cat("Date of Last Termination: ",lasttermination, "Mom Current Age: ",momage);
				output;
			end;
		end;

/*Previous #s 																				*/
	*Live births > 12;
		%question5('Number of previous births',alivenow,2.,>,12); 
	*Deceased > 12;
		%question5('Number of deceased',deadnow,2.,>,12); 
	*Terminations > 12;
		%question5('Number of terminations',terminationnum,2.,>,12); 


/*Weight Mother																				*/
	*PrePregancy Weight < 75 or > 400;
		if newpriorweight ne . AND 
			(newpriorweight le 75 OR 
			newpriorweight ge 350)
		then do; 
			issue='Prior Weight';
			value=cat("Maternal Prior Weight: ",newpriorweight);
			output; 
		end;

	*Delivery Pregancy Weight < 75 or > 400;
		if newdeliveryweight ne . AND 
			(newdeliveryweight le 75 OR
			newdeliveryweight ge 400)
		then do; 
			issue='Delivery Weight';
			value=cat("Maternal Delivery Weight: ",newdeliveryweight);
			output; 
		end;

	*Lost weight during pregancy > 50; 
		if wtchange ne . AND WtChange le -50 
		then do; 
			issue='Weight Lost > 50';
			value=catt("Maternal Wt Change: ",wtchange," Prior Wt: ",newpriorweight," Delivery Wt: ",newdeliveryweight);
			output; 
		end;
	*Gained weight during pregancy > 100; 
		if wtchange ne . AND WtChange ge 100 
		then do; 
			issue='Weight Gained > 100';
			value=catt("Maternal Wt Change: ",wtchange," Prior Wt: ",newpriorweight," Delivery Wt: ",newdeliveryweight);
			output; 
		end;
*Mother's Height; *Height > 7' or  < 3'; 
	%question2('Maternal height','03:09' '03:10' '03:11' '07:00' '07:01' '07:02' '07:03',motherheight);


/*Mother Age vs Education																	*/
	*9-12 grade + mother's age > 9;
	if momage ne . and (
		(momage le 9 and meduc in ('2','3','4','5','6','7')) 
		OR (momage le 16 and meduc in ('3','4','5','6','7')) 
		OR (momage le 17 and meduc in ('4','5','6','7')) 
		OR (momage le 18 and meduc in ('5','6','7'))  
		OR (momage le 20 and meduc in ('6','7')) 
		OR (momage le 21 and meduc in ('7')))
	then do; 
		issue='Maternal age/education';
		value=cat("Mom Age: ",momage, " Mom Ed: ", meduc);
		output;
	end;

*Prenatal care dates RE: NCHS;
	*Checks for matching data:;
		if prenatalcare in ('N','U') and monthcarebegan in ('1','2','3','4','5','6','7','8','9') 
		then do;
			issue='Prenatal care/month care began mismatch';
			value=cat("PNC: ",prenatalcare," / ","Month PNC Began: ",monthcarebegan);
			output;
		end;

		if prenatalcare='N' and pnv not in ('0',' ') 
		then do;
			issue='Prenatal Care Mismatch';
			value=cat("PNC: ",prenatalcare, " PNC Visits: ", pnv); 
			output; 
		end; 

		if (prenatalcare='N' or pnv in ('0',' ')) and (substr(pnvfirst,1,2)='&pdsn' or substr(pnvfirst,1,2)='&dsn') 
		then do; 
			issue="Prenatal care info mismatch";
			value=cat("PNC: ",prenatalcare, " PNC Visits: ", pnv);
			output; 
		end; 

*Unknown/Missing Fields;
		if newbwgr = . then do; 
			issue="Missing birth weight";
			value="n/a";
			output;
		end; 

	%question1('Time of birth missing/unknown',' ',timeob);	*Time of Birth; 
	%question4('Baby Sex','M' 'F',sex);	*Sex; 
	%question1('Facility missing',' ',facname);*Facility Name; 

run;

**********************************************************************************************;
***** REPORT PREPARATION																	  ;
*********************************************************************************************/;
 
data queriedfinal
	(keep=facname certifiername  
		childmedrec cfname clname dob sex 
		matmedrec mlname mmlname certnum
		issue value newvalue 
		hospcom_1 hospcom_2 hospcom_3);
	retain 
		facname certifiername  
		childmedrec cfname clname dob sex 
		matmedrec mlname mmlname certnum
		issue value newvalue 
		hospcom_1 hospcom_2 hospcom_3;
set queried; 
run; 


data facility;
	set queriedfinal;
if issue='Facility missing' then
		facname="Facility Missing";
run;

goptions reset=goptions;
goptions device=png;

*Creates temp df with facilities included in the queried data;
proc Sort data=queriedfinal out=loop (keep=facname) nodupkey;
	by facname;
run;

*Creates macro variables based on previously created df;
data _null_;
	set loop end=eof;
	call symputx(cats('facname',_n_),facname);
	if eof then call symputx('numfac',_n_);
run;

**********************************************************************************************;
***** MAIN REPORT CREATION ON FACILITY LOOP													  ;
*********************************************************************************************/;
%macro facilityreportloop; 
	%do i = 1 %to &numfac; 
				ods excel file = "&outputfile\&&facname&i &filedate QA.xlsx"
						options (absolute_column_width='30, 23, 13, 13, 17, 8, 5, 13, 15, 15, 18, 30, 30, 15, 50, 40, 40'
						embedded_titles="yes"
						hidden_columns= '1'
						sheet_name="&sheetname");
					proc report data=facility;
						where facname="&&facname&i"; 
						title "&&facname&i Report";
								define facname / 'Facility Name' style(column)=data[width=1000% tagattr='wrap:no'];
								define certifiername/ 'Certifier'  style(column)=data[width=1000% tagattr='wrap:no'];
								define CFName/ 'Child First'  style(column)=data[width=1000% tagattr='wrap:no'];
								define CLName/ 'Child Last'  style(column)=data[width=1000% tagattr='wrap:no'];
								define DOB / 'DOB' style(column)=data[width=1000% tagattr='wrap:no'];
								define Sex/ 'Sex'  style(column)=data[width=1000% tagattr='wrap:no'];
								define MLName/ 'Mother Last'  style(column)=data[width=1000% tagattr='wrap:no'];
								define MMLName/ 'Mother Maiden'  style(column)=data[width=1000% tagattr='wrap:no'];
								define Issue/ 'Issue with Record'  style(column)=data[width=1000% tagattr='wrap:no'];
								define value/ 'Original Data Entered'  style(column)=data[width=1000% tagattr='wrap:no'];
								define newvalue/ 'New Data To Enter' style(column)=[backgroundcolor=lightyellow];
								define hospcom_1/ 'Hospital Comment1'  style(column)=data[width=1000% tagattr='wrap:yes height=50px'];
								define hospcom_2/ 'Hospital Comment2'  style(column)=data[width=1000% tagattr='wrap:yes'];
								define hospcom_3/ 'Hospital Comment3'  style(column)=data[width=1000% tagattr='wrap:yes'];
					run; 
				ods excel close;
	%end; 
%mend facilityreportloop; 

%facilityreportloop;

**********************************************************************************************;
***** OTHER PAYMENT TYPE REPORT																  ;
*********************************************************************************************/;

/* Extract Records with Non-standard Payment Types */
data pay (keep= certnum facname CLName paymenttype otherpaymenttype notes);
	set filtered;
	where otherpaymenttype ne ' ';
	notes=" ";  /* Initialize notes field for reviewer comments */
run;


/* Prepare Data for Reporting */
DATA payment; 
	retain  facname clname certnum otherpaymenttype notes;
	set pay;
RUN;

%sort(payment,otherpaymenttype) 
goptions reset=goptions;
goptions device=png; title; 

/* Generate and Format the Excel Report */
ods excel file = "&outputfile\Other Payment &filedate Report.xlsx"
options (absolute_column_width= '35, 25, 15, 50, 50'
			embedded_titles="yes"
			sheet_name="&sheetname");

	proc report data=payment;
	title "Other Payments";
	define facname / 'Facility Name' style(column)=data[width=100% tagattr='wrap:no'];
	define CLName/ 'Child Last Name'  style(column)=data[width=100% tagattr='wrap:no'];
	*define paymenttype/ 'Payment Type'  style(column)=data[width=100% tagattr='wrap:no'];
	define certnum/ 'Cert Number'  style(column)=data[width=100% tagattr='wrap:no'];
	define otherpaymenttype / 'Payment Notes' style(column)=data[width=100% tagattr='wrap:no'];
	define notes / 'New Notes' style(column)=data[width=100% tagattr='wrap:no'];
run; 

ods excel close;

**********************************************************************************************;
***** MOTHER SSN DUPLICATE REPORT															  ;
*********************************************************************************************/;

/* Find & Create Dataset with MSSN Duplicates*/
	proc freq data=YTD noprint;
	where mssn not in (' ','?','999-99-9999');
	tables mssn / nocum nopct out=mssnfreq (keep=mssn count where=(count >1));
	run;

/* Merge with Original Data & Check for Plurality Discrepancies*/
	proc sql;
	    create table dup_ssn as
	    select b.*, a.count as ssn_count
	    from mssnfreq as a
	    inner join YTD as b
	    on a.mssn = b.mssn
	    where a.count ne input(b.plurality, 2.);
	quit;


data dup_ssn; 
set dup_ssn; 
where mssn not in ('237-41-7193', '305-95-4553','332-04-6502');
run;

 
/* Format and Create Report*/

	data dup_ssn
			(keep= facname cfname clname dob plurality mfname mlname mmlname matdob certnum mssn notes); 
		retain facname cfname clname dob plurality mfname mlname mmlname matdob certnum mssn notes; 
		set dup_ssn;
		notes=" ";
	run;

	goptions reset=goptions;

	%sort(dup_ssn,mssn);

	goptions device=png;
	ods excel file = "&outputfile\MSSN Dupe &filedate Report.xlsx"
	options (absolute_column_width='35, 13, 18, 10, 8, 13, 18, 18, 10, 15, 12, 25, 35'
			embedded_titles="yes"
			sheet_name="MSSN Duplicates YTD");

	proc report data=dup_ssn;
	title "Mother SSN Duplicates/Plurality Mismatches";
		define facname/ 'Facility'  style(column)=data[width=1000% tagattr='wrap:no'];
		define CFName/ 'Child First'  style(column)=data[width=1000% tagattr='wrap:no'];
		define CLName/ 'Child Last'  style(column)=data[width=1000% tagattr='wrap:no'];
		define DOB / 'DOB' style(column)=data[width=1000% tagattr='wrap:no'];
		define Plurality/ 'Pluraility'  style(column)=data[width=1000% tagattr='wrap:no'];
		define MFName/ 'Mom First'  style(column)=data[width=1000% tagattr='wrap:no'];
		define MLName/ 'Mom Last'  style(column)=data[width=1000% tagattr='wrap:no'];
		define MMLName/ 'Mom Maiden'  style(column)=data[width=1000% tagattr='wrap:no'];
		define matDOB / 'Mom DOB' style(column)=data[width=1000% tagattr='wrap:no'];
		define certnum/ 'Cert Number'  style(column)=data[width=1000% tagattr='wrap:no'];
		define MSSN / 'Mom SSN' style(column)=data[width=1000% tagattr='wrap:no'];
		define notes / 'Notes' style(column)=data[width=1000% tagattr='wrap:no'];
	run; 
	ods excel close;
