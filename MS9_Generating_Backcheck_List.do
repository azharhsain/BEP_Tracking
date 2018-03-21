/***********************************************************
Project: BEP

Purpose: Generating list of surveys for doing back-checking

Author:  Azhar Hussain

Date  :  01 August, 2015
************************************************************/



* OPENING COMMANDS

	clear all
	capture log close
	set more off
	pause on
	version 12.0
	
	local BC_REPORT_DATE "08Sep2015"
	local REPORT_DATE "08Sep2015"


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
	local BC_OUTPUT  "`WORKING_DATA'\Backcheck Lists"


* GENERATING HOUSEHOLD BACKCHECK LIST

	cd "`WORKING_DATA'"
	use CUMULATIVE_HH_`REPORT_DATE'_COMPLETE
	keep submission_date start_date surveyor_code supervisor_code village_id* areaid hh_id district pss feeder parent_key
	keep if start_date<=date("`BC_REPORT_DATE'","DMY")
	gsort parent_key
	tempfile HH_WORKING_DATA
	save "`HH_WORKING_DATA'"
	clear

	insheet using "`RAW_DATA'\BEP_HH_MID_V7_WIDE.csv"
	rename key parent_key
	gsort parent_key
	keep cal_hh_num cal_build_name cal_street_name cal_area_name cal_panchayat_name cal_block_name cal_dist_name ///
	cal_pin_code cal_hh_head_name grp3resp_name parent_key
	tempfile HH_RAW DATA
	save "`HH_RAW DATA'"

	merge 1:1 parent_key using "`HH_WORKING_DATA'", generate(mergeBackcheck)
	label define tracking 1 "Raw Data only" 2 "Working Data only" 3 "Both Raw and Working data"
	label values mergeBackcheck tracking

	keep if mergeBackcheck==3

	// Rename identification variables
	rename cal_hh_num HH_NUMBER
	rename cal_build_name BUILDING_NAME
	rename cal_street_name STREET
	rename cal_area_name AREA
	rename cal_panchayat_name PANCHAYAT
	rename cal_block_name BLOCK
	rename cal_pin_code PIN_CODE
	rename cal_hh_head_name HH_HEAD_NAME
	rename grp3resp_name RESPONDENT_NAME

	gsort start_date parent_key

	duplicates tag start_date parent_key, generate(temp)
	tab temp

	// Pick one sample each per surveyor for each survey date
	set seed 05082015
	display c(seed)
	gen rand_samp=runiform()
	sort start_date surveyor_code rand_samp

	bys start_date surveyor_code: gen picked = _n==1
	tab picked
	keep if picked==1

	tempfile CUMULATIVE_HH_BC
	save "`CUMULATIVE_HH_BC'"

	keep if start_date==date("`BC_REPORT_DATE'","DMY")
	tempfile DAILY_HH_BC
	save "`DAILY_HH_BC'"

	//Outputting data to be sent to the field 
	keep HH_NUMBER BUILDING_NAME STREET AREA PANCHAYAT BLOCK PIN_CODE HH_HEAD_NAME RESPONDENT_NAME district pss feeder village_id* areaid hh_id start_date
	sort start_date village_id1 village_id2 village_id3 village_id4 hh_id
	gen sno= _n
	outsheet using "`BC_OUTPUT'\DAILY_HH_BC_`BC_REPORT_DATE'.xls", replace
	clear

	use `CUMULATIVE_HH_BC'
	keep HH_NUMBER BUILDING_NAME STREET AREA PANCHAYAT BLOCK PIN_CODE HH_HEAD_NAME RESPONDENT_NAME district pss feeder village_id* areaid hh_id start_date
	sort start_date village_id1 village_id2 village_id3 village_id4 hh_id
	gen sno= _n
	outsheet using "`BC_OUTPUT'\CUMULATIVE_HH_BC_`BC_REPORT_DATE'.xls", replace
	clear


* GENERATING BUSINESS BACKCHECK LIST

	cd "`WORKING_DATA'"
	use CUMULATIVE_BIZ_`REPORT_DATE'_COMPLETE
	keep submission_date start_date surveyor_code supervisor_code village_id* marketid biz_id district pss feeder parent_key
	keep if start_date<=date("`BC_REPORT_DATE'","DMY")
	gsort parent_key
	tempfile BIZ_WORKING_DATA
	save "`BIZ_WORKING_DATA'"
	
	clear

	insheet using "`RAW_DATA'\BEP_Busi_MID_V7_WIDE.csv"
	tempfile BIZ_RAW_DATA7
	save "`BIZ_RAW_DATA7'"
	
	clear
	
	insheet using "`RAW_DATA'\BEP_Busi_MID_V8_WIDE.csv"
	tempfile BIZ_RAW_DATA8
	save "`BIZ_RAW_DATA8'"
	
	clear
	
	use "`BIZ_RAW_DATA7'"
	append using "`BIZ_RAW_DATA8'", force
	rename key parent_key
	gsort parent_key
	keep cal_shop_num cal_street_name cal_area_name cal_panchayat_name cal_block_name cal_dist_name ///
	cal_pin_code cal_bus_name bg4resp_name parent_key
	tempfile BIZ_RAW_DATA
	save "`BIZ_RAW_DATA'"
	
	merge 1:1 parent_key using "`BIZ_WORKING_DATA'", generate(mergeBackcheck)
	label define tracking 1 "Raw Data only" 2 "Working Data only" 3 "Both Raw and Working data"
	label values mergeBackcheck tracking

	keep if mergeBackcheck==3

	// Rename identification variables
	rename cal_shop_num SHOP_NUMBER
	rename cal_street_name STREET
	rename cal_area_name MARKET
	rename cal_panchayat_name PANCHAYAT
	rename cal_block_name BLOCK
	rename cal_pin_code PIN_CODE
	rename cal_bus_name BUSINESS_NAME
	rename bg4resp_name RESPONDENT_NAME

	gsort start_date parent_key

	duplicates tag start_date parent_key, generate(temp)
	tab temp

	// Pick one sample each per surveyor for each survey date
	set seed 06082015
	display c(seed)
	gen rand_samp=runiform()
	sort start_date surveyor_code rand_samp

	bys start_date surveyor_code: gen picked = _n==1
	tab picked
	keep if picked==1

	tempfile CUMULATIVE_BIZ_BC
	save "`CUMULATIVE_BIZ_BC'"

	keep if start_date==date("`BC_REPORT_DATE'","DMY")
	tempfile DAILY_BIZ_BC
	save "`DAILY_BIZ_BC'"

	//Outputting data to be sent to the field 
	keep SHOP_NUMBER STREET MARKET PANCHAYAT BLOCK PIN_CODE BUSINESS_NAME RESPONDENT_NAME district pss feeder village_id* marketid biz_id start_date
	sort start_date village_id1 village_id2 village_id3 village_id4 biz_id
	gen sno= _n
	outsheet using "`BC_OUTPUT'\DAILY_BIZ_BC_`BC_REPORT_DATE'.xls", replace
	clear

	use `CUMULATIVE_BIZ_BC'
	keep SHOP_NUMBER STREET MARKET PANCHAYAT BLOCK PIN_CODE BUSINESS_NAME RESPONDENT_NAME district pss feeder village_id* marketid biz_id start_date
	sort start_date village_id1 village_id2 village_id3 village_id4 biz_id
	gen sno= _n
	outsheet using "`BC_OUTPUT'\CUMULATIVE_BIZ_BC_`BC_REPORT_DATE'.xls", replace
	clear
