/*****************************************************************************
Project: BEP

Purpose: Tracking backchecks of household and business surveys on daily basis

Author:  Azhar Hussain

Date  :  12 August, 2015
******************************************************************************/



* OPENING COMMANDS

	clear all
	capture log close
	set more off
	pause on
	version 12.0
	
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
	local BC_TRACK "`DROPBOX_ROOT'/Tracking sheet/"
	local OUTPUT  "`DROPBOX_ROOT'/Output/`TDATE'/Survey Tracking"


* READING DAILY HOUSEHOLD BACKCHECK TRACKING SHEET

	insheet using "`BC_TRACK'//Household Backcheck/Household_Backcheck_Tracking_`REPORT_DATE'.csv"
	drop if missing(areaid)
	quietly tostring status*, replace
	format status* %30s
	drop if missing(hh)
	
	//Backcheck status codes
	gen backcheck_status=.
	replace backcheck_status=1 if status=="1-Complete"
	replace backcheck_status=2 if status=="2-Left Village/Market"
	replace backcheck_status=3 if status=="3-Respondent partially unavailable"
	replace backcheck_status=4 if status=="4-Respondent completely unavailable"
	replace backcheck_status=5 if status=="5-Did not consent"
	replace backcheck_status=6 if status=="6-Refused to complete survey midway"
	replace backcheck_status=7 if status=="7-HH/B not found"
	replace backcheck_status=8 if status=="8-Others"
		
	//Formatting backcheck tracking date
	gen datex=subinstr(date,"-","",.)
	gen backcheck_tracking_date=date(date,"DMY")
	format backcheck_tracking_date %td

	//Identifying completed households
	gen flag_hh_complete=0
	replace flag_hh_complete=1 if (backcheck_status==1)
	keep if flag_hh_complete==1

	//Creating village ids and household ids
	split areaid, p(-) generate(village_id)
	destring village_id* hh, replace
	rename hh hh_id
	rename backcheckercode backchecker_code
	destring backchecker_code, force replace 	
	gsort village_id1 village_id2 village_id3 village_id4 hh_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 hh_id, generate(duphh)
	br if duphh!=0
	//Stop the program if duplicates are found in tracking sheet
	if duphh!=0{
	exit
	}
	
	tempfile HH_BC_DAILY_TRACKING
	save "`HH_BC_DAILY_TRACKING'"

	clear
	

* READING DAILY BUSINESS SURVEY TRACKING SHEET

	insheet using "`BC_TRACK'//Business Backcheck/Business_Backcheck_Tracking_`REPORT_DATE'.csv"
	drop if missing(marketid)
	quietly tostring status*, replace
	format status* %30s
	drop if missing(biz)

	//Backcheck status codes
	gen backcheck_status=.
	replace backcheck_status=1 if status=="1-Complete"
	replace backcheck_status=2 if status=="2-Left Village/Market"
	replace backcheck_status=3 if status=="3-Respondent partially unavailable"
	replace backcheck_status=4 if status=="4-Respondent completely unavailable"
	replace backcheck_status=5 if status=="5-Did not consent"
	replace backcheck_status=6 if status=="6-Refused to complete survey midway"
	replace backcheck_status=7 if status=="7-HH/B not found"
	replace backcheck_status=8 if status=="8-Others"
		
	//Formatting backcheck tracking date
	gen datex=subinstr(date,"-","",.)
	gen backcheck_tracking_date=date(date,"DMY")
	format backcheck_tracking_date %td
	
	//Identifying completed businesses
	gen flag_biz_complete=0
	replace flag_biz_complete=1 if (backcheck_status==1)
	keep if flag_biz_complete==1
	
	//Creating market ids and business ids
	split marketid, p(-) generate(village_id)
	destring village_id* biz, replace
	rename biz biz_id
	rename backcheckercode backchecker_code
	destring backchecker_code, force replace 
	gsort village_id1 village_id2 village_id3 village_id4 biz_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 biz_id, generate(dupbiz)
	br if dupbiz!=0
	//Stop the program if duplicates are found in tracking sheet
	if dupbiz!=0{
	exit
	}

	tempfile BIZ_BC_DAILY_TRACKING
	save "`BIZ_BC_DAILY_TRACKING'"
	
	clear
	

