/******************************************************************************************************
Project: BEP

Purpose: Tracking midline household and business backcheck & survey reconciliation data on daily basis

Author:  Azhar Hussain

Date  :  14 September, 2015
*******************************************************************************************************/



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
	//ssc install truecrypt
	//cd "`DROPBOX_ROOT'"
	//truecrypt BEP_TrueCrypt_20jul15, mount drive(S)
	local ROOT  "S:"
	local TDATE =  subinstr("$S_DATE"," ","",.)
	local RAW_DATA   "`ROOT'/Raw Data"
	local WORKING_DATA  "`DROPBOX_ROOT'/Working Data/`TDATE'"
	local SURVEY_TRACK "`DROPBOX_ROOT'/Tracking sheet/"
	local OUTPUT  "`DROPBOX_ROOT'/Output/`TDATE'/Survey Tracking"


* READING DAILY HOUSEHOLD SURVEY TRACKING SHEET

	insheet using "`SURVEY_TRACK'//Household Reconciliation/Household_Reconciliation_Tracking_`REPORT_DATE'.csv"
	drop if missing(areaid)
	quietly tostring status*, replace
	format status* %30s

	//Survey status codes
	gen recon_status=.
	replace recon_status=1 if status=="1-Complete"
	replace recon_status=2 if status=="2-Left Village/Market"
	replace recon_status=3 if status=="3-Respondent partially unavailable"
	replace recon_status=4 if status=="4-Respondent completely unavailable"
	replace recon_status=5 if status=="5-Did not consent"
	replace recon_status=6 if status=="6-Refused to complete survey midway"
	replace recon_status=7 if status=="7-HH/B not found"
	replace recon_status=8 if status=="8-Others"

	//Formatting survey tracking date
	gen datex=subinstr(date,"-","",.)
	gen recon_tracking_date=date(date,"DMY")
	format recon_tracking_date %td

	//Identifying completed households
	gen flag_hh_complete=0
	replace flag_hh_complete=1 if (recon_status==1)
	keep if flag_hh_complete==1

	//Creating village ids and household ids
	split areaid, p(-) generate(village_id)
	destring village_id* hh, replace
	rename hh hh_id
	rename surveyorcode reconciliator_code
	destring reconciliator_code, force replace 
	gsort village_id1 village_id2 village_id3 village_id4 hh_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 hh_id, generate(duphh)
	br if duphh!=0
	//Stop the program if duplicates are found in tracking sheet
	if duphh!=0{
	exit
	}
	
	tempfile HH_RECON_DAILY_TRACKING
	save "`HH_RECON_DAILY_TRACKING'"
	clear
	

* READING DAILY BUSINESS SURVEY TRACKING SHEET

	insheet using "`SURVEY_TRACK'//Business Reconciliation/Business_Reconciliation_Tracking_`REPORT_DATE'.csv"
	drop if missing(marketid)
	quietly tostring status*, replace
	format status* %30s

	//Survey status codes
	gen recon_status=.
	replace recon_status=1 if status=="1-Complete"
	replace recon_status=2 if status=="2-Left Village/Market"
	replace recon_status=3 if status=="3-Respondent partially unavailable"
	replace recon_status=4 if status=="4-Respondent completely unavailable"
	replace recon_status=5 if status=="5-Did not consent"
	replace recon_status=6 if status=="6-Refused to complete survey midway"
	replace recon_status=7 if status=="7-HH/B not found"
	replace recon_status=8 if status=="8-Others"
	
	//Formatting survey tracking date
	gen datex=subinstr(date,"-","",.)
	gen recon_tracking_date=date(date,"DMY")
	format recon_tracking_date %td

	//Identifying completed businesses
	gen flag_biz_complete=0
	replace flag_biz_complete=1 if (recon_status==1)
	keep if flag_biz_complete==1

	//Creating market ids and business ids
	split marketid, p(-) generate(village_id)
	destring village_id* biz, replace
	rename biz biz_id
	rename surveyorcode reconciliator_code
	destring reconciliator_code, force replace 
	gsort village_id1 village_id2 village_id3 village_id4 biz_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 biz_id, generate(dupbiz)
	br if dupbiz!=0
	//Stop the program if duplicates are found in tracking sheet
	if dupbiz!=0{
	exit
	}

	tempfile BIZ_RECON_DAILY_TRACKING
	save "`BIZ_RECON_DAILY_TRACKING'"
	clear
	

* READING DAILY RAW DATA AND CONVERTING TO .DTA FORMAT

	****Business****
	
	cd "`RAW_DATA'"
	insheet using "BEP_Busi_Reconci_V2.csv"
	rename key parent_key
	keep if stat_code1==1
	tempfile Business_R
	save "`Business_R'"
	clear
	
	****Household****
	
	cd "`RAW_DATA'"
	insheet using "BEP_HH_Reconci_V2.csv"
	rename key parent_key
	keep if stat_code1==1
	tempfile Household_R
	save "`Household_R'"
	clear


