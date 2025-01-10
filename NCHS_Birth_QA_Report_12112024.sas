*********************************************************************************************;
*                                  BIRTH QA MASTER PROGRAM                                  *;
*-------------------------------------------------------------------------------------------*;
* This top-level SAS program runs Birth QA sub-programs.                                    *;                                             ;
*-------------------------------------------------------------------------------------------*;
* Contact: For questions about this program or generated reports, email                     *;
*          vanessa.kohl@state.co.us                                                         *;
*-------------------------------------------------------------------------------------------*;
* Program Overview:                                                                         *;
* 1. User-Defined Parameters                                                                *;
* 2. Set Up Environment                                                                     *;
*    - Libraries and macros                                                                 *;
* 3. Pull data from the backend database                                                    *;
*    - Clean data for analysis                                                              *;
* 4. Query and Report                                                                       *;
*    - Monthly Reports                                                                      *;
*    - Quarterly Reports                                                                    *;
* 5. Clear Workspace                                                                        *;
*********************************************************************************************;

*********************************************************************************************;
***** 1. USER-DEFINED PARAMETERS                            				                *;
*********************************************************************************************;

/******* Report Filter *******/;
/* Last Run: 10/1 - 12/11 */;
%let prevreport = '11DEC2024'd; 
%let sheetname = Filed since Dec 11;

/* DataSetName = DSN = Year + Previous*/
%let pdsn=23; 
%let dsn=24; 

*********************************************************************************************;
***** 2. LIBRARY SET UP & SUBPATH FOLDER LOCATION  							                *;
*********************************************************************************************;

/* Library Set Up */
libname BIRTH base "W:\birth\sas";  run;

/* File Paths */
%let subpath = V:\VITAL RECORDS\Program Support\RDI Unit\Statistical Analyst\SAS Programs\Current Programs\Quality Assurance Reports\NCHS Birth QA Report\Subprograms;

**********************************************************************************************;
***** 3. OUT PUT FOLDER CREATION & LOCATION         								         *;
*********************************************************************************************/;

*Creates new dated folder for output automatically based on today's date; 
%let filepath=V:\VITAL RECORDS\Program Support\RDI Unit\QA Analyst Alicia\Birth\NEW 2024; 
%let filedate=%sysfunc(today(),mmddyy6.); 
option dlcreatedir; libname Folder "&filepath\Birth QA for &filedate ";

*Sets newly created folder to output destination;
%let outputfile=V:\VITAL RECORDS\Program Support\RDI Unit\QA Analyst Alicia\Birth\NEW 2024\Birth QA for &filedate; 
goptions device=png;

*********************************************************************************************;
***** 4. DATA PREPARATION       								                            *;
*********************************************************************************************;

/* Run Birth Data Preparation Subprogram */  
%include "&subpath.\Birth_QA_Data_Pull_Clean_12112024.sas";

*********************************************************************************************;
***** 5. MONTHLY BIRTH QA REPORTS     							                            *;
*********************************************************************************************;

/* Generate Monthly QA Reports */
%include "&subpath.\Birth_QA_Monthly_Reports_12112024.sas";

*********************************************************************************************;
***** 6. QUARTERLY BIRTH QA REPORTS    								                        *;
*********************************************************************************************;

/* Generate Quarterly QA Reports (March, June, September, December) */
%include "&subpath.\Birth_QA_Quarterly_Reports_12112024.sas";


*********************************************************************************************;
***** 7. CLEAR SAS WORKSPACE 							                                    *;
*********************************************************************************************;

/* Clear all datasets from the WORK library to free up memory when you are finished */
proc datasets library=work kill; 
run;

