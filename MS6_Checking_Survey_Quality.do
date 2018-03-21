/********************************************************************************
Project: BEP

Purpose: Performing quality checks on midline household and business survey data

Author:  Azhar Hussain

Date  :  21 July, 2015
*********************************************************************************/



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
	local OUTPUT  "`DROPBOX_ROOT'/Output/`TDATE'/Survey Quality"

	
* RUNNING HIGH FREQUENCY CHECKS ON THE CUMULATIVE SURVEY DATASET

	******HOUSEHOLD*******
	
	cd "`WORKING_DATA'"	
	use CUMULATIVE_HH_`REPORT_DATE'
	keep if flag_hh_complete==1
	keep if mergeHHTracking== 3
	
	//Renaming variables
	rename consent_1grp72e1 e1_elec_any
	rename consent_1e5_to_e54e19 e19_grid_conn
	rename consent_1e5_to_e54e20_to_e54e20e e20_meter_have
	rename v119 e33_receive_elecbill
	rename consent_1e5_to_e54e20_to_e54grp9 f1_elec_conn
	rename consent_1e5_to_e54e20_to_e54f20 f20_maintenane_complaint
	rename consent_1h_secsection_hhb0_have hb0_bedroom_have
	rename consent_1h_sechb1_elec hb1_bedroom_elec
	rename consent_1h_seckitchenshk0_have hk0_kitchen_have
	rename consent_1h_sechk1_elec hk1_kitchen_elec
	rename consent_1h_secliving_areahd0_hav hd0_livingroom_have
	rename consent_1h_sechd1_elec hd1_livingroom_elec
	rename consent_1h_sectoiletsht0_have ht0_toilet_have
	rename consent_1h_secht1_elec ht1_toilet_elec
	
	//Recoding variables
	recode e1_elec_any e19_grid_conn e20_meter_have e33_receive_elecbill f1_elec_conn f20_maintenane_complaint ///
	hb0_bedroom_have hb1_bedroom_elec hk0_kitchen_have hk1_kitchen_elec hd0_livingroom_have hd1_livingroom_elec ///
	ht0_toilet_have ht1_toilet_elec (2=0) (-101=0) (-102=0) (-103=0) (-104=0)

	//Converting to percent
	foreach var in e1_elec_any e19_grid_conn e20_meter_have e33_receive_elecbill f1_elec_conn f20_maintenane_complaint ///
	hb0_bedroom_have hb1_bedroom_elec hk0_kitchen_have hk1_kitchen_elec hd0_livingroom_have hd1_livingroom_elec ///
	ht0_toilet_have ht1_toilet_elec {
		generate `var'_100=.
		replace `var'_100= 100*`var'
	}
	
	//Generating distirct, area, surveyor and supervisor level summary statistics
	qui tabout district area_id surveyor_code supervisor_code using "`OUTPUT'/CUMULATIVE_HH_`REPORT_DATE'_HighFreqChecks_Results.xls", ///
	mi rep c(mean e1_elec_any_100 mean e19_grid_conn_100 mean e20_meter_have_100 mean e33_receive_elecbill_100 mean f1_elec_conn_100 ///
	mean f20_maintenane_complaint_100 mean hb0_bedroom_have_100 mean hb1_bedroom_elec_100 mean hk0_kitchen_have_100 ///
	mean hk1_kitchen_elec_100 mean hd0_livingroom_have_100 mean hd1_livingroom_elec_100 mean ht0_toilet_have_100 ///
	mean ht1_toilet_elec_100) oneway f(0p) sum npos(lab) ///
	h3(| % Elec Any| % Grid Elec | % Meter Have| % Receive Bill| % Elec Conn| % Maintenance Complaint| % Have Bedroom| ///
	% Have Elec Bedroom| % Have Kitchen| %Have Elec Kitchen| % Have Living Area| % Have Elec Living Area| % Have Toilet| ///
	% Have Elec Toilet) 
	drop *_100
	
	//Saving completed surveys only
	cd "`WORKING_DATA'"	
	save CUMULATIVE_HH_`REPORT_DATE'_COMPLETE, replace
	
	******BUSINESS*******
	
	use CUMULATIVE_BIZ_`REPORT_DATE'
	keep if flag_biz_complete==1
	keep if mergeBizTracking== 3
	
	//Renaming variables
	rename secebg219e1_have_elec e1_elec_any
	rename secebg220e19_connection e19_grid_conn
	rename secebg220grp_e19bg226e21_meter e21_meter_have
	rename secebg220grp_e19bg226billinge27_ e27_receive_elecbill
	rename secebg220grp_e19secfbgf1f1_conne f1_elec_conn
	rename secebg220grp_e19secff9_maintain f8_maintenane_complaint
	
	//Recoding variables
	recode e1_elec_any e19_grid_conn e21_meter_have e27_receive_elecbill f1_elec_conn f8_maintenane_complaint (2=0) (-101=0) (-102=0) (-103=0) (-104=0)
	
	//Converting to percent
	foreach var in e1_elec_any e19_grid_conn e21_meter_have e27_receive_elecbill f1_elec_conn f8_maintenane_complaint {
		generate `var'_100=.
		replace `var'_100= 100*`var'
	}	

	//Generating distirct, market, surveyor and supervisor level summary statistics
	qui tabout district marketid surveyor_code supervisor_code using "`OUTPUT'/CUMULATIVE_BIZ_`REPORT_DATE'_HighFreqChecks_Results.xls", ///
	mi rep c(mean e1_elec_any_100 mean e19_grid_conn_100 mean e21_meter_have_100 mean e27_receive_elecbill_100 mean f1_elec_conn_100 ///
	mean f8_maintenane_complaint_100) oneway f(0p) sum npos(lab) ///
	h3(| % Elec Any| % Grid Elec | % Meter Have| % Receive Bill| % Elec Conn| % Maintenance Complaint) 
	drop *_100
	
	//Saving completed surveys only
	cd "`WORKING_DATA'"	
	save CUMULATIVE_BIZ_`REPORT_DATE'_COMPLETE, replace


* RUNNING LOGICAL CHECKS ON THE CUMULATIVE SURVEY DATASET
	
	******HOUSEHOLD*******
	
	use CUMULATIVE_HH_`REPORT_DATE'_COMPLETE
	
	//Identifying variables to consider for check
	rename consent_1e5_to_e54e6_to_e12e7 e7_genset_ownership
	rename consent_1secgdiesgengen2 g_genset_private
	rename consent_1secggen_sharedg2_share g_genset_shared
	rename v179 f7_voltage_dim
	rename v204 f21_maintenance_issue
	generate f21_voltage_dim= regexm(f21_maintenance_issue, "4")
	unab exp_head: consent_1secjk1_expexp*
	recode `exp_head' (-101=.a) (-102=.b) (-103=.c) (-104=.d) 
	egen j1_exp= rowtotal(`exp_head')
	rename consent_1secjk2_to_k3k2_amount j2_high_exp
	recode j2_high_exp (-101=.a) (-102=.b) (-103=.c) (-104=.d)
	rename consent_1section_kgive1 k1_wakeup_male
	rename consent_1section_kgive2 k1_leave_male
	rename consent_1section_kgive3 k1_comeback_male
	rename consent_1section_kgive4 k1_sleep_male
	rename consent_1section_kgive5 k2_wakeup_female
	rename consent_1section_kgive6 k2_leave_female
	rename consent_1section_kgive7 k2_comeback_female
	rename consent_1section_kgive8 k2_sleep_female
	rename consent_1section_kgive9 k3_wakeup_child
	rename consent_1section_kgive10 k3_leave_child
	rename consent_1section_kgive11 k3_comeback_child
	rename consent_1section_kgive12 k3_sleep_child
	foreach k in k1_wakeup_male k1_leave_male k1_comeback_male k1_sleep_male k2_wakeup_female k2_leave_female k2_comeback_female ///
	k2_sleep_female k3_wakeup_child k3_leave_child k3_comeback_child k3_sleep_child {
		generate `k'_time_sif = Clock(`k', "hms")
		format `k'_time_sif %tC
		generate `k'_hour = hhC(`k'_time_sif)
		generate `k'_min = mmC(`k'_time_sif)
		generate `k'_sec = ssC(`k'_time_sif)
		generate `k'_tot= `k'_hour + `k'_min/60 + `k'_sec/3600
	}
	
	//Generating flagging variables
	generate flag_genset_private= .
	generate flag_genset_shared= .
	generate flag_elec_anyroom= .
	generate flag_voltage_dim= .
	generate flag_expenditure= .
	generate flag_wakeup_leave_male= .
	generate flag_wakeup_leave_female= .
	generate flag_wakeup_leave_child= .
	generate flag_comeback_sleep_male= .
	generate flag_comeback_sleep_female= .
	generate flag_comeback_sleep_child= .
	
	//Generating entry variables for Section-J and Section-K
	foreach var in `exp_head' {
		generate new_`var'= .
	}
	generate new_j2_high_exp= .
	foreach var in k1_wakeup_male k1_leave_male k1_comeback_male k1_sleep_male k2_wakeup_female k2_leave_female k2_comeback_female ///
	k2_sleep_female k3_wakeup_child k3_leave_child k3_comeback_child k3_sleep_child {
		generate new_`var'= .
	}
	
	//Flagging problematic observations
	replace flag_genset_private= 1 if ((e7_genset_ownership==1 & g_genset_private!=1) | (e7_genset_ownership!=1 & g_genset_private==1))
	replace flag_genset_shared= 1 if ((e7_genset_ownership==2 & g_genset_shared!=1) | (e7_genset_ownership!=2 & g_genset_shared==1))
	replace flag_elec_anyroom= 1 if ((e1_elec_any==2) & (hb1_bedroom_elec==1 | hk1_kitchen_elec==1 | hd1_livingroom_elec==1 | ht1_toilet_elec==1))
	replace flag_elec_anyroom= 1 if ((e1_elec_any==1) & (hb1_bedroom_elec!=1 & hk1_kitchen_elec!=1 & hd1_livingroom_elec!=1 & ht1_toilet_elec!=1))
	replace flag_voltage_dim= 1 if ((f7_voltage_dim==1 & f21_voltage_dim!=1) | (f7_voltage_dim==2 & f21_voltage_dim==1))
	replace flag_expenditure= 1 if (j1_exp>j2_high_exp)
	replace flag_wakeup_leave_male= 1 if ((k1_wakeup_male_tot>k1_leave_male_tot) & !missing(k1_wakeup_male_tot) & !missing(k1_leave_male_tot))
	replace flag_wakeup_leave_female= 1 if ((k2_wakeup_female_tot>k2_leave_female_tot) & !missing(k2_wakeup_female_tot) & !missing(k2_leave_female_tot))
	replace flag_wakeup_leave_child= 1 if ((k3_wakeup_child_tot>k3_leave_child_tot) & !missing(k3_wakeup_child_tot) & !missing(k3_leave_child_tot))
	replace flag_comeback_sleep_male= 1 if ((k1_comeback_male_tot>k1_sleep_male_tot) & !missing(k1_comeback_male_tot) & !missing(k1_sleep_male_tot))
	replace flag_comeback_sleep_female= 1 if ((k2_comeback_female_tot>k2_sleep_female_tot) & !missing(k2_comeback_female_tot) & !missing(k2_sleep_female_tot))
	replace flag_comeback_sleep_child= 1 if ((k3_comeback_child_tot>k3_sleep_child_tot) & !missing(k3_comeback_child_tot) & !missing(k3_sleep_child_tot))
	drop block grampanchayat 
	tempfile HH_LOG_CHK
	save "`HH_LOG_CHK'"
	
	//Outsheeting flagged observations
	keep flag* village_id* hh_id surveyor_code supervisor_code start_date parent_key
	drop flag_hh_complete
	sort start_date supervisor_code surveyor_code
	order parent_key start_date supervisor_code surveyor_code village_id1 village_id2 village_id3 village_id4 hh_id
	keep if (!missing(flag_genset_private) | !missing(flag_genset_shared) | !missing(flag_elec_anyroom) | ///
	!missing(flag_voltage_dim) | !missing(flag_expenditure) | !missing(flag_wakeup_leave_male) | !missing(flag_wakeup_leave_female) | ///
	!missing(flag_wakeup_leave_child) | !missing(flag_comeback_sleep_male) | !missing(flag_comeback_sleep_female) | !missing(flag_comeback_sleep_child))
	unab flags: flag*
	egen total_flags= rowtotal(`flags')
	egen energy_flags= rowtotal(flag_genset_private flag_genset_shared flag_elec_anyroom flag_voltage_dim)
	egen non_energy_flags= rowtotal(flag_expenditure flag_wakeup_leave_male flag_wakeup_leave_female flag_wakeup_leave_child ///
	flag_comeback_sleep_male flag_comeback_sleep_female flag_comeback_sleep_child)	
	outsheet using "`OUTPUT'/CUMULATIVE_HH_`REPORT_DATE'_LogicalChecks_Results.xls", replace
		
	//Surveyor-wise count of flags in electricity and non-electricity sections
	collapse (sum) total_flags (sum) energy_flags (sum) non_energy_flags, by(surveyor_code)
	gsort -total_flags -energy_flags -non_energy_flags
	outsheet using "`OUTPUT'/CUMULATIVE_HH_`REPORT_DATE'_Surveyor-level_LogicalChecks_Results.xls", replace	
	clear
	
	******BUSINESS*******
	
	use CUMULATIVE_BIZ_`REPORT_DATE'_COMPLETE
	
	//Identifying variables to consider for check
	rename secaa11a11_morning shop_start_time
	rename secaa11a11_afternoon shop_close_time
	rename secaa11_1a11_1_brk_time_from lunch_start_time
	rename secaa11_1a11_1_brk_time_to lunch_close_time
	rename secebg220bg221e7_shared e7_genset_ownership
	rename sec_f1diesel_generator_owni2_day g_genset_private
	rename sec_f1diesel_generator_sharedi2_ g_genset_shared
	
	//Generating flagging variables
	generate flag_genset_private= .
	generate flag_genset_shared= .
	
	//Flagging problematic observations
	replace flag_genset_private= 1 if ((e7_genset_ownership==1 & g_genset_private!=1) | (e7_genset_ownership!=1 & g_genset_private==1))
	replace flag_genset_shared= 1 if ((e7_genset_ownership==2 & g_genset_shared!=1) | (e7_genset_ownership!=2 & g_genset_shared==1))
	drop block
	tempfile BIZ_LOG_CHK
	save "`BIZ_LOG_CHK'"
	
	//Outsheeting flagged observations
	keep flag* village_id* biz_id surveyor_code supervisor_code start_date parent_key
	drop flag_biz_complete
	sort start_date supervisor_code surveyor_code
	order parent_key start_date supervisor_code surveyor_code village_id1 village_id2 village_id3 village_id4 biz_id
	keep if (!missing(flag_genset_private) | !missing(flag_genset_shared))
	unab flags: flag*
	egen total_flags= rowtotal(`flags')
	outsheet using "`OUTPUT'/CUMULATIVE_BIZ_`REPORT_DATE'_LogicalChecks_Results.xls", replace
	
	//Surveyor-wise count of flags in electricity section
	collapse (sum) total_flags, by(surveyor_code)
	gsort -total_flags
	outsheet using "`OUTPUT'/CUMULATIVE_BIZ_`REPORT_DATE'_Surveyor-level_LogicalChecks_Results.xls", replace	
	clear


* GENERATING REVISIT LIST FOR SURVEY RECONCILIATION

	******HOUSEHOLD******
		
	// Merging raw data for PII to include in tracking sheet
	insheet using "`RAW_DATA'/BEP_HH_MID_V7_WIDE.csv", clear
	rename key parent_key
	keep parent_key cal_panchayat_name cal_block_name cal_pin_code cal_hh_head_name grp3resp_name
	merge 1:1 parent_key using `HH_LOG_CHK', generate(merge_PII)
	keep if merge_PII==3
	drop merge_PII
	rename cal_panchayat_name grampanchayat
	rename cal_block_name block
	rename cal_pin_code pin_code
	rename grp3resp_name respondent_name
	rename cal_hh_head_name hh_head_name
	
	tempfile HH_LOG_RECON
	save "`HH_LOG_RECON'"
	clear

	// Merging names to include in tracking sheet
	insheet using "`ROOT'/Village_List.csv"
	keep village_id* district pss feeder area
	merge 1:m village_id1 village_id2 village_id3 village_id4 using `HH_LOG_RECON', gen(merge_Names)
	keep if merge_Names==3
	drop merge_Names
	sort village_id1 village_id2 village_id3 village_id4 hh_id

	// Outsheeting reconciliation survey list
	outsheet parent_key areaid village_id1 village_id2 village_id3 village_id4 hh_id district pss feeder area grampanchayat ///
	block respondent_name hh_head_name flag_genset_private flag_genset_shared using "`OUTPUT'/HH_LOG_CHK_RECON_LIST_`REPORT_DATE'.xls" ///
	if (flag_genset_private==1 | flag_genset_shared==1), replace
	clear

	******BUSINESS******
		
	// Merging raw data for PII to include in tracking sheet
	insheet using "`RAW_DATA'/BEP_Busi_MID_V7_WIDE.csv"
	tempfile Business7
	save "`Business7'"
	clear
	insheet using "`RAW_DATA'/BEP_Busi_MID_V8_WIDE.csv"
	tempfile Business8
	save "`Business8'"
	append using `Business7', force
	tempfile Business
	save "`Business'"
	rename key parent_key
	keep parent_key cal_panchayat_name cal_block_name cal_pin_code cal_bus_name bg4resp_name
	merge 1:1 parent_key using `BIZ_LOG_CHK', generate(merge_PII)
	keep if merge_PII==3
	drop merge_PII
	rename cal_panchayat_name grampanchayat
	rename cal_block_name block
	rename cal_pin_code pin_code
	rename bg4resp_name respondent_name
	rename cal_bus_name shop_name

	tempfile BIZ_LOG_RECON
	save "`BIZ_LOG_RECON'"
	clear

	// Merging names to include in tracking sheet
	insheet using "`ROOT'/Market_List.csv"
	keep village_id* district pss feeder market
	merge 1:m village_id1 village_id2 village_id3 village_id4 using `BIZ_LOG_RECON', gen(merge_Names)
	keep if merge_Names==3
	drop merge_Names
	sort village_id1 village_id2 village_id3 village_id4 biz_id

	// Outsheeting reconciliation survey list
	outsheet parent_key marketid village_id1 village_id2 village_id3 village_id4 biz_id district pss feeder market grampanchayat ///
	block respondent_name shop_name flag_genset_private flag_genset_shared using "`OUTPUT'/BIZ_LOG_CHK_RECON_LIST_`REPORT_DATE'.xls" ///
	if (flag_genset_private==1 | flag_genset_shared==1), replace
	clear
