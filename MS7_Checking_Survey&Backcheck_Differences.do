/****************************************************************************************************************
Project: BEP

Purpose: Flagging differences between survey and backcheck data of hosuehold and business surveys on daily basis

Author:  Azhar Hussain

Date  :  13 August, 2015
*****************************************************************************************************************/



* OPENING COMMANDS

	clear all
	capture log close
	set more off
	pause on
	version 12.0
	
	local REPORT_DATE "11Oct2015"  //Date of the survey being tracked is to be updated before running the code
	//ssc install cfout, replace


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

	local RAW_DATA "`ROOT'/Raw Data"
	local TDATE =  subinstr("$S_DATE"," ","",.)
	local WORKING_DATA  "`DROPBOX_ROOT'/Working Data/`TDATE'"
	local OUTPUT  "`DROPBOX_ROOT'/Output/`TDATE'/Survey Backcheck"


* READING CUMULATIVE BACKCHECK DATA

	cd "`WORKING_DATA'"
	
	******HOUSEHOLD******
	
	use CUMULATIVE_HH_BC_`REPORT_DATE'
	
	//Renaming variables
	rename backchecker_code surveyor_code
	rename enquirygrp_consentgrp9d1_ele_sou e1_elec_any
	rename enquirygrp_consentgrp10d2_have_g e5_genset
	rename enquirygrp_consentgrp10d3_solar_ e13_solar
	rename enquirygrp_consentd4_ele_connect e19_grid_conn
	rename enquirygrp_consentgrp11d5_have_m e20_meter_have
	rename enquirygrp_consentd6_functional e21_meter_functional
	rename enquirygrp_consentgrp12d7_receiv e33_receive_elecbill
	rename enquirygrp_consentgrp13f3_income j7_have_regular_inc
	rename enquirygrp_consentgrp14f4_earn j12_monthly_inc_val
	rename enquirygrp_consentgrp14f5_high_e j8_high_inc_val
	rename enquirygrp_consentgrp14f6_mm j9_high_inc_month
	rename enquirygrp_consentgrp15f7_low_ex j10_low_inc_val
	rename enquirygrp_consentgrp15f8_mm_yy j11_low_inc_month
	rename enquirygrp_consentgrp17hb0_bed_r hb0_bedroom_have 
	rename enquirygrp_consenthb1_elec hb1_bedroom_elec
	rename enquirygrp_consentgrp18hb2_num_b hb2_bedroom_bulb
	rename enquirygrp_consentgrp18hb3_num_c hb3_bedroom_cfl
	rename enquirygrp_consentgrp18hb4_num_t hb4_bedroom_tube
	rename enquirygrp_consentgrp18hb5_num_p	hb5_bedroom_plug
	rename enquirygrp_consenthk0_kitchen hk0_kitchen_have 
	rename enquirygrp_consenthk1_elec hk1_kitchen_elec
	rename enquirygrp_consentgrp19hk2_num_b hk2_kitchen_bulb
	rename enquirygrp_consentgrp19hk3_num_c hk3_kitchen_cfl
	rename enquirygrp_consentgrp19hk4_num_t hk4_kitchen_tube
	rename enquirygrp_consentgrp19hk5_num_p hk5_kitchen_plug
	rename enquirygrp_consenthd0_livi_area hd0_livingroom_have
	rename enquirygrp_consenthd1_elec hd1_livingroom_elec
	rename enquirygrp_consentgrp20hd2_num_b hd2_livingroom_bulb
	rename enquirygrp_consentgrp20hd3_num_c hd3_livingroom_cfl
	rename enquirygrp_consentgrp20hd4_num_t hd4_livingroom_tube
	rename enquirygrp_consentgrp20hd5_num_p hd5_livingroom_plug
	rename enquirygrp_consentht0_toilet ht0_toilet_have
	rename enquirygrp_consentht1_elec ht1_toilet_elec
	rename enquirygrp_consentgrp21ht2_num_b ht2_toilet_bulb
	rename enquirygrp_consentgrp21ht3_num_c ht3_toilet_cfl
	rename enquirygrp_consentgrp21ht4_num_t ht4_toilet_tube
	rename enquirygrp_consentgrp21ht5_num_p ht5_toilet_plug
	
	//Recoding variables to missing values for skip codes and 0 for No
	recode e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have e21_meter_functional e33_receive_elecbill ///
	j7_have_regular_inc j12_monthly_inc_val j8_high_inc_val j9_high_inc_month j10_low_inc_val j11_low_inc_month ///
	h*0_*_have h*1_*_elec h*2_*_bulb h*3_*_cfl h*4_*_tube h*5_*_plug (-101=.a) (-102=.b) (-103=.c) (-104=.d)
	recode e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have e21_meter_functional e33_receive_elecbill ///
	j7_have_regular_inc h*0_*_have h*1_*_elec (2=0)
	
	//Generating UIDs
	egen uid=concat(village_id1 village_id2 village_id3 village_id4 hh_id), punct(-)
	gsort uid
	duplicates drop uid, force
	
	//Keeping relevant variables only
	keep village_id* parent_key surveyor_code uid e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have e21_meter_functional e33_receive_elecbill ///
	j7_have_regular_inc j12_monthly_inc_val j8_high_inc_val j9_high_inc_month j10_low_inc_val j11_low_inc_month ///
	h*0_*_have h*1_*_elec h*2_*_bulb h*3_*_cfl h*4_*_tube h*5_*_plug
	tempfile HH_BC
	save "`HH_BC'"
	clear
	
	******BUSINESS******
	
	use CUMULATIVE_BIZ_BC_`REPORT_DATE'
	
	//Renaming variables
	rename backchecker_code surveyor_code
	rename enquirygrp_consentsectors0_1 o1_retail
	rename enquirygrp_consentretail_sect o1_retail_sector
	rename enquirygrp_consentsectors0_2 o2_service
	rename enquirygrp_consentserv_sect o2_service_sector
	rename enquirygrp_consentsectors0_3 o3_workshop
	rename enquirygrp_consentworkshop_sect o3_workshop_sector
	rename enquirygrp_consentgrp11a1_proper a1_proprietor
	rename enquirygrp_consentgrpb1b1_number b1_male_worker
	rename enquirygrp_consentgrpb1b2_number b2_female_worker
	rename enquirygrp_consentgrpb2b3_number b3_supervisor
	rename enquirygrp_consentgrpb2b4_number b4_other
	rename enquirygrp_consentgrpb2b5_number b5_family_member
	rename enquirygrp_consentgrp12c1_have_e e1_elec_any
	rename enquirygrp_consentgrp_c2c2_have_ e5_genset
	rename enquirygrp_consentgrp_c2c3_share e7_genset_owner
	rename enquirygrp_consentgrp_c2c4_hav_p e13_solar
	rename enquirygrp_consentgrp_c2c5_kind e14_solar_owner
	rename enquirygrp_consentgrp_c2c6_conne e19_grid_conn
	rename enquirygrp_consentgrp_c2c7_pay e20_bill_rent
	rename enquirygrp_consentgrp_c2grp13c8_ e21_meter_have
	rename enquirygrp_consentgrp_c2c9_funct e23_meter_functional
	rename enquirygrp_consentgrp14d5_income h25_rental_inc
	rename enquirygrp_consentgrp14_1d6_tot_ h26_rental_inc_val
	rename enquirygrp_consentgrp14_1d7_prof h28_profit
	
	//Recoding variables to missing values for skip codes and 0 for No
	recode o1_retail o1_retail_sector o2_service o2_service_sector o3_workshop o3_workshop_sector ///
	a1_proprietor b1_male_worker b2_female_worker b3_supervisor b4_other b5_family_member e1_elec_any e5_genset ///
	e7_genset_owner e13_solar e14_solar_owner e19_grid_conn e20_bill_rent e21_meter_have e23_meter_functional ///
	h25_rental_inc h26_rental_inc_val h28_profit (-101=.a) (-102=.b) (-103=.c) (-104=.d)
	recode o1_retail o2_service o3_workshop e1_elec_any e5_genset e7_genset_owner e13_solar e19_grid_conn e20_bill_rent ///
	e21_meter_have e14_solar_owner e23_meter_functional h25_rental_inc (2=0)
	
	//Generating UIDs
	egen uid=concat(village_id1 village_id2 village_id3 village_id4 biz_id), punct(-)
	gsort uid
	duplicates drop uid, force
	
	//Keeping relevant variables only
	keep village_id* parent_key surveyor_code uid o1_retail o1_retail_sector o2_service o2_service_sector o3_workshop o3_workshop_sector ///
	a1_proprietor b1_male_worker b2_female_worker b3_supervisor b4_other b5_family_member e1_elec_any e5_genset ///
	e7_genset_owner e13_solar e14_solar_owner e19_grid_conn e20_bill_rent e21_meter_have e23_meter_functional ///
	h25_rental_inc h26_rental_inc_val h28_profit
	tempfile BIZ_BC
	save "`BIZ_BC'"
	clear


