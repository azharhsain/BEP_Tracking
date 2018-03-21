/*********************************************************************
Project: BEP

Purpose: Tracking midline household and business surveys productivity

Author:  Azhar Hussain

Date  :  17 July, 2015
**********************************************************************/



* OPENING COMMANDS

	clear all
	capture log close
	set logtype text
	set linesize 200
	set more off
	pause on
	version 12.0
	cap log close
	
	local REPORT_DATE "11Oct2015"  //Date of the survey being tracked is to be updated before running the code


* AUTOMATED SELECTION OF ROOT PATH BASED ON USER

	if c(os) == "Windows" {
    cd "C:/Users/`c(username)'/Dropbox"
	}
	else if c(os) == "MacOSX" {
		cd "/Users/`c(username)'/Dropbox"
	}
	local DROPBOX `c(pwd)'
	if "`c(username)'" == "nryan" {
	  local DROPBOX_ROOT "`DROPBOX'/BEP Midline Survey Data"
	}
	else {
	  local DROPBOX_ROOT "`DROPBOX'/BEP Midline Survey Data"
	}	
	local ROOT  "S:"
	local TDATE =  subinstr("$S_DATE"," ","",.)
	local RAW_DATA   "`ROOT'/Raw Data"
	local WORKING_DATA  "`DROPBOX_ROOT'/Working Data/`TDATE'"
	local SURVEY_TRACK "`DROPBOX_ROOT'/Tracking sheet/"
	local OUTPUT  "`DROPBOX_ROOT'/Output/`TDATE'/Survey Productivity"


