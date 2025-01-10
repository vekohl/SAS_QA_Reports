

**********************************************************************************************;
***** LOW BIRTH WEIGHT REPORT																  ;
*********************************************************************************************/;

DATA lowbirthweight; 
set YTD; 
	if newbwgr ne . and newbwgr lt 500 and childalive = "Y" /*> 500 grams check if deceased;*/
	then do;
		value=cat("Birth Weight: ",newbwgr);
		output;
	end;
RUN;

DATA lowbirthweight 
		(keep= 
			certnum mmlname mfname matmedrec
			facname certifiername  
			childmedrec cfname clname dob sex 
		 value newvalue 
		hospcom_1 hospcom_2 hospcom_3);
		retain 
		certnum mmlname mfname matmedrec 
		facname certifiername  
		childmedrec cfname clname dob sex 
		value newvalue
		hospcom_1 hospcom_2 hospcom_3;
	set lowbirthweight;
RUN;

%sort(lowbirthweight, facname);

%sort(lowbirthweight,facname)
title; 
goptions reset=goptions;
goptions device=png;

ods excel file = "&outputfile\Low Birth Weight &filedate Report.xlsx"
options (absolute_column_width='18, 18, 13, 13, 33, 23, 18, 13, 18, 10, 5, 25, 25, 25'
		embedded_titles="yes"
		frozen_headers="3"
		frozen_rowheaders="2"
		sheet_name="Low Birth Weight YTD");

proc report data=lowbirthweight;
title "Low Birth Weight Report";
	define certnum/ 'Cert Number'  style(column)=data[width=1000% tagattr='wrap:no'];
	define facname / 'Facility Name' style(column)=data[width=1000% tagattr='wrap:no'];
	define certifiername/ 'Certifier'  style(column)=data[width=1000% tagattr='wrap:no'];
	*define ChildMedRed/ 'Child Medical Record'  style(column)=data[width=1000% tagattr='wrap:no'];
	*define CFName/ 'Child First Name'  style(column)=data[width=1000% tagattr='wrap:no'];
	*define CLName/ 'Child Last Name'  style(column)=data[width=1000% tagattr='wrap:no'];
	 define DOB / 'DOB' style(column)=data[width=1000% tagattr='wrap:no'];
	define Sex/ 'Sex'  style(column)=data[width=1000% tagattr='wrap:no'];
	define MatMedRed/ 'Mother Medical Record'  style(column)=data[width=1000% tagattr='wrap:no'];
	*define mMLName/ 'Mother Maiden Name'  style(column)=data[width=1000% tagattr='wrap:no'];
	define value/ 'Original Data Entered'  style(column)=data[width=1000% tagattr='wrap:no'];
	define HospCom/ 'Hospital Comments'  style(column)=data[width=1000% tagattr='wrap:no'];
	define newvalue/ 'New Data To Enter' style(column)=[backgroundcolor=lightyellow];

run; 
ods excel close;

**********************************************************************************************;
***** BIRTH & DEATH DATA LINKAGE REPORT														  ;
*********************************************************************************************/;

DATA bdlink; 
set YTD; 

*Child Alive + Death Certification; 
	if childalive NE "Y" and deathcert=" "
	then output; 
run; 

data bdlink
	(keep= 
		certnum mmlname mfname matmedrec 
		facname certifiername  
		childmedrec cfname clname dob sex 
		childalive deathcert newvalue 
		hospcom_1 hospcom_2 hospcom_3);
	retain 
		certnum mmlname mfname matmedrec 
		facname certifiername  
		childmedrec cfname clname dob sex
		childalive deathcert newvalue 
		hospcom_1 hospcom_2 hospcom_3;
	set bdlink;
run;

%sort(bdlink,facname)
title; 
goptions reset=goptions;
goptions device=png;
ods excel file = "&outputfile\Birth Death Link &filedate Report.xlsx"
options (absolute_column_width='13, 18, 13, 15, 30, 18, 15, 13, 18, 10, 5, 5, 25, 75'
		absolute_row_height='15'
		embedded_titles="yes"
		frozen_headers="4"
		frozen_rowheaders="2"
		sheet_name="Records YTD");

proc report data=bdlink;
title "Birth & Death Record Inconsistencies";
title2 "Child Alive: *T* & No Death Date/Cert#";
	*define certnum/ 'Cert Number'  style(column)=data[width=1000% tagattr='wrap:no'];
	define facname / 'Facility Name' style(column)=data[width=1000% tagattr='wrap:no'];
	define certifiername/ 'Certifier'  style(column)=data[width=1000% tagattr='wrap:no'];
	*define ChildMedRed/ 'Child Medical Record'  style(column)=data[width=1000% tagattr='wrap:no'];
	define CFName/ 'Child First'  style(column)=data[width=1000% tagattr='wrap:no'];
	define CLName/ 'Child Last'  style(column)=data[width=1000% tagattr='wrap:no'];
	 define DOB / 'DOB' style(column)=data[width=1000% tagattr='wrap:no'];
	define Sex/ 'Sex'  style(column)=data[width=1000% tagattr='wrap:no'];
	define childalive/ 'Child Alive?'  style(column)=data[width=1000% tagattr='wrap:no'];
	define deathcert/ 'Death Cert Number'  style(column)=data[width=1000% tagattr='wrap:no'];
	*define MatMedRed/ 'Mother Medical Record'  style(column)=data[width=1000% tagattr='wrap:no'];
	define MFName/ 'Mother First'  style(column)=data[width=1000% tagattr='wrap:no'];
	*define MMLName/ 'Mother Maiden Name'  style(column)=data[width=1000% tagattr='wrap:no'];
	*define Issue/ 'Issue with Record'  style(column)=data[width=1000% tagattr='wrap:no'];
	*define value/ 'Original Data Entered'  style(column)=data[width=1000% tagattr='wrap:no'];
	define newvalue/ 'Notes' style(column)=[backgroundcolor=lightyellow];
	define HospCom/ 'Hospital Comments'  style(column)=data[width=1000% tagattr='wrap:no'];
run; 
ods excel close;




