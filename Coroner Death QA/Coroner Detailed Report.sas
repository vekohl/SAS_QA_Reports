
data vk.jeffco2; 
set vk.dfpull; 
where CertifierOfficeName = ('JEFFERSON COUNTY CORONER');
run; 


ods excel file="&output\jeffco detailed.xlsx";
proc print data=vk.jeffco; 
var EDRUniqueIdentifier DOD UnderCauseDeath; 
where illdefined=1; 
title "Ill-Defined Cause of Death";
run;

proc print data=jeffco; 
var EDRUniqueIdentifier DOD UnderCauseDeath causeliteral1 causeliteral2 causeliteral3; 
where illdefined=1; 
title "Ill-Defined Cause of Death with Literals";
run;
ods excel close; 

ods results; clear;