* READING CUMULATIVE SURVEY DATA

	******HOUSEHOLD******

	use CUMULATIVE_HH_`REPORT_DATE'_COMPLETE

	//Renaming variables
	rename consent_1e5_to_e54e5 e5_genset
	rename consent_1e5_to_e54grp78e13 e13_solar
	rename consent_1e5_to_e54e20_to_e54e21 e21_meter_functional
	rename consent_1secjk2k2_regular j7_have_regular_inc
	rename consent_1secjk7_earn j12_monthly_inc_val
	rename consent_1secjj8_to_j9k3_amount j8_high_inc_val
	rename consent_1secjj8_to_j9k4_month j9_high_inc_month
	rename consent_1secjk5_to_k6k5_low j10_low_inc_val
	rename consent_1secjk5_to_k6k6_month j11_low_inc_month
	rename consent_1h_sechb2_bulb hb2_bedroom_bulb
	rename consent_1h_sechb3_tube hb3_bedroom_cfl
	rename consent_1h_sechb4_cfl hb4_bedroom_tube
	rename consent_1h_sechb5_plug hb5_bedroom_plug
	rename consent_1h_sechk2_bulb hk2_kitchen_bulb
	rename consent_1h_sechk3_cfl hk3_kitchen_cfl
	rename consent_1h_sechk4_tube hk4_kitchen_tube
	rename consent_1h_sechk5_plug hk5_kitchen_plug
	rename consent_1h_sechd2_bulb hd2_livingroom_bulb
	rename consent_1h_sechd3_cfl hd3_livingroom_cfl
	rename consent_1h_sechd4_tube hd4_livingroom_tube
	rename consent_1h_sechd5_plug hd5_livingroom_plug
	rename consent_1h_secht2_bulb ht2_toilet_bulb
	rename consent_1h_secht3_cfl ht3_toilet_cfl
	rename consent_1h_secht4_tube ht4_toilet_tube
	rename consent_1h_secht5_plug ht5_toilet_plug
	
	//Recoding variables to missing values for skip codes and 0 for No
	recode e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have e21_meter_functional e33_receive_elecbill ///
	j7_have_regular_inc j12_monthly_inc_val j8_high_inc_val j9_high_inc_month j10_low_inc_val j11_low_inc_month ///
	h*0_*_have h*1_*_elec h*2_*_bulb h*3_*_cfl h*4_*_tube h*5_*_plug (-101=.a) (-102=.b) (-103=.c) (-104=.d)
	recode e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have e21_meter_functional e33_receive_elecbill ///
	j7_have_regular_inc h*0_*_have h*1_*_elec (2=0)
	
	//Generating unique IDs
	egen uid=concat(village_id1 village_id2 village_id3 village_id4 hh_id), punct(-)
	gsort uid
	duplicates drop uid, force
	
	//Keeping relevant variables only
	keep village_id* parent_key surveyor_code uid e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have e21_meter_functional e33_receive_elecbill ///
	j7_have_regular_inc j12_monthly_inc_val j8_high_inc_val j9_high_inc_month j10_low_inc_val j11_low_inc_month ///
	h*0_*_have h*1_*_elec h*2_*_bulb h*3_*_cfl h*4_*_tube h*5_*_plug
	tempfile HH_SUR
	save "`HH_SUR'"
	clear
	
	******BUSINESS******
	
	use CUMULATIVE_BIZ_`REPORT_DATE'_COMPLETE

	//Renaming variables
	rename secaq0sectors0_1 o1_retail
	rename secaq0retail_sect o1_retail_sector
	rename secaq0sectors0_2 o2_service
	rename secaq0serv_sect o2_service_sector
	rename secaq0sectors0_3 o3_workshop
	rename secaq0workshop_sect o3_workshop_sector
	rename secaa1_proper a1_proprietor
	rename secbb1_count b1_male_worker
	rename secbb2_count b2_female_worker
	rename secbb3_count b3_supervisor
	rename secbb4_count b4_other
	rename secbb7b5_number b5_family_member
	rename secebg220e5_hav_gen e5_genset
	rename secebg220bg221e7_shared e7_genset_owner
	rename secebg220bg224e13_hav_panel e13_solar
	rename secebg220e14_to_e18e14_kind e14_solar_owner
	rename secebg220grp_e19e20_pay e20_bill_rent
	rename v667 e23_meter_functional
	rename secgask_all_busg25_income h25_rental_inc
	rename secgask_all_busg26_income h26_rental_inc_val
	rename secgprofit h28_profit
	
	//Recoding variables to missing values for skip codes
	recode o1_retail o1_retail_sector o2_service o2_service_sector o3_workshop o3_workshop_sector ///
	a1_proprietor b1_male_worker b2_female_worker b3_supervisor b4_other b5_family_member e1_elec_any e5_genset ///
	e7_genset_owner e13_solar e14_solar_owner e19_grid_conn e20_bill_rent e21_meter_have e23_meter_functional ///
	h25_rental_inc h26_rental_inc_val h28_profit (-101=.a) (-102=.b) (-103=.c) (-104=.d)
	recode o1_retail o2_service o3_workshop e1_elec_any e5_genset e13_solar e19_grid_conn e20_bill_rent ///
	e21_meter_have e23_meter_functional h25_rental_inc (2=0)
	
	//Generating unique IDs
	egen uid=concat(village_id1 village_id2 village_id3 village_id4 biz_id), punct(-)
	gsort uid
	duplicates drop uid, force
	
	//Keeping relevant variables only
	keep village_id* parent_key surveyor_code uid o1_retail o1_retail_sector o2_service o2_service_sector o3_workshop o3_workshop_sector ///
	a1_proprietor b1_male_worker b2_female_worker b3_supervisor b4_other b5_family_member e1_elec_any e5_genset ///
	e7_genset_owner e13_solar e14_solar_owner e19_grid_conn e20_bill_rent e21_meter_have e23_meter_functional ///
	h25_rental_inc h26_rental_inc_val h28_profit
	tempfile BIZ_SUR
	save "`BIZ_SUR'"
	clear


