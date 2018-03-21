/********************************************************************************************************************************
Project: BEP

Purpose: Flagging differences between survey, backcheck and reconciliation data of hosuehold and business surveys on daily basis

Author:  Azhar Hussain

Date  :  16 September, 2015
*********************************************************************************************************************************/



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
	local OUTPUT  "`DROPBOX_ROOT'/Output/`TDATE'/Survey Reconciliation"


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
	
	//Recoding variables to missing values for skip codes and 0 for No
	recode e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have e21_meter_functional e33_receive_elecbill (2=0)
	
	//Generating UIDs
	egen uid=concat(village_id1 village_id2 village_id3 village_id4 hh_id), punct(-)
	gsort uid
	duplicates drop uid, force
	
	//Keeping relevant variables only
	keep village_id* hh_id parent_key surveyor_code uid e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have ///
	e21_meter_functional e33_receive_elecbill
	tempfile HH_BC
	save "`HH_BC'"
	clear
	
	******BUSINESS******
	
	use CUMULATIVE_BIZ_BC_`REPORT_DATE'
	
	//Renaming variables
	rename backchecker_code surveyor_code
	rename enquirygrp_consentgrp12c1_have_e e1_elec_any
	rename enquirygrp_consentgrp_c2c2_have_ e5_genset
	rename enquirygrp_consentgrp_c2c3_share e7_genset_owner
	rename enquirygrp_consentgrp_c2c4_hav_p e13_solar
	rename enquirygrp_consentgrp_c2c5_kind e14_solar_owner
	rename enquirygrp_consentgrp_c2c6_conne e19_grid_conn
	rename enquirygrp_consentgrp_c2c7_pay e20_bill_rent
	rename enquirygrp_consentgrp_c2grp13c8_ e21_meter_have
	rename enquirygrp_consentgrp_c2c9_funct e23_meter_functional

	//Recoding variables to missing values for skip codes and 0 for No
	recode e1_elec_any e5_genset e13_solar e19_grid_conn e20_bill_rent ///
	e21_meter_have e23_meter_functional (2=0)
	
	//Generating UIDs
	egen uid=concat(village_id1 village_id2 village_id3 village_id4 biz_id), punct(-)
	gsort uid
	duplicates drop uid, force
	
	//Keeping relevant variables only
	keep village_id* biz_id parent_key surveyor_code uid e1_elec_any e5_genset e7_genset_owner e13_solar ///
	e14_solar_owner e19_grid_conn e20_bill_rent e21_meter_have e23_meter_functional
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
	
	//Recoding variables to 0 for No
	recode e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have e21_meter_functional e33_receive_elecbill (2=0)

	//Generating unique IDs
	egen uid=concat(village_id1 village_id2 village_id3 village_id4 hh_id), punct(-)
	gsort uid
	duplicates drop uid, force
	
	//Keeping relevant variables only
	keep village_id* hh_id parent_key surveyor_code uid e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have ///
	e21_meter_functional e33_receive_elecbill
	tempfile HH_SUR
	save "`HH_SUR'"
	clear
	
	******BUSINESS******
	
	use CUMULATIVE_BIZ_`REPORT_DATE'_COMPLETE

	//Renaming variables
	rename secebg220e5_hav_gen e5_genset
	rename secebg220bg221e7_shared e7_genset_owner
	rename secebg220bg224e13_hav_panel e13_solar
	rename secebg220e14_to_e18e14_kind e14_solar_owner
	rename secebg220grp_e19e20_pay e20_bill_rent
	rename v667 e23_meter_functional
	
	//Recoding variables to missing values for skip codes
	recode e1_elec_any e5_genset e13_solar e19_grid_conn e20_bill_rent e21_meter_have e23_meter_functional (2=0)
	
	//Generating unique IDs
	egen uid=concat(village_id1 village_id2 village_id3 village_id4 biz_id), punct(-)
	gsort uid
	duplicates drop uid, force
	
	//Keeping relevant variables only
	keep village_id* biz_id parent_key surveyor_code uid e1_elec_any e5_genset e7_genset_owner ///
	e13_solar e14_solar_owner e19_grid_conn e20_bill_rent e21_meter_have e23_meter_functional
	tempfile BIZ_SUR
	save "`BIZ_SUR'"
	clear

	
