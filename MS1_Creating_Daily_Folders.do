/*************************************************************************************************************
Project: BEP

Purpose: Creating folders to store survey data and tracking results of midline household and business surveys

Author:  Azhar Hussain

Date  :  15 July, 2015
**************************************************************************************************************/



* OPENING COMMANDS

	clear all
	capture log close
	set logtype text
	set linesize 200
	set more off
	pause on
	version 12.0
	cap log close
	
	local REPORT_DATE "29Nov2015"  //Date of the survey being tracked is to be updated before running the code


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
	//ssc install truecrypt
	//cd "`DROPBOX_ROOT'"
	//truecrypt BEP_TrueCrypt_20jul15, mount drive(S)
	local ROOT  "S:"
	local TDATE =  subinstr("$S_DATE"," ","",.)
	local RAW_DATA   "`ROOT'/Raw Data"
	local WORKING_DATA  "`DROPBOX_ROOT'/Working Data/`TDATE'"
	local SURVEY_TRACK "`DROPBOX_ROOT'/Tracking sheet/"
	local OUTPUT  "`DROPBOX_ROOT'/Output/`TDATE'"

	
* STARTING TEXT LOG FILE

	local x = c(current_date)
	log using "`DROPBOX_ROOT'//Code logs/MS1. Creating Daily Folders `x'.log", replace    


* MAKING DATED FOLDER FOR WORKING DATA AND OUTPUT

	cd "`ROOT'"
	local tdate = "$S_DATE"

 	//Constructing a text string with today's date
	display "`tdate'"
	local firstword="0"+word("`tdate'",1)
	local middleword = word("`tdate'",2)
	local lastword=word("`tdate'",3)
	local tdate = subinstr("`tdate'"," ","",.)
	display "`tdate'"

	//Creating a dated folder within the "Working Data" folder, which will store de-identified Stata datasets, both daily and cumulative
	cd "`DROPBOX_ROOT'/Working Data"
	!mkdir "`tdate'"

	//Creating a "Backcheck List" folder 
	cd "`DROPBOX_ROOT'//Working Data//`tdate'"
	!mkdir "Backcheck Lists"

	//Creating a dated folder within the "Output" folder, which will store mismatch, duplicate, and tracking files
	cd "`DROPBOX_ROOT'//Output"
	!mkdir "`tdate'"

	//Creating separate folders within the dated folder in "Output" folder
	cd "`DROPBOX_ROOT'//Output//`tdate'"
	!mkdir "Survey Tracking"
	!mkdir "Survey Productivity"
	!mkdir "Survey Quality"
	!mkdir "Survey Backcheck"
	!mkdir "Survey Reconciliation"
	log close