/* TRACKING OVERALL PRODUCTIVITY OF HOUSEHOLD & BUSINESS SURVEY ATTEMPTS

	******HOUSEHOLD*******

	cd "`WORKING_DATA'"
	use CUMULATIVE_HH_`REPORT_DATE'
	
	histogram start_date, freq discrete fcolor(blue) width(1) xtitle(Date, height(6)) ///
	ytitle(Number of Surveys, height(6)) aspectratio(.4) ylabel(0 (25) 150, labsize(small)) xsize(20) ysize(12) ///
	tlabel(24jul2015 (4) 10sep2015, labsize(small) angle(45)) title("{bf:Household Surveys Per Day}") yline(100, lcolor(red) lpattern(dash))
	cd "`OUTPUT'"
	graph export Household_Survey_Attempts_per_day_`REPORT_DATE'.pdf, replace
	clear
	
	******BUSINESS*******

	cd "`WORKING_DATA'"
	use CUMULATIVE_BIZ_`REPORT_DATE'
	
	histogram start_date, freq discrete fcolor(purple) width(1) xtitle(Date, height(6)) ///
	ytitle(Number of Surveys, height(6)) aspectratio (.4) ylabel(0 (10) 50, labsize(small)) xsize(20) ysize(12) ///
	tlabel(24jul2015 (4) 10sep2015, labsize(small) angle(45)) title ("{bf:Business Surveys Per Day}") yline(30, lcolor(red) lpattern(dash))
	cd "`OUTPUT'"
	graph export Business_Survey_Attempts_per_day_`REPORT_DATE'.pdf, replace
	clear
	
	
* TRACKING DISTRICTWISE NUMBER OF HOUSEHOLD & BUSINESS SURVEYS ATTEMPTED WITH STATUS CODES

	******HOUSEHOLD*******

	cd "`WORKING_DATA'"
	use CUMULATIVE_HH_`REPORT_DATE'
	
	//Standardize Spelling of District Names
	replace district="Chapra" if village_id1==3 
	replace district="Katihar" if village_id1==4
	replace district="Purnea" if village_id1==5
	replace district="Siwan" if village_id1==6
	
	tabulate survey_status, generate(ss)
	
	graph bar (mean) ss1 ss2 ss3 ss4 ss5, over(district) percent ///
	legend (label(1 "{bf:Complete}") label(2 "{bf:Respondent completely unavailable}") label(3 "{bf:Did not consent}") ///
	label(4 "{bf:Refused to complete survey midway}") ///
	label(5 "{bf:HH/B not found}") size(small) symxsize(*.2) bmargin(top)) ///
	ytitle(Percentage of Households (%)) ylabel(0 (10) 100, labsize(small)) yscale(titlegap(*8)) ///
	title("{bf:District-wise Household Survey Status}") ///
	xsize(20) ysize(12) aspectratio(0.4)
	cd "`OUTPUT'"
	graph export Districtwise_Household_Survey_Status_`REPORT_DATE'.pdf, replace
	clear
	
	******BUSINESS*******

	cd "`WORKING_DATA'"
	use CUMULATIVE_BIZ_`REPORT_DATE'
	
	//Standardize Spelling of District Names
	replace district="Chapra" if village_id1==3 
	replace district="Katihar" if village_id1==4
	replace district="Purnea" if village_id1==5
	replace district="Siwan" if village_id1==6
	
	tabulate survey_status, generate(ss)
	
	graph bar (mean) ss1 ss2 ss3 ss4 ss5, over(district) percent ///
	legend (label(1 "{bf:Complete}") label(2 "{bf:Left Village/Market}") label(3 "{bf:Respondent completely unavailable}") ///
	label(4 "{bf:Did not consent}") label(5 "{bf:HH/B not found}") size(small) symxsize(*.2) bmargin(top)) ///
	ytitle(Percentage of Businesses (%)) ylabel(0 (10) 100, labsize(small)) yscale(titlegap(*8)) ///
	title("{bf:District-wise Business Survey Status}") ///
	xsize(20) ysize(12) aspectratio(0.4)
	cd "`OUTPUT'"
	graph export Districtwise_Business_Survey_Status_`REPORT_DATE'.pdf, replace
	clear
	

* TRACKING NUMBER OF HOUSEHOLD & BUSINESS SURVEYS ATTEMPTED BY EACH SURVEYOR

	******HOUSEHOLD*******

	cd "`WORKING_DATA'"
	use CUMULATIVE_HH_`REPORT_DATE'
	
	preserve
	drop if surveyor_code>150 | surveyor_code<111
	histogram surveyor_code, freq discrete fcolor(blue) width(1) start(101) xtitle(Surveyor, height(6)) ///
	ytitle(Number of Surveys, height(6)) aspectratio(.35) ylabel(0 (25) 175, labsize(small)) ///
	tlabel(111 (1) 150, labsize(small) angle(vertical)) xsize(20) ysize(10) ///
	title("{bf:Household Surveyor Productivity}")
	cd "`OUTPUT'"
	graph export Household_Surveyor_Productivity_`REPORT_DATE'.pdf, replace
	restore
	clear
	
	******BUSINESS*******

	cd "`WORKING_DATA'"
	use CUMULATIVE_BIZ_`REPORT_DATE'
	
	preserve
	drop if surveyor_code>110 | surveyor_code<101
	histogram surveyor_code, freq discrete fcolor(purple) width(1) start(101) xtitle(Surveyor, height(6)) ///
	ytitle(Number of Surveys, height(6)) aspectratio(.35) ylabel(0 (20) 100, labsize(small)) ///
	tlabel(101 (1) 110, labsize(small) angle(vertical)) xsize(20) ysize(10) ///
	title ("{bf:Business Surveyor Productivity}")
	cd "`OUTPUT'"
	graph export Business_Surveyor_Productivity_`REPORT_DATE'.pdf , replace
	restore	
	clear

	
* TRACKING NUMBER OF SURVEYS AND BACKCHECKS ATTEMPTED BY EACH SURVEYOR PER DAY

	//Survey
	cd "`WORKING_DATA'"
	use CUMULATIVE_HH_`REPORT_DATE'
	preserve
	keep surveyor_code supervisor_code start_date report_dt
	append using CUMULATIVE_BIZ_`REPORT_DATE'
	drop if surveyor_code>155 | surveyor_code<100
	keep if report_dt==start_date
	histogram surveyor_code, freq discrete fcolor(cranberry) width(1) start(101) xtitle(Surveyor, height(6)) ///
	ytitle(Number of Surveys, height(6)) aspectratio(.35) ylabel(0 (1) 10, labsize(small)) ///
	tlabel(101 (1) 155, labsize(small) angle(vertical)) xsize(20) ysize(10) ///
	title("{bf:Surveyor Daily Productivity}") yline(5, lcolor(red) lpattern(dash))
	cd "`OUTPUT'"
	graph export Surveyor_Daily_Productivity_`REPORT_DATE'.pdf, replace
	restore
	clear

	//Backcheck
	cd "`WORKING_DATA'"
	use CUMULATIVE_HH_BC_`REPORT_DATE'
	preserve
	keep backchecker_code start_date report_dt
	append using CUMULATIVE_BIZ_BC_`REPORT_DATE'
	keep if report_dt==start_date
	histogram backchecker_code, freq discrete fcolor(orange) width(1) start(301) xtitle(Backchecker, height(6)) ///
	ytitle(Number of Backchecks, height(6)) aspectratio(.35) ylabel(0 (1) 15, labsize(small)) ///
	tlabel(301 (1) 315, labsize(small)) xsize(20) ysize(10) ///
	title("{bf:Backchecker Daily Productivity}") yline(10, lcolor(red) lpattern(dash))
	cd "`OUTPUT'"
	graph export Backchecker_Daily_Productivity_`REPORT_DATE'.pdf, replace
	restore
	clear
*/
	//Reconciliation
	cd "`WORKING_DATA'"
	use CUMULATIVE_HH_RECON_`REPORT_DATE'
	preserve
	keep reconciliator_code start_date report_dt
	append using CUMULATIVE_BIZ_RECON_`REPORT_DATE'
	keep if report_dt==start_date
	keep if (reconciliator_code>400 & reconciliator_code<405)
	histogram reconciliator_code, freq discrete fcolor(green) width(1) start(401) xtitle(Reconciliator Code, height(6)) ///
	ytitle(Number of Reconciliations, height(6)) aspectratio(.35) ylabel(0 (1) 15, labsize(small)) ///
	tlabel(400 (1) 405, labsize(small)) xsize(20) ysize(10) ///
	title("{bf:Reconciliator Daily Productivity}") yline(10, lcolor(red) lpattern(dash))
	cd "`OUTPUT'"
	graph export Reconciliator_Daily_Productivity_`REPORT_DATE'.pdf, replace
	restore
	clear