* READING DAILY RAW DATA AND CONVERTING TO .DTA FORMAT

	// Business
	cd "`RAW_DATA'"
	insheet using "BEP_Busi_BACKCHECK_MID_V4.csv"
	keep if stat_code1==1
	rename key parent_key
	tempfile Business_BC
	save "`Business_BC'"
	clear
	
	// Household
	cd "`RAW_DATA'"
	insheet using "BEP_HH_BACKCHECK_MID_V4.csv"
	keep if stat_code1==1
	rename key parent_key
	tempfile Household_BC
	save "`Household_BC'"
	clear


* HOUSEHOLD BACKCHECK DAILY TRACKING

	use `Household_BC'

	//Generating relevant date variables
	gen backcheck_start_date = date("11Aug2015","DMY")
	gen today = date("`TDATE'", "DMY")
	gen report_dt = date("`REPORT_DATE'", "DMY")
	gen submission_date = date(submissiondate, "DMYhms")
	gen start_date = date(starttime, "DMYhms")
	gen end_date = date(endtime, "DMYhms")
	format submission_date start_date end_date today %td
	gen backcheck_mins=(clock(endtime, "DMYhms")-clock(starttime, "DMYhms"))/60000
	format backcheck_mins %3.2f

	//Eliminating pilot backchecks done
	keep if start_date >= backcheck_start_date
	keep if start_date<=report_dt

	//Removing outliers such as second visits and other outlier cases which take too long
	gen backcheck_mins_adj=backcheck_mins
	replace backcheck_mins_adj=. if backcheck_mins>120

	//Renaming village IDs and surveyor codes to assign codes to district, pss, feeder and village
	rename grp2vil_id_1 village_id1
	rename grp2vil_id_2 village_id2
	rename grp2vil_id_3 village_id3
	rename grp2vil_id_4 village_id4
	rename grp1hh_id hh_id
	rename enquirygrp_consentgrp7surveyor_code backchecker_code
	destring village_id* hh_id, replace

	//Making corrections to incorrect IDs entered based on feedback received from Animesh
	*19/08/2015
	replace backchecker_code= 304 if parent_key== "uuid:c158aed2-6411-43c6-9891-6c1b62debb4c"
	*28/08/2015	
	drop if parent_key== "uuid:6cab6708-5898-47c6-b5c5-192e53d2d172"
	*03/09/2015	
	replace backchecker_code= 309 if parent_key== "uuid:a768e975-b836-4796-93d5-a60a33c74936"	

	//Resolving survey duplicates based on feedback received from Animesh
	*15/09/2015
	drop if inlist(parent_key, "uuid:80acdf5f-c9f9-4565-a9c6-eb473988db56", "uuid:c2826350-615a-4417-b70d-3c4b4b17672c")
	
	//Generating area id for tracking results
	generate area_id = string(village_id1)+"-"+string(village_id2)+"-"+string(village_id3)+"-"+string(village_id4)
	gsort village_id1 village_id2 village_id3 village_id4 hh_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 hh_id, generate(duphh)
	tab duphh

	//Outputting duplicate backchecks to be resolved							
	preserve
	keep if duphh!=0
	keep village_id1 village_id2 village_id3 village_id4 area_id hh_id start_date backchecker_code parent_key			
	outsheet using "`OUTPUT'/DUPLICATE_BACKCHECKS_HH_`REPORT_DATE'.xls", replace
	restore

	//Merging tracking and backcheck data
	merge m:1 village_id1 village_id2 village_id3 village_id4 hh_id backchecker_code using "`HH_BC_DAILY_TRACKING'", generate (mergeHHBCTracking)
	label define tracking 1 "DDC Data only" 2 "Tracking Sheet only" 3 "Both DDC data and Tracking sheet"
	label values mergeHHBCTracking tracking

	//Outsheeting  surveyor mismatches to be resolved
	preserve
	keep if ((mergeHHBCTracking==1 & !missing(backchecker_code)) | (mergeHHBCTracking==2 & !missing(backchecker_code)))
	keep village_id1 village_id2 village_id3 village_id4 area_id hh_id backchecker_code start_date ///
	backcheck_tracking_date mergeHHBCTracking parent_key 						
	outsheet using "`OUTPUT'/HH_BC_SURVEYOR_ID_MISMATCH_`REPORT_DATE'.xls", replace
	restore

	//Dropping PII before saving working data on Dropbox
	drop cal_hh_num infost enquirycal_build_name enquirycal_street_name enquirycal_area_name enquirycal_panchayat_name ///
	enquirycal_block_name enquirycal_dist_name enquirycal_pin_code enquirycal_hh_head_name enquirygrp5hh_num ///
	enquirygrp5build_name enquirygrp5street_name enquirygrp5area_name enquirygrp6panchayat_name enquirygrp6block_name ///
	enquirygrp6dist_name enquirygrp6pin_code enquirygrp6hh_head_name enquirygrp6_1info2 enquirygrp6_1resp_name enquirygrp6_1phone_num

	//Saving cumulative working files without PII
	cd "`WORKING_DATA'"
	save CUMULATIVE_HH_BC_`REPORT_DATE', replace
	clear


* BUSINESS BACKCHECK DAILY TRACKING

	use `Business_BC'
	gen backcheck_start_date = date("11Aug2015","DMY")
	gen today = date("`TDATE'", "DMY")
	gen report_dt = date("`REPORT_DATE'", "DMY")
	gen submission_date = date(submissiondate, "DMYhms")
	gen start_date = date(starttime, "DMYhms")
	gen end_date = date(endtime, "DMYhms")
	format submission_date start_date end_date today %td
	gen backcheck_mins=(clock(endtime, "DMYhms")-clock(starttime, "DMYhms"))/60000
	format backcheck_mins %3.2f

	//Eliminating pilot surveys done
	keep if start_date >= backcheck_start_date
	keep if start_date<=report_dt

	//Removing outliers such as second visits and other outlier cases which take too long
	gen backcheck_mins_adj=backcheck_mins
	replace backcheck_mins_adj=. if backcheck_mins>120
	  
	//Renaming village IDs and surveyour codes to assign codes to district, pss, feeder and village
	rename grp1vil_id_1 village_id1
	rename grp1vil_id_2 village_id2
	rename grp1vil_id_3 village_id3
	rename grp1vil_id_4 village_id4
	rename firm_id biz_id
	rename enquirygrp_consentgrp9sur_code backchecker_code
	destring village_id* biz_id, replace

	//Making corrections to incorrect IDs entered based on feedback received from Animesh
	
	//Resolving survey duplicates based on feedback received from Animesh
	*29/08/2015
	drop if parent_key== "uuid:61ad0cdb-3825-4a89-9794-a3643faa1ebc"

	//Generating area id for tracking results
	generate area_id = string(village_id1)+"-"+string(village_id2)+"-"+string(village_id3)+"-"+string(village_id4)
	gsort village_id1 village_id2 village_id3 village_id4 biz_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 biz_id, generate(dupbiz)
	tab dupbiz

	//Outputting surveyor duplicates to be resolved							
	preserve
	keep if dupbiz!=0
	keep village_id1 village_id2 village_id3 village_id4 area_id biz_id start_date backchecker_code parent_key
	outsheet using "`OUTPUT'/DUPLICATE_BACKCHECKS_BIZ_`REPORT_DATE'.xls", replace
	restore

	//Merging tracking and survey data
	merge m:1 village_id1 village_id2 village_id3 village_id4 biz_id backchecker_code using "`BIZ_BC_DAILY_TRACKING'", generate (mergeBizBCTracking)
	label define tracking 1 "DDC Data only" 2 "Tracking Sheet only" 3 "Both DDC data and Tracking sheet"
	label values mergeBizBCTracking tracking

	//Outsheeting village and biz id mismatches to be resolved
	preserve
	keep if ((mergeBizBCTracking==1 )| (mergeBizBCTracking==2) & !missing(backchecker_code))
	keep village_id1 village_id2 village_id3 village_id4 area_id biz_id start_date backcheck_tracking_date ///
	backchecker_code mergeBizBCTracking parent_key 						
	outsheet using "`OUTPUT'/BIZ_BC_SURVEYOR_ID_MISMATCH_`REPORT_DATE'.xls", replace
	restore

	//Dropping PII before saving working data on Dropbox
	drop enquirycal_shop_num enquirycal_street_name enquirycal_area_name enquirycal_panchayat_name enquirycal_block_name ///
	enquirycal_dist_name enquirycal_pin_code enquirycal_bus_name enquirygrp3intro4 enquirygrp3shop_num ///
	enquirygrp3street_name enquirygrp3village_name enquirygrp4town_name enquirygrp4bloc_name enquirygrp4dist_name ///
	enquirygrp4pin_code enquirygrp5bus_info enquirygrp5bus_name enquirygrp5resp_name enquirygrp5resp_phno

	//Saving cumulative working files without PII
	cd "`WORKING_DATA'"
	save CUMULATIVE_BIZ_BC_`REPORT_DATE', replace
	clear
	