* HOUSEHOLD SURVEY DAILY TRACKING

	use `Household_R'

	//Generating relevant date variables
	gen recon_start_date = date("19Sep2015","DMY")
	gen today = date("`TDATE'", "DMY")
	gen report_dt = date("`REPORT_DATE'", "DMY")
	gen submission_date = date(submissiondate, "DMYhms")
	gen start_date = date(starttime, "DMYhms")
	gen end_date = date(endtime, "DMYhms")
	format submission_date start_date end_date today %td
	gen survey_mins=(clock(endtime, "DMYhms")-clock(starttime, "DMYhms"))/60000
	format survey_mins %3.2f

	//Eliminating pilot surveys done
	keep if start_date >= recon_start_date
	keep if start_date<=report_dt

	//Removing outliers such as second visits and other outlier cases which take too long
	gen survey_mins_adj=survey_mins
	replace survey_mins_adj=. if survey_mins>120

	//Surveyor codes
	rename consent_1grp7surveyor_name reconciliator_name
	rename consent_1grp7surveyor_code reconciliator_code

	//Renaming village IDs to assign codes to district, pss, feeder and village
	rename market_idvil_id_1 village_id1
	rename market_idvil_id_2 village_id2
	rename market_idvil_id_3 village_id3
	rename market_idvil_id_4 village_id4
	destring village_id* hh_id, replace
	
	//Making corrections to incorrect IDs entered based on feedback received from Animesh
	*23/09/2015
	drop if inlist(parent_key, "uuid:c9d678bd-576d-44d0-9bb1-43709002a70e", ///
	"uuid:94928852-e8ab-4219-a65d-972793212270", "uuid:916a932f-089f-4117-bbd7-7dfb99c9c91b")
	drop if inlist(parent_key, "uuid:4de08a42-0ec6-4008-899c-0c35bcfea1b3", ///
	"uuid:3c2d5ead-5287-44e4-9480-ee1d55dfb25a", "uuid:82adb644-405f-418c-90ea-6a2227a2b062")
	drop if inlist(parent_key, "uuid:c5040772-5a09-4945-9701-f539c15eb39e", ///
	"uuid:b02e227d-77ab-4424-bd22-9024c50e1dd8", "uuid:e22eedd1-347c-45d7-97a5-859018bee544")
	drop if inlist(parent_key, "uuid:2edf5a7c-71c5-4ffb-839d-fb70bf59005f", ///
	"uuid:53f7ea36-cf8d-4cf7-a8fd-4b5a436ec750")

	//Resolving survey duplicates based on feedback received from Animesh

	//Generating area id for tracking results
	generate area_id = string(village_id1)+"-"+string(village_id2)+"-"+string(village_id3)+"-"+string(village_id4)
	gsort village_id1 village_id2 village_id3 village_id4 hh_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 hh_id, generate(duphh)
	tab duphh

	//Outputting duplicate surveys to be resolved							
	preserve
	keep if duphh!=0	
	keep village_id1 village_id2 village_id3 village_id4 area_id hh_id start_date ///
	reconciliator_name reconciliator_code parent_key 						
	outsheet using "`OUTPUT'/DUPLICATE_RECON_HH_`REPORT_DATE'.xls", replace
	restore
	
	//Merging tracking and survey data
	merge m:1 village_id1 village_id2 village_id3 village_id4 hh_id reconciliator_code using "`HH_RECON_DAILY_TRACKING'", generate (mergeHHTracking)
	label define tracking 1 "DDC Data only" 2 "Tracking Sheet only" 3 "Both DDC data and Tracking sheet"
	label values mergeHHTracking tracking

	//Outsheeting  surveyor mismatches to be resolved
	preserve
	keep if (mergeHHTracking!=3)
	keep village_id1 village_id2 village_id3 village_id4 area_id hh_id reconciliator_name start_date ///
	reconciliator_code recon_tracking_date mergeHHTracking parent_key 						
	outsheet using "`OUTPUT'/HH_RECONCILIATOR_ID_MISMATCH_`REPORT_DATE'.xls", replace
	restore

	//Dropping PII before saving working data on Dropbox
	drop cal_hh_num infost cal_build_name cal_street_name cal_area_name cal_panchayat_name cal_block_name cal_dist_name ///
	cal_pin_code cal_hh_head_name consent_1grp2_0hh_num consent_1grp2_0build_name consent_1grp2_0street_name ///
	consent_1grp2_0area_name consent_1grp2panchayat_name consent_1grp2block_name consent_1grp2dist_name ///
	consent_1grp2pin_code consent_1grp2hh_head_name consent_1grp3info2 consent_1grp3resp_name consent_1grp3phone_num

	//Saving cumulative working files without PII
	cd "`WORKING_DATA'"
	save CUMULATIVE_HH_RECON_`REPORT_DATE', replace
	clear


* BUSINESS SURVEY DAILY TRACKING

	use `Business_R'
	gen recon_start_date = date("16Sep2015","DMY")
	gen today = date("`TDATE'", "DMY")
	gen report_dt = date("`REPORT_DATE'", "DMY")
	gen submission_date = date(submissiondate, "DMYhms")
	gen start_date = date(starttime, "DMYhms")
	gen end_date = date(endtime, "DMYhms")
	format submission_date start_date end_date today %td
	gen survey_mins=(clock(endtime, "DMYhms")-clock(starttime, "DMYhms"))/60000
	format survey_mins %3.2f

	//Eliminating pilot surveys done
	keep if start_date >= recon_start_date
	keep if start_date<=report_dt

	//Removing outliers such as second visits and other outlier cases which take too long
	gen survey_mins_adj=survey_mins
	replace survey_mins_adj=. if survey_mins>120

	//Surveyor and supervisor codes
	rename enquirysurveyorsur_name reconciliator_name
	rename enquirysurveyorsur_code reconciliator_code

	//Renaming village IDs to assign codes to district, pss, feeder and village
	rename grp1vil_id_1 village_id1
	rename grp1vil_id_2 village_id2
	rename grp1vil_id_3 village_id3
	rename grp1vil_id_4 village_id4
	rename firm_id biz_id
	destring village_id* biz_id, replace

	//Making corrections to incorrect IDs entered based on feedback received from Animesh
	*23/09/2015
	replace reconciliator_code=403 if inlist(parent_key, "uuid:d643221d-7f5a-47e1-9715-cc38ede0af54", ///
	"uuid:269ae303-b65b-4887-8da8-3643bee7d783", "uuid:32f93fb3-fc4b-4704-9fc0-c8e2fb6bfb56")
	replace reconciliator_code=403 if inlist(parent_key, "uuid:0640ad20-7c56-4125-b9de-938fa17b4ae8", ///
	"uuid:c55bd590-e300-4502-8159-a8420d10f08e", "uuid:5bfd96ba-3190-4892-97b0-f343c817e471")
	replace reconciliator_code=403 if inlist(parent_key, "uuid:b789aa42-9d68-4de6-ac73-572c379e5e33")
	replace reconciliator_code=402 if inlist(parent_key, "uuid:4390ec5f-5837-4e82-afd3-cf25b39f29cd", ///
	"uuid:6b616e1b-7733-4682-bc43-371556b15c8e", "uuid:ad049c11-e59e-41ff-bf45-4ac279a0878b")
	replace reconciliator_code=402 if inlist(parent_key, "uuid:6c9b2183-ce5c-442f-9c0b-640977b76c97")

	//Resolving survey duplicates based on feedback received from Animesh
	
	//Generating area id for tracking results
	generate area_id = string(village_id1)+"-"+string(village_id2)+"-"+string(village_id3)+"-"+string(village_id4)
	gsort village_id1 village_id2 village_id3 village_id4 biz_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 biz_id, generate(dupbiz)
	tab dupbiz

	//Outputting surveyor duplicates to be resolved							
	preserve
	keep if dupbiz!=0
	keep village_id1 village_id2 village_id3 village_id4 area_id biz_id start_date ///
	reconciliator_name reconciliator_code parent_key 						
	outsheet using "`OUTPUT'/DUPLICATE_RECON_BIZ_`REPORT_DATE'.xls", replace
	restore

	//Merging tracking and survey data
	merge m:1 village_id1 village_id2 village_id3 village_id4 biz_id reconciliator_code using "`BIZ_RECON_DAILY_TRACKING'", generate (mergeBizTracking)
	label define tracking 1 "DDC Data only" 2 "Tracking Sheet only" 3 "Both DDC data and Tracking sheet"
	label values mergeBizTracking tracking

	//Outsheeting village and biz id mismatches to be resolved
	preserve
	keep if (mergeBizTracking!=3)
	keep parent_key  village_id1 village_id2 village_id3 village_id4 area_id biz_id ///
	start_date recon_tracking_date reconciliator_name reconciliator_code mergeBizTracking						
	outsheet using "`OUTPUT'/BIZ_RECONCILIATOR_ID_MISMATCH_`REPORT_DATE'.xls", replace
	restore

	//Dropping PII before saving working data on Dropbox
	drop cal_firm_id infost cal_shop_num cal_street_name cal_area_name cal_panchayat_name cal_block_name cal_dist_name ///
	cal_pin_code cal_bus_name enquiryintro4 enquiryshop_num enquirystreet_name enquiryvillage_name enquirybg3town_name ///
	enquirybg3bloc_name enquirybg3dist_name enquirybg3pin_code enquirybg3bus_name enquirybg4bus_info enquirybg4bus_name ///
	enquirybg4resp_name enquirybg4resp_phno

	//Saving cumulative working files without PII
	cd "`WORKING_DATA'"
	save CUMULATIVE_BIZ_RECON_`REPORT_DATE', replace
	clear
	