* READING CUMULATIVE RECONCILIATION DATA

	******HOUSEHOLD******

	use CUMULATIVE_HH_RECON_`REPORT_DATE'

	//Renaming variables
	rename reconciliator_code surveyor_code
	rename consent_1grp72e1 e1_elec_any
	rename consent_1e5_to_e54e5 e5_genset
	rename consent_1e5_to_e54grp78e13 e13_solar
	rename consent_1e5_to_e54e19 e19_grid_conn
	rename consent_1e5_to_e54e20_to_e54e20e20_meter e20_meter_have
	rename consent_1e5_to_e54e20_to_e54e21 e21_meter_functional
	rename consent_1e5_to_e54e20_to_e54bill_situatione33 e33_receive_elecbill

	//Recoding variables to 0 for No
	recode e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have e21_meter_functional e33_receive_elecbill (2=0)

	//Generating unique IDs
	egen uid=concat(village_id1 village_id2 village_id3 village_id4 hh_id), punct(-)
	gsort uid
	duplicates drop uid, force
	
	//Keeping relevant variables only
	keep village_id* hh_id parent_key surveyor_code uid e1_elec_any e5_genset e13_solar e19_grid_conn e20_meter_have ///
	e21_meter_functional e33_receive_elecbill
	tempfile HH_REC
	save "`HH_REC'"
	clear

	******BUSINESS******
	
	use CUMULATIVE_BIZ_RECON_`REPORT_DATE'

	//Renaming variables
	rename reconciliator_code surveyor_code
	rename enquirybg219e1_have_elec e1_elec_any
	rename enquirybg220e5_hav_gen e5_genset
	rename enquirybg220bg221e7_shared e7_genset_owner
	rename enquirybg220bg224e13_hav_panel e13_solar
	rename enquirybg220e14_to_e18e14_kind e14_solar_owner
	rename enquirybg220e19_connection e19_grid_conn
	rename enquirybg220grp_e19e20_pay e20_bill_rent
	rename enquirybg220grp_e19bg226e21_meter e21_meter_have
	rename enquirybg220grp_e19bg226e21_to_e27e23_functional e23_meter_functional
	
	//Recoding variables to missing values for skip codes
	recode e1_elec_any e5_genset e13_solar e19_grid_conn e20_bill_rent e21_meter_have e23_meter_functional (2=0)
	
	//Generating unique IDs
	egen uid=concat(village_id1 village_id2 village_id3 village_id4 biz_id), punct(-)
	gsort uid
	duplicates drop uid, force
	
	//Keeping relevant variables only
	keep village_id* biz_id parent_key surveyor_code uid e1_elec_any e5_genset e7_genset_owner ///
	e13_solar e14_solar_owner e19_grid_conn e20_bill_rent e21_meter_have e23_meter_functional
	tempfile BIZ_REC
	save "`BIZ_REC'"
	clear