* COMPARING SURVEY & BACKCHECK DATA AND GENERATING DIFFERENCES REPORT

	******HOUSEHOLD******
	
	use `HH_SUR'
	merge 1:1 uid using `HH_BC', generate(mergeHHBC)
	keep if mergeHHBC == 3
	cfout using `HH_BC', id(uid) upper saving(HH_BACKCHECK_DIFFERENCES_`REPORT_DATE', masterval(SUR_) usingval(BC_) all(DIFF_) replace)
	clear
	
	//Reshaping the cumulative difference data
	use HH_BACKCHECK_DIFFERENCES_`REPORT_DATE'
	reshape wide SUR_ BC_ DIFF_, i(uid) j(Question) string
	
	//Generating section-wise error rates keeping only binary and categorical variables
	drop *j12_monthly_inc_val *j8_high_inc_val *j10_low_inc_val 
	local bc_sec `" "e" "j" "h" "' 
	foreach section in `bc_sec' {
		unab sec_ques: DIFF_`section'*
		egen error_rate_sec_`section'= rmean(`sec_ques')
	}
	unab section_EHJ: DIFF_e* DIFF_h* DIFF_j*
	egen error_rate_sec_ehj = rmean(`section_EHJ')
	
	foreach var in `section_EHJ' {
	replace `var' = `var'*100
	}

	label var SUR_village_id1 "District Code"
	label var SUR_surveyor_code "Surveyor Code"
	label var BC_surveyor_code "Backchecker Code"

	// Outsheeting backcheck differences report							
	qui tabout SUR_village_id1 SUR_surveyor_code BC_surveyor_code using "`OUTPUT'/HH_BC_REPORT_`REPORT_DATE'.xls", mi rep ///
	c(mean DIFF_e1_elec_any mean DIFF_e5_genset mean DIFF_e13_solar mean DIFF_e19_grid_conn mean DIFF_e20_meter_have ///
	mean DIFF_e21_meter_functional mean DIFF_e33_receive_elecbill mean DIFF_j7_have_regular_inc mean DIFF_j9_high_inc_month ///
	mean DIFF_j11_low_inc_month mean DIFF_hb0_bedroom_have mean DIFF_hb1_bedroom_elec mean DIFF_hb2_bedroom_bulb ///
	mean DIFF_hb3_bedroom_cfl mean DIFF_hb4_bedroom_tube mean DIFF_hb5_bedroom_plug mean DIFF_hk0_kitchen_have ///
	mean DIFF_hk1_kitchen_elec mean DIFF_hk2_kitchen_bulb mean DIFF_hk3_kitchen_cfl mean DIFF_hk4_kitchen_tube ///
	mean DIFF_hk5_kitchen_plug mean DIFF_hd0_livingroom_have mean DIFF_hd1_livingroom_elec mean DIFF_hd2_livingroom_bulb ///
	mean DIFF_hd3_livingroom_cfl mean DIFF_hd4_livingroom_tube mean DIFF_hd5_livingroom_plug mean DIFF_ht0_toilet_have ///
	mean DIFF_ht1_toilet_elec mean DIFF_ht2_toilet_bulb mean DIFF_ht3_toilet_cfl mean DIFF_ht4_toilet_tube ///
	mean DIFF_ht5_toilet_plug) oneway f(2p) sum npos(lab) ///
	h3( |E1-Elec Any|E5-Genset|E13-Solar|E19-Grid|E20-Metered|E21-Func Meter|E33-Billed|J7-Reg Inc|J9-HiInc Mth| ///
	J11-LoInc Mth|HB0-Have|HB1-Elec|HB2-Bulb|HB3-CFL|HB4-Tube|HB5-Plug|HK0|HK1|HK2|HK3|HK4|HK5| ///
	HD0|HD1|HD2|HD3|HD4|HD5|HT0|HT1|HT2|HT3|HT4|HT5)
	
	rename SUR_parent_key parent_key
	replace parent_key=lower(parent_key)
	tempfile HH_BC_DIFF
	save "`HH_BC_DIFF'"
	clear

	******BUSINESS******
	
	use `BIZ_SUR'
	merge 1:1 uid using `BIZ_BC', generate(mergeBIZBC)
	keep if mergeBIZBC == 3
	cfout using `BIZ_BC', id(uid) upper saving(BIZ_BACKCHECK_DIFFERENCES_`REPORT_DATE', masterval(SUR_) usingval(BC_) all(DIFF_) replace)
	clear

	//Reshaping the cumulative difference data
	use BIZ_BACKCHECK_DIFFERENCES_`REPORT_DATE'
	reshape wide SUR_ BC_ DIFF_, i(uid) j(Question) string
	
	//Generating section-wise error rates keeping only binary and categorical variables
	drop *h26_rental_inc_val *h28_profit
	local bc_sec `" "o" "a" "b" "e" "h" "' 
	foreach section in `bc_sec' {
		unab sec_ques: DIFF_`section'*
		egen error_rate_sec_`section'= rmean(`sec_ques')
	}
	unab section_OABEH: DIFF_o* DIFF_a* DIFF_b* DIFF_e* DIFF_h*
	egen error_rate_sec_oabeh = rmean(`section_OABEH')
	
	foreach var in `section_OABEH' {
	replace `var' = `var'*100
	}

	label var SUR_village_id1 "District Code"
	label var SUR_surveyor_code "Surveyor Code"
	label var BC_surveyor_code "Backchecker Code"

	// Outsheeting backcheck differences report							
	qui tabout SUR_village_id1 SUR_surveyor_code BC_surveyor_code using "`OUTPUT'/BIZ_BC_REPORT_`REPORT_DATE'.xls", mi rep ///
	c(mean DIFF_o1_retail mean DIFF_o1_retail_sector mean DIFF_o2_service mean DIFF_o2_service_sector mean DIFF_o3_workshop ///
	mean DIFF_o3_workshop_sector mean DIFF_a1_proprietor mean DIFF_b1_male_worker mean DIFF_b2_female_worker ///
	mean DIFF_b3_supervisor mean DIFF_b4_other mean DIFF_b5_family_member mean DIFF_e1_elec_any mean DIFF_e5_genset ///
	mean DIFF_e13_solar mean DIFF_e19_grid_conn mean DIFF_e20_bill_rent ///
	mean DIFF_e21_meter_have mean DIFF_e23_meter_functional mean DIFF_h25_rental_inc) ///
	oneway f(2p) sum npos(lab) ///
	h3( |O1-Ret|O1-Sec|O2-Serv|O2-Sec|O3-Work|O3-Sec|A1-Proprietor|B1-Male Work|B2-Female Work| ///
	B3-Supervisor|B4-Other|B5-Family|E1-Elec Any|E5-Genset|E13-Solar|E19-Grid|E20-Bill Rent| ///
	E21-Metered|E23-Func Meter|H25-Rent Inc)
	
	rename SUR_parent_key parent_key
	replace parent_key=lower(parent_key)
	tempfile BIZ_BC_DIFF
	save "`BIZ_BC_DIFF'"
	clear


