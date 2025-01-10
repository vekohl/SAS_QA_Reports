
/***********************************************************************************************
 Program:     Tableau Data Pull for Birth and Admin Comparison
 Author:      Vanessa Kohl
 Created:     [27-MAR-2024]
 Purpose:     This program pulls data from the `birth` and `admin` datasets, merges relevant 
              information, and prepares a cleaned dataset for Tableau reporting. The final output 
              includes key fields needed for analysis, such as birth details, certifier information, 
              and calculated days between birth and state file date.
              
 Data Sources:
    - `birth.attendant`       : Contains certifier information.
    - `birth.admin&dsn`       : Admin data.
    - `birth.birth&dsn`       : Main birth data.

 Output:
    - A cleaned dataset is exported to CSV for Tableau at:
      `...RDI Unit\Statistical Analyst\SAS Programs\Do Not Delete\DND\z_QAExtracts&dsn YTD.csv`

 Modifications:
    - [04-NOV-2024] - Recovered version.
    - [10-DEC-2024] - Changed output to reflect new file structure.
	- [10-DEC-2024] - Implemented data split based on facility match. 
					Used list provided by Pete in Field Team
					Excel list located Statistical Analyst\SAS_Programs\Do Not Delete\DND\Tableau_Valid_Locations.xlsx
							

 Steps:
    1. Pull standalone copy of certifier data from `birth.attendant`.
    2. Merge certifier data with `birth.admin&dsn` to create `admin` dataset.
    3. Create a copy of `birth.birth&dsn` and keep only required variables.
    4. Merge `birth_data` and `admin` to form `merged_raw`.
    5. Process the merged data to create a cleaned final dataset with calculated fields.
    6. Export the cleaned dataset to CSV.

 Notes:
    - Ensure the connection to the `birth` library is active.
    - Check and update variable formats as needed to avoid truncation.
    - Any additional processing should be documented in the Modifications section.

***********************************************************************************************/

/* Set up library and macros */
libname birth "W:\birth\sas";

%macro sort(var, by);
    proc sort data=&var; by &by; run;
%mend sort;

/* Define year parameter */
%let yr=24;

/* Pull and prepare certifier information */
data attendant 
    (drop=cattendanttypeid rename=(cid=certifier cname=certifiername));
    informat cid $12. cname $103.;
    format cid $12. cname $103.;
    set birth.attendant;
run;

data admin (keep=certnum certifier statefiledate);
    informat certifier $12.; 
    format certifier $12.;
    set birth.admin&yr;
    if strip(certifier) in ('-1000', '.', ' ') then delete;
run;

/* Sort datasets for merging */
%sort(attendant, certifier);
%sort(admin, certifier);

/* Merge certifier data with admin dataset */
proc sql;
    create table mergedadmin as
    select a.certifier, a.certnum, a.statefiledate, b.certifiername
    from admin as a
    left join attendant as b
    on strip(a.certifier) = strip(b.certifier);
quit;

/* Prepare birth data */
data birth 
    (keep=facname facstate certnum dob meduc priorweight motherheight wic prenatalcare pnv pnvfirst lmpdate lasttermination lastlivebirth factype);
    set birth.birth&yr;
    where facstate in ('Colorado');
run;

data birthid 
    (keep=certnum cfname clname childmedrec mfname mlname matmedrec);
    set birth.birthid&yr;
run;

/* Merge datasets */
proc sql;
    create table mergedbirth as
    select a.*, b.*, c.certifier, c.statefiledate, c.certifiername
    from birth as a
    left join birthid as b
    on a.certnum = b.certnum
    left join mergedadmin as c
    on b.certnum = c.certnum;
quit;

/* Clean and process the merged dataset */
data mergedbirth;
    set mergedbirth;
    where factype in ('1','2');
    if certnum in ('2023026649') then delete;

    /* Format fields */
    newStateFileDate=input(StateFileDate,anydtdte32.);
    format newStateFileDate mmddyy10.;
    facname = propcase(facname);
    certifiername = propcase(certifiername);
    newDOB=input(DOB,mmddyy10.);
    format newDOB mmddyy10.;
    cfname = propcase(cfname);
    clname = propcase(clname);
    mfname = propcase(mfname);
    mlname = propcase(mlname);
    certifier= propcase(certifier);

    /* Additional cleaning */
    statefiledays = intck("day", newDOB, newStateFileDate);
    if WIC = "U" then WIC = " " ; 
    if priorweight = "?" then priorweight = " " ; 
    if prenatalcare = "U" then prenatalcare = " " ; 
    if PNV = "U" then PNV = " " ;
run;

/* Finalize cleaned dataset */
data finishedbirth
    (keep=
        facname certnum certifiername dob newdob wic meduc newstatefiledate statefiledays priorweight 
        motherheight wic prenatalcare pnv pnvfirst lmpdate lasttermination lastlivebirth cfname clname 
        childmedrec mfname mlname matmedrec);
    set mergedbirth;
run;


/* Import the Excel file containing valid locations */
proc import 
    datafile="V:\VITAL RECORDS\Program Support\RDI Unit\Statistical Analyst\SAS_Programs\Do Not Delete\DND\Tableau_Valid_Locations.xlsx"
    out=valid_locations
    dbms=xlsx
    replace;
run;

/* Step 2: Divide the finishedbirth dataset into two sections */
proc sql;
    /* Create dataset with valid locations */
    create table valid_finishedbirth as
    select *
    from finishedbirth as fb
    where fb.facname in (select ValidLocation from valid_locations);

    /* Create dataset with invalid locations */
    create table invalid_finishedbirth as
    select *
    from finishedbirth as fb
    where fb.facname not in (select ValidLocation from valid_locations);
quit;

proc sort data=valid_finishedbirth;
    by dob;
run;

/* Export the cleaned dataset to Tableau directory */
PROC EXPORT DATA=valid_finishedbirth 
    OUTFILE= "V:\VITAL RECORDS\Program Support\RDI Unit\Statistical Analyst\SAS_Programs\Do Not Delete\DND\z_QAExtracts&yr YTD.csv" 
    DBMS=CSV REPLACE;
    PUTNAMES=YES;
RUN;

proc freq data=invalid_finishedbirth; 
table facname;
run; 
