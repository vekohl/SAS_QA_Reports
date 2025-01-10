
PROC TABULATE
	data=CoronersCountdf out=tabulated_COTotals;
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


PROC TABULATE
	data=CoronersCountdf format=best5. ;
		where CertifierOfficeName = "ADAMS COUNTY CORONER";
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


/* Reshape the data */
data deaths_reshaped;
  set tabulated_COTotals;
  Month = Monthf;
  MannerOfDeath = 'Natural'; Count = Natural_Sum; output;
  MannerOfDeath = 'Accident'; Count = Accident_Sum; output;
  MannerOfDeath = 'Homicide'; Count = Homicide_Sum; output;
  MannerOfDeath = 'Suicide'; Count = Suicide_Sum; output;
  MannerOfDeath = 'Undetermined'; Count = Undetermined_Sum; output;
  MannerOfDeath = 'Pending'; Count = Pending_Sum; output;
run;


data deaths_reshaped3;
  set tabulated_COTotals;
  Total = Natural_Sum + Accident_Sum + Homicide_Sum + Suicide_Sum + Undetermined_Sum + Pending_Sum;
  Natural_PctSum = Natural_Sum / Total * 100;
  Accident_PctSum = Accident_Sum / Total * 100;
  Homicide_PctSum = Homicide_Sum / Total * 100;
  Suicide_PctSum = Suicide_Sum / Total * 100;
  Undetermined_PctSum = Undetermined_Sum / Total * 100;
  Pending_PctSum = Pending_Sum / Total * 100;
  drop Total Natural_Sum Accident_Sum Homicide_Sum Suicide_Sum Undetermined_Sum Pending_Sum;
run;


/* Create stacked bar chart */
proc sgplot data=deaths_reshaped;
  vbar Monthf / response=Count group=MannerOfDeath groupdisplay=stack datalabel;
  yaxis grid;
  xaxis display=(nolabel);
run;