* GENERATING REVISIT LIST FOR BACKCHECK AND SURVEY RECONCILIATION

	******HOUSEHOLD******
	
	// Merging raw data for PII to include in tracking sheet
	insheet using "`RAW_DATA'/BEP_HH_MID_V7_WIDE.csv", clear
	rename key parent_key
	keep parent_key cal_panchayat_name cal_block_name cal_pin_code cal_hh_head_name grp3resp_name
	merge 1:1 parent_key using `HH_BC_DIFF', generate(merge_PII)
	keep if merge_PII==3
	drop merge_PII
	rename cal_panchayat_name grampanchayat
	rename cal_block_name block
	rename cal_pin_code pin_code
	rename grp3resp_name respondent_name
	rename cal_hh_head_name hh_head_name
	
	split uid, parse(-) generate(village_id) destring
	rename village_id5 hh_id

	tempfile HH_RECON
	save "`HH_RECON'"
	clear

	// Merging names to include in tracking sheet
	insheet using "`ROOT'/Village_List.csv"
	keep village_id* district pss feeder area
	merge 1:m village_id1 village_id2 village_id3 village_id4 using `HH_RECON', gen(merge_Names)
	keep if merge_Names==3
	drop merge_Names
	sort village_id1 village_id2 village_id3 village_id4 hh_id
	tostring village_id1 village_id2 village_id3 village_id4, replace
	gen areaid= village_id1 + "-" + village_id2 + "-" + village_id3 + "-" + village_id4
	
	// Outsheeting reconciliation survey list
	outsheet parent_key areaid village_id1 village_id2 village_id3 village_id4 hh_id district pss feeder area grampanchayat ///
	block respondent_name hh_head_name DIFF_e1_elec_any DIFF_e5_genset DIFF_e13_solar DIFF_e19_grid_conn ///
	error_rate_sec_e error_rate_sec_ehj using "`OUTPUT'/HH_BC_RECON_LIST_`REPORT_DATE'.xls" ///
	if (DIFF_e1_elec_any==100|DIFF_e5_genset==100|DIFF_e13_solar==100|DIFF_e19_grid_conn==100), replace
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
	merge 1:1 parent_key using `BIZ_BC_DIFF', generate(merge_PII)
	keep if merge_PII==3
	drop merge_PII
	rename cal_panchayat_name grampanchayat
	rename cal_block_name block
	rename cal_pin_code pin_code
	rename bg4resp_name respondent_name
	rename cal_bus_name shop_name

	split uid, parse(-) generate(village_id) destring
	rename village_id5 biz_id

	tempfile BIZ_RECON
	save "`BIZ_RECON'"
	clear

	// Merging names to include in tracking sheet
	insheet using "`ROOT'/Market_List.csv"
	keep village_id* district pss feeder market
	merge 1:m village_id1 village_id2 village_id3 village_id4 using `BIZ_RECON', gen(merge_Names)
	keep if merge_Names==3
	drop merge_Names
	sort village_id1 village_id2 village_id3 village_id4 biz_id
	tostring village_id1 village_id2 village_id3 village_id4, replace
	gen marketid= village_id1 + "-" + village_id2 + "-" + village_id3 + "-" + village_id4

	// Outsheeting reconciliation survey list
	outsheet parent_key marketid village_id1 village_id2 village_id3 village_id4 biz_id district pss feeder market grampanchayat ///
	block respondent_name shop_name DIFF_e1_elec_any DIFF_e5_genset DIFF_e13_solar DIFF_e19_grid_conn ///
	error_rate_sec_e error_rate_sec_oabeh using "`OUTPUT'/BIZ_BC_RECON_LIST_`REPORT_DATE'.xls" ///
	if (DIFF_e1_elec_any==100|DIFF_e5_genset==100|DIFF_e13_solar==100|DIFF_e19_grid_conn==100), replace
	clear