* COMPARING SURVEY, BACKCHECK AND RECONCILIATION DATA AND GENERATING DIFFERENCES REPORT
	//(Note: Reconciliation data is taken as a reference here with 100% accuracy, as it 
	//has been collected by field monitors, who are highly-trained senior field staff)

	*SURVEY AND RECONCILIATION DIFFERENCES*
	*-------------------------------------*
	
	******HOUSEHOLD******

	use `HH_REC'
	merge 1:1 uid using `HH_SUR', generate(mergeHHSUR)
	keep if mergeHHSUR == 3
	cfout using `HH_SUR', id(uid) upper saving(HH_SURVEY_RECONCILIATION_DIFFERENCES_`REPORT_DATE', masterval(REC_) usingval(SUR_) all(DIFF_) replace)
	clear

	//Reshaping the cumulative difference data
	use HH_SURVEY_RECONCILIATION_DIFFERENCES_`REPORT_DATE'
	reshape wide REC_ SUR_ DIFF_, i(uid) j(Question) string
	
	//Generating section-wise error rates
	unab e_sec_ques: DIFF_e*
	egen error_rate_sec_e= rmean(`e_sec_ques')
	
	foreach var in `e_sec_ques' {
	replace `var' = `var'*100
	}

	label var REC_village_id1 "District Code"
	label var SUR_surveyor_code "Surveyor Code"
	label var REC_surveyor_code "Reconciliator Code"

	// Outsheeting reconciliation and survey differences report							
	qui tabout REC_village_id1 REC_surveyor_code SUR_surveyor_code using "`OUTPUT'/HH_REC_SUR_REPORT_`REPORT_DATE'.xls", mi rep ///
	c(mean DIFF_e1_elec_any mean DIFF_e5_genset mean DIFF_e13_solar mean DIFF_e19_grid_conn mean DIFF_e20_meter_have ///
	mean DIFF_e21_meter_functional mean DIFF_e33_receive_elecbill) oneway f(2p) sum npos(lab) ///
	h3( |E1-Elec Any|E5-Genset|E13-Solar|E19-Grid|E20-Metered|E21-Func Meter|E33-Billed)

	rename SUR_parent_key parent_key
	replace parent_key=lower(parent_key)
	tempfile HH_REC_SUR_DIFF
	save "`HH_REC_SUR_DIFF'"
	clear

	******BUSINESS******
	
	use `BIZ_REC'
	merge 1:1 uid using `BIZ_SUR', generate(mergeBIZSUR)
	keep if mergeBIZSUR == 3
	cfout using `BIZ_SUR', id(uid) upper saving(BIZ_SURVEY_RECONCILIATION_DIFFERENCES_`REPORT_DATE', masterval(REC_) usingval(SUR_) all(DIFF_) replace)
	clear

	//Reshaping the cumulative difference data
	use BIZ_SURVEY_RECONCILIATION_DIFFERENCES_`REPORT_DATE'
	reshape wide REC_ SUR_ DIFF_, i(uid) j(Question) string

	//Generating section-wise error rates
	unab e_sec_ques: DIFF_e*
	egen error_rate_sec_e= rmean(`e_sec_ques')
	
	foreach var in `e_sec_ques' {
	replace `var' = `var'*100
	}

	label var REC_village_id1 "District Code"
	label var SUR_surveyor_code "Surveyor Code"
	label var REC_surveyor_code "Reconciliator Code"

	// Outsheeting backcheck differences report							
	qui tabout REC_village_id1 REC_surveyor_code SUR_surveyor_code using "`OUTPUT'/BIZ_REC_SUR_REPORT_`REPORT_DATE'.xls", mi rep ///
	c(mean DIFF_e1_elec_any mean DIFF_e5_genset mean DIFF_e7_genset_owner mean DIFF_e13_solar mean DIFF_e14_solar_owner ///
	mean DIFF_e19_grid_conn mean DIFF_e20_bill_rent mean DIFF_e21_meter_have mean DIFF_e23_meter_functional) ///
	oneway f(2p) sum npos(lab) ///
	h3( |E1-Elec Any|E5-Genset|E7-Genset Own|E13-Solar|E14-Solar Own|E19-Grid|E20-Bill Rent| ///
	E21-Metered|E23-Func Meter)

	rename REC_parent_key parent_key
	replace parent_key=lower(parent_key)
	tempfile BIZ_SUR_REC_DIFF
	save "`BIZ_SUR_REC_DIFF'"
	clear

	*BACKCHECK AND RECONCILIATION DIFFERENCES*
	*-------------------------------------*
	
	******HOUSEHOLD******

	use `HH_REC'
	merge 1:1 uid using `HH_BC', generate(mergeHHBC)
	keep if mergeHHBC == 3
	cfout using `HH_BC', id(uid) upper saving(HH_BACKCHECK_RECONCILIATION_DIFFERENCES_`REPORT_DATE', masterval(REC_) usingval(BC_) all(DIFF_) replace)
	clear

	//Reshaping the cumulative difference data
	use HH_BACKCHECK_RECONCILIATION_DIFFERENCES_`REPORT_DATE'
	reshape wide REC_ BC_ DIFF_, i(uid) j(Question) string
	
	//Generating section-wise error rates
	unab e_sec_ques: DIFF_e*
	egen error_rate_sec_e= rmean(`e_sec_ques')
	
	foreach var in `e_sec_ques' {
	replace `var' = `var'*100
	}

	label var REC_village_id1 "District Code"
	label var REC_surveyor_code "Reconciliator Code"
	label var BC_surveyor_code "Backchecker Code"

	// Outsheeting reconciliation and survey differences report							
	qui tabout REC_village_id1 REC_surveyor_code BC_surveyor_code using "`OUTPUT'/HH_REC_BC_REPORT_`REPORT_DATE'.xls", mi rep ///
	c(mean DIFF_e1_elec_any mean DIFF_e5_genset mean DIFF_e13_solar mean DIFF_e19_grid_conn mean DIFF_e20_meter_have ///
	mean DIFF_e21_meter_functional mean DIFF_e33_receive_elecbill) oneway f(2p) sum npos(lab) ///
	h3( |E1-Elec Any|E5-Genset|E13-Solar|E19-Grid|E20-Metered|E21-Func Meter|E33-Billed)

	rename REC_parent_key parent_key
	replace parent_key=lower(parent_key)
	tempfile HH_REC_BC_DIFF
	save "`HH_REC_BC_DIFF'"
	clear

	******BUSINESS******
	
	use `BIZ_REC'
	merge 1:1 uid using `BIZ_BC', generate(mergeBIZBC)
	keep if mergeBIZBC == 3
	cfout using `BIZ_BC', id(uid) upper saving(BIZ_BACKCHECK_RECONCILIATION_DIFFERENCES_`REPORT_DATE', masterval(REC_) usingval(BC_) all(DIFF_) replace)
	clear

	//Reshaping the cumulative difference data
	use BIZ_BACKCHECK_RECONCILIATION_DIFFERENCES_`REPORT_DATE'
	reshape wide REC_ BC_ DIFF_, i(uid) j(Question) string

	//Generating section-wise error rates
	unab e_sec_ques: DIFF_e*
	egen error_rate_sec_e= rmean(`e_sec_ques')
	
	foreach var in `e_sec_ques' {
	replace `var' = `var'*100
	}

	label var REC_village_id1 "District Code"
	label var REC_surveyor_code "Reconciliator Code"
	label var BC_surveyor_code "Backchecker Code"

	// Outsheeting backcheck differences report							
	qui tabout REC_village_id1 REC_surveyor_code BC_surveyor_code using "`OUTPUT'/BIZ_REC_BC_REPORT_`REPORT_DATE'.xls", mi rep ///
	c(mean DIFF_e1_elec_any mean DIFF_e5_genset mean DIFF_e7_genset_owner mean DIFF_e13_solar mean DIFF_e14_solar_owner ///
	mean DIFF_e19_grid_conn mean DIFF_e20_bill_rent mean DIFF_e21_meter_have mean DIFF_e23_meter_functional) ///
	oneway f(2p) sum npos(lab) ///
	h3( |E1-Elec Any|E5-Genset|E7-Genset Own|E13-Solar|E14-Solar Own|E19-Grid|E20-Bill Rent| ///
	E21-Metered|E23-Func Meter)

	rename REC_parent_key parent_key
	replace parent_key=lower(parent_key)
	tempfile BIZ_REC_BC_DIFF
	save "`BIZ_REC_BC_DIFF'"
	clear
