


**********************************************************************************************;
***** MACRO SET UP																			  ;
*********************************************************************************************/;

/************* 	Macro Set Up *****************************************/
*Macro program to sort dataset by variable;
%macro sort (v1,v2);

	proc Sort data=&v1;
		by &v2;
	run;

%mend sort;

*Macros to query the data in 5 different ways;
%macro question1(issue,equals,value);
	if &value=&equals then do;
		issue=&issue;
		value=&value;
		output;
	end;
%mend question1;

%macro question2(issue,equals,value);
	if &value in (&equals) then do;
		issue=&issue;
		value=&value;
		output;
	end;
%mend question2;

%macro question3(issue,equals,value);
	if &value ne &equals then do;
		issue=&issue;
		value=&value;
		output;
	end;
%mend question3;

%macro question4(issue,equals,value);
	if &value not in (&equals) then do;
		issue=&issue;
		value=&value;
		output;
	end;
%mend question4;

%macro question5(issue,value,num,op,comp);
	if &value not in (' ','?') then do;
		if input(&value,&num)&op&comp then do;
			issue=&issue;
			value=&value;
			output;
		end;
	end;
%mend question5; 


/*Sorts all relevant datasets to prep for merge to new dataset*/
%sort(birth.birth&dsn,certnum);
%sort(birth.birthid&dsn,certnum);
%sort(birth.birthd&dsn,certnum);
%sort(birth.codes&dsn,certnum);


/*Creates *merge1* dataset from backend data to format and query*/
DATA merge1 
		(keep= certnum facname factype mfname mmlname mlname matmedrec cfname clname dob childmedrec pnv pnvfirst 
		prenatalcare monthcarebegan lmpdate alivenow deadnow plurality birthorder terminationnum sex cahypospad priorweight 
		deliveryweight matage matdob childalive bwgr deathdate issue value MEduc EstGest newvalue 
		absdate lastlivebirth lasttermination timeob motherheight lastlivebirth lasttermination DeathCert paymenttype otherpaymenttype 
		mssn facstate mathepscreen);
length issue value newvalue $150;
		Issue= " ";
		Value= " ";
		NewValue= " ";
		absdate=today(); 
		informat issue value newvalue $150. absdate mmddyy10.;
		format issue value newvalue $150. absdate mmddyy10.;	
merge birth.birth&dsn(in=ina) birth.birthid&dsn birth.birthd&dsn birth.codes&dsn;
		by certnum;
		if ina; 
	
RUN;

%sort(birth.comments&dsn,certnum);
/****Transposes the comments and merges the comments with the merge1 dataset****/
/* Create a sequence number for each comment within certnum */
data comments_with_seq;
    set birth.comments&dsn;
    by certnum;
    if first.certnum then seq = 0;
    seq + 1;
run;

/* Determine the maximum number of comments per certnum */
proc sql noprint;
    select max(seq)
    into :max_comments
    from comments_with_seq;
quit;

/* Transpose the comments dataset with the prefix option */
proc transpose data=comments_with_seq out=trans_comments(drop=_name_) prefix=hospcom_;
    by certnum;
    var hospcom;
    id seq;
run;

/* Define the macro to dynamically generate the list of columns and merge */
%macro merge_comments(max_comments);
    %let columns = ;
    %do i = 1 %to &max_comments;
        %let columns = &columns, b.hospcom_&i;
    %end;

    proc sql;
        create table merge2 as
        select a.* &columns
        from merge1 as a
        left join trans_comments as b
        on a.certnum = b.certnum;
    quit;
%mend merge_comments;

/* Call the macro to perform the merge */
%merge_comments(&max_comments);



DATA att /*Makes att dataset from backend attendant dataset*/
		(drop=cattendanttypeid rename=(cid=Certifier cname=CertifierName));
		informat cid $12.; format cid $12.;
		informat cname $103.; format cname $103.;
	set birth.attendant;
RUN; 

data admin&dsn; 
set birth.admin&dsn; 
informat Certifier $12.; format Certifier $12.;
run; 

%sort(att,certifier);/*Sorts for Merge*/
%sort(admin&dsn,certifier);

 /*Merges certifers/attendants with backend birth admin dataset*/
proc sql; 
create table merge3 as
select a.certifier, a.certnum, a.statefiledate, a.voiddate, b.certifiername
from admin&dsn as a
inner join att as b
on strip(a.certifier) = strip(b.certifier); 
quit;

/*merge everything together */
proc sql; 
create table merged as
select *
from merge3 as a 
full join merge2 as b
on a.certnum = b.certnum; 
quit; 

data merged; 
set merged; 
where voiddate in (' '); 
run; 


**********************************************************************************************;
***** DATA CLEANING 																		  ;
*********************************************************************************************/;

data ready;
    set merged;

    /* Convert StateFileDate to date format */
    if missing(StateFileDate) then do;
		delete; 
		end; 
	else do; newStateFileDate = input(StateFileDate, anydtdte32.);
        format newStateFileDate mmddyy10.;
    end;

    /* Convert matage to numeric */
    if matage not in ('?', ' ') then do;
        momage = input(matage, 2.);
    end;
    else momage = .;


    /* Extract year of birth from matdob */
    if not missing(matdob) and matdob not in ('?', ' ') then do;
        matyob = input(substr(matdob, 1, 4), 4.);
    end;
    else matyob = .;

	    /* Convert alivenow to numeric */
    if not missing(alivenow) and alivenow not in ('?', ' ') then do;
        prevalive = input(alivenow, 2.);
    end;
    else prevalive = 0;

    /* Convert deadnow to numeric */
    if not missing(deadnow) and deadnow not in ('?', ' ') then do;
        prevdead = input(deadnow, 2.);
    end;
    else prevdead = 0;

    /* Convert terminationnum to numeric */
    if not missing(terminationnum) and terminationnum not in ('?', ' ') then do;
        prevterm = input(terminationnum, 2.);
    end;
    else prevterm = 0;
	
    /* Convert bwgr to numeric */
    if not missing(bwgr) and bwgr not in (' ', '?') then do;
        newbwgr = input(bwgr, 5.);
        format newbwgr 5.;
    end;
    else newbwgr = .;

    /* Convert estgest to numeric */
    if not missing(estgest) and estgest not in (' ', '?') then do;
        newestgest = input(estgest, 2.);
        format newestgest 2.;
    end;
    else newestgest = .;

    /* Convert deliveryweight to numeric */
    if not missing(deliveryweight) and deliveryweight not in (' ', '?') then do;
        newdeliveryweight = input(deliveryweight, 5.);
        format newdeliveryweight 5.;
    end;
    else newdeliveryweight = .;

    /* Convert priorweight to numeric */
    if not missing(priorweight) and priorweight not in (' ', '?') then do;
        newpriorweight = input(priorweight, 4.);
        format newpriorweight 4.;
    end;
    else newpriorweight = .;
	
    if newpriorweight ne . and newdeliveryweight ne . then do;
        wtchange = newdeliveryweight - newpriorweight;
    end;
    else wtchange = .;
	        format wtchange 5.;
run; 

data ready; 
set ready;

	facname=propcase(facname);
	CFName=propcase(CFName);
	CLName=propcase(CLName);
	MFName=propcase(MFName);
	MLName=propcase(MLName);
	MMLName=propcase(MMLName);
	CertifierName=propcase(CertifierName);
	label 
		Certnum="Cert Num"
		facname="Facility"
		CertifierName="Certifier"
		newStateFileDate="Date Filed"
		absdate="Date Queried"
		ChildMedRec="Child Record"
		CFName="Child First"
		CLName="Child Last"
		DOB="Date of Birth"
		sex="Sex"
		MatMedRec="Mother Record"
		MFName="Mother First"
		MLName="Mother Last"
		MMLName="Mother Maiden"
		matdob="Mother DOB"
		issue="Issue with Record"
		value="Original Data Entered"
		NewValue= "Updated Data to Enter";
RUN;


**********************************************************************************************;
***** DATA FILTER	 																		  ;
*********************************************************************************************/;

DATA YTD;
	set ready; 
	where facstate in ('Colorado'); 
RUN;

data filtered; 
set YTD; 
where newStateFileDate > &prevreport; 
run; 

