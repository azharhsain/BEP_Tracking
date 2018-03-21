/***********************************************************************
Project: BEP

Purpose: Tracking midline household and business surveys on daily basis

Author:  Azhar Hussain

Date  :  15 July, 2015
************************************************************************/



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
	local OUTPUT  "`DROPBOX_ROOT'/Output/`TDATE'/Survey Tracking"


* READING DAILY HOUSEHOLD SURVEY TRACKING SHEET

	insheet using "`SURVEY_TRACK'//Household Survey/Household_Survey_Tracking_`REPORT_DATE'.csv"
	drop if missing(areaid)
	quietly tostring status*, replace
	format status* %30s
	
	//Reshaping the tracking sheet to long format
	reshape long hh code status, i(areaid) j(hh_pos)
	drop if missing(hh)
	
	//Survey status codes
	gen survey_status=.
	replace survey_status=1 if status=="1-Complete"
	replace survey_status=2 if status=="2-Left Village/Market"
	replace survey_status=3 if status=="3-Respondent partially unavailable"
	replace survey_status=4 if status=="4-Respondent completely unavailable"
	replace survey_status=5 if status=="5-Did not consent"
	replace survey_status=6 if status=="6-Refused to complete survey midway"
	replace survey_status=7 if status=="7-HH/B not found"
	replace survey_status=8 if status=="8-Others"
	drop if survey_status== 3
		
	//Formatting survey tracking date
	gen datex=subinstr(date,"-","",.)
	gen survey_tracking_date=date(date,"DMY")
	format survey_tracking_date %td

	//Identifying completed households
	gen flag_hh_complete=0
	replace flag_hh_complete=1 if (survey_status==1)

	//Creating village ids and household ids
	split areaid, p(-) generate(village_id)
	destring village_id* hh, replace
	rename hh hh_id
	rename code surveyor_code
	rename teamcode supervisor_code	
	destring supervisor_code, force replace 
	gsort village_id1 village_id2 village_id3 village_id4 hh_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 hh_id, generate(duphh)
	br if duphh!=0
	//Stop the program if duplicates are found in tracking sheet
	if duphh!=0{
	exit
	}
	
	tempfile HH_DAILY_TRACKING
	save "`HH_DAILY_TRACKING'"

	clear
	

* READING DAILY BUSINESS SURVEY TRACKING SHEET

	insheet using "`SURVEY_TRACK'//Business Survey/Business_Survey_Tracking_`REPORT_DATE'.csv"
	drop if missing(marketid)
	quietly tostring status*, replace
	format status* %30s

	//Survey status codes
	generate survey_status1=.
	generate survey_status2=.
	generate survey_status3=.
	foreach i of numlist 1/3 {
		replace survey_status`i'=1 if status`i'=="1-Complete"
		replace survey_status`i'=2 if status`i'=="2-Left Village/Market"
		replace survey_status`i'=3 if status`i'=="3-Respondent partially unavailable"
		replace survey_status`i'=4 if status`i'=="4-Respondent completely unavailable"
		replace survey_status`i'=5 if status`i'=="5-Did not consent"
		replace survey_status`i'=6 if status`i'=="6-Refused to complete survey midway"
		replace survey_status`i'=7 if status`i'=="7-HH/B not found"
		replace survey_status`i'=8 if status`i'=="8-Others"
	}
	generate survey_status=.
	replace survey_status= survey_status3 if (!missing(survey_status3))
	replace survey_status= survey_status2 if (!missing(survey_status2) & missing(survey_status3))
	replace survey_status= survey_status1 if (!missing(survey_status1) & missing(survey_status2) & missing(survey_status3))
	drop if survey_status== 3
	
	//Formatting survey tracking date
	foreach i of numlist 1/3 {
		cap gen datex`i'=subinstr(visit`i'date,"-","",.)
		cap gen survey_tracking_date`i'=date(visit`i'date,"DMY")
		cap format survey_tracking_date`i' %td
	}
	
	//Identifying completed businesses
	gen flag_biz_complete=0
	replace flag_biz_complete=1 if survey_status==1

	//Creating market ids and business ids
	split marketid, p(-) generate(village_id)
	destring village_id* bizid, replace
	rename bizid biz_id
	rename code1 surveyor1_code
	rename code2 surveyor2_code
	rename code3 surveyor3_code
	generate surveyor_code=.	
	replace surveyor_code= surveyor3_code if (!missing(surveyor3_code))
	replace surveyor_code= surveyor2_code if (!missing(surveyor2_code) & missing(surveyor3_code))
	replace surveyor_code= surveyor1_code if (!missing(surveyor1_code) & missing(surveyor2_code) & missing(surveyor3_code))	
	rename teamcode supervisor_code
	destring supervisor_code, force replace 
	gsort village_id1 village_id2 village_id3 village_id4 biz_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 biz_id, generate(dupbiz)
	br if dupbiz!=0
	//Stop the program if duplicates are found in tracking sheet
	if dupbiz!=0{
	exit
	}

	tempfile BIZ_DAILY_TRACKING
	save "`BIZ_DAILY_TRACKING'"
	
	clear
	

* READING DAILY RAW DATA AND CONVERTING TO .DTA FORMAT

	****Business****
	cd "`RAW_DATA'"
	insheet using "BEP_Busi_MID_V7_WIDE.csv"
	rename key parent_key
	
	//Changing status codes of some surveys, where surveyors used wrong status codes, based on Animesh's feedback
	replace stat_code1= 4 if inlist(parent_key, "uuid:b6e056b0-0b1a-4b93-85c4-7f0e5e564b81", "uuid:677789bc-2cc1-412e-803f-d0abeebbe8a4")

	drop if stat_code1== 3
	tempfile Business7
	save "`Business7'"
	
	clear
	
	insheet using "BEP_Busi_MID_V8_WIDE.csv"
	rename key parent_key
	
	//Changing status codes of some surveys, where surveyors used wrong status codes, based on Animesh's feedback
	replace stat_code1= 4 if inlist(parent_key, "uuid:9b22ef27-4d1e-4357-9cea-06ccb445f024", "uuid:b72d4ead-51a3-42d5-9854-cb939bf1a76f", ///
	"uuid:8e703162-884c-44fe-b663-4cf338e5a081")
	replace stat_code1= 4 if inlist(parent_key, "uuid:89557b0c-7b9a-4b03-a70b-d967e08ae78d")
	
	drop if stat_code1== 3
	tempfile Business8
	save "`Business8'"
	
	clear
	
	use `Business7'
	append using `Business8', force
	tempfile Business
	save "`Business'"

	clear	

	****Household****
	cd "`RAW_DATA'"
	insheet using "BEP_HH_MID_V7_WIDE.csv"
	rename key parent_key
	
	//Changing status codes of some surveys, where surveyors used wrong status codes, based on Animesh's feedback
	replace stat_code1= 4 if inlist(parent_key, "uuid:1696f6ef-1ee0-49b6-9914-90a4f10b7ed9", "uuid:34105287-a40b-434d-8014-5939c4ee3a51", ///
	"uuid:eca41816-ead3-4c93-9f3a-589ce8f89b82")
	replace stat_code1= 4 if inlist(parent_key, "uuid:41d906d9-73fc-4b43-b342-91d3474fca1a", "uuid:da316f6f-fbd7-4600-a2b9-a9b9ea941f58", ///
	"uuid:629fcd66-5509-450f-baa5-ae16c6a57e29")
	replace stat_code1= 4 if inlist(parent_key, "uuid:9febb74e-f94e-4ced-a8d0-eb5c3b057001", "uuid:bc59be0b-113d-4d72-9d23-eb0a1b3073b7", ///
	"uuid:582a80e3-228f-45f4-902f-51b2c9997810")
	replace stat_code1= 4 if inlist(parent_key, "uuid:a075039f-63f8-4d88-aa3d-34df0a30c912", "uuid:0101c9b1-415f-40ac-8d7d-6dc689f8b45d")

	drop if stat_code1== 3
	tempfile Household
	save "`Household'"
	clear


* HOUSEHOLD SURVEY DAILY TRACKING

	use `Household'

	//Generating relevant date variables
	gen survey_start_date = date("24Jul2015","DMY")
	gen today = date("`TDATE'", "DMY")
	gen report_dt = date("`REPORT_DATE'", "DMY")
	gen submission_date = date(submissiondate, "DMYhms")
	gen start_date = date(starttime, "DMYhms")
	gen end_date = date(endtime, "DMYhms")
	format submission_date start_date end_date today %td
	gen survey_mins=(clock(endtime, "DMYhms")-clock(starttime, "DMYhms"))/60000
	format survey_mins %3.2f

	//Eliminating pilot surveys done
	keep if start_date >= survey_start_date
	keep if start_date<=report_dt

	//Removing outliers such as second visits and other outlier cases which take too long
	gen survey_mins_adj=survey_mins
	replace survey_mins_adj=. if survey_mins>120

	//Surveyor and supervisor codes
	rename grp7surveyor_name surveyor_name
	rename grp7surveyor_code surveyor_code
	rename grp7team_code supervisor_code

	//Renaming village IDs to assign codes to district, pss, feeder and village
	rename market_idvil_id_1 village_id1
	rename market_idvil_id_2 village_id2
	rename market_idvil_id_3 village_id3
	rename market_idvil_id_4 village_id4
	destring village_id* hh_id, replace
	
	//Making corrections to incorrect IDs entered based on feedback received from Animesh
	*30/07/2015
	replace surveyor_code= 120 if parent_key== "uuid:890cff9f-f8a5-4c5a-998a-7e5791c9178b"
	*31/07/2015
	replace supervisor_code= 301 if inlist(parent_key, "uuid:8841240b-9887-4f4c-b8ef-a73017e1ddf4", "uuid:917377f6-3ee4-4021-9728-925b60f09c63", ///
	"uuid:4575c0e7-a3a7-45bf-bae1-bcdb73569cb1")
	replace supervisor_code= 301 if inlist(parent_key, "uuid:40abb5da-eaf4-466b-be03-7f37c87b018e", "uuid:28410c2f-160c-49a2-808c-28d82b430e57", ///
	"uuid:b3a40d50-d330-4097-9d01-dd1ca1726a19")
	replace supervisor_code= 301 if inlist(parent_key, "uuid:3f34d1ff-2239-425d-b44c-297a096979b2", "uuid:e4e3c64a-63c6-45b8-b7ce-de290fc3b186", ///
	"uuid:ca08493a-77ea-4fb9-9ca9-110fb294c4a1")
	replace supervisor_code= 301 if inlist(parent_key, "uuid:b6bf5d49-89da-40f7-9992-4ed3395ae697", "uuid:9d9b207c-6ac5-4690-9ebd-e7084b44c1b5", ///
	"uuid:5f6a4ee5-cfc8-4d2b-b120-fd0c3a822acc")
	replace supervisor_code= 301 if inlist(parent_key, "uuid:6b360393-8247-420a-bdf8-ae49bf08ced7", "uuid:7fac525a-12b2-4423-b6b9-3ca97c4d0a81", ///
	"uuid:656737ce-db24-45bd-83b2-68e8520b977e")
	replace supervisor_code= 301 if inlist(parent_key, "uuid:37816bf4-f8a6-41d1-99a4-b6e759c0962d")
	replace supervisor_code= 301 if inlist(parent_key, "uuid:f18f30bf-b98c-4d2c-b482-13155a1ab966", "uuid:bcb63eed-19ae-4754-9054-8c0869803d48", ///
	"uuid:e365ade2-d3ed-4875-97b8-03c638f52666")
	replace supervisor_code= 301 if inlist(parent_key, "uuid:6ce9df1b-73d2-4e9c-806c-e95ca779d78f")
	replace supervisor_code= 308 if inlist(parent_key, "uuid:7142544c-4b88-4436-a357-9e4d530656af")
	replace supervisor_code= 301 if inlist(parent_key, "uuid:cfc5f4a7-335d-4330-95aa-8ee14d85a670", "uuid:e8258b5b-cfab-4e68-9389-018f38d52698", ///
	"uuid:a18a5244-1f17-46ab-8b60-f4293bd59b1a")
	replace supervisor_code= 306 if inlist(parent_key, "uuid:d555c6b8-69ab-47a7-b278-06c193f3c683", "uuid:8d8e5fb0-1991-465a-9e0f-825260ee3b90", ///
	"uuid:a1fdce2f-cb4a-426b-8a44-7b4037275e51")
	replace supervisor_code= 306 if inlist(parent_key, "uuid:e9d40af5-c74a-43fa-ba40-600ec57ae1f1")
	replace supervisor_code= 302 if inlist(parent_key, "uuid:45a5351d-e4a3-485e-8079-ef6557cb4364", "uuid:0ce4f17e-4080-45b9-b7b8-18346100fdb0", ///
	"uuid:eb43a5b0-380c-44b9-ab7c-4d8bc593a851")
	replace supervisor_code= 302 if inlist(parent_key, "uuid:fc7822eb-e0d7-410d-bcb7-64b7d1391ff1", "uuid:474de0dc-e471-453b-99ad-ee5b7cc38f9c")
	replace supervisor_code= 302 if inlist(parent_key, "uuid:8ee8ac8f-738e-4c56-8294-1f573c599693", "uuid:1471783b-b675-4b79-b2b9-587de1358adb", ///
	"uuid:64ce8b36-1197-4c59-8557-e6aab507a78c")
	replace surveyor_code= 118 if inlist(parent_key, "uuid:0ce4f17e-4080-45b9-b7b8-18346100fdb0")
	replace surveyor_code= 131 if inlist(parent_key, "uuid:2986a039-39f4-46a1-81ae-95206d2e30b8")
	*01/08/2015
	replace supervisor_code= 305 if inlist(parent_key, "uuid:f18f30bf-b98c-4d2c-b482-13155a1ab966", "uuid:bcb63eed-19ae-4754-9054-8c0869803d48", ///
	"uuid:e365ade2-d3ed-4875-97b8-03c638f52666")
	replace supervisor_code= 305 if inlist(parent_key, "uuid:6ce9df1b-73d2-4e9c-806c-e95ca779d78f", "uuid:423dd436-3d1a-4f7c-ae5c-0b73c6174e0c", ///
	"uuid:44f658a4-c24b-40e3-afc8-115b6f5c1651")
	replace supervisor_code= 305 if inlist(parent_key, "uuid:a4af940a-4fe1-4451-8086-2c36f1291730", "uuid:24cd8403-f06a-4acc-96cc-2908c320a614")
	replace supervisor_code= 307 if inlist(parent_key, "uuid:39a1d170-8166-40a0-bc2a-ba28ed5b137f")
	replace supervisor_code= 306 if inlist(parent_key, "uuid:8ee8ac8f-738e-4c56-8294-1f573c599693", "uuid:1471783b-b675-4b79-b2b9-587de1358adb", ///
	"uuid:64ce8b36-1197-4c59-8557-e6aab507a78c")
	replace supervisor_code= 306 if inlist(parent_key, "uuid:ff0c74ba-2ac1-48f3-865f-8576d27083db", "uuid:e1d616e3-cde9-4e73-b0ee-f752e52d016a", ///
	"uuid:ccdc7c8c-86e7-4367-a098-e3593ea17a15")
	replace supervisor_code= 306 if inlist(parent_key, "uuid:362dc703-3408-4e3c-a21b-63c9599a2028", "uuid:a2c575b5-6db3-4f26-a989-513dbc59e3d2", ///
	"uuid:258c4d53-46a6-4df5-88c4-2ff9b4991e9c")
	*05/08/2015
	replace supervisor_code= 305 if inlist(parent_key, "uuid:35123bc6-cd7a-41ef-9cd4-1e0d8a1c6f00")
	drop if inlist(parent_key, "uuid:25b164da-6940-4a55-bc96-dbf2c7123774")
	*06/08/2015
	replace supervisor_code= 305 if inlist(parent_key, "uuid:8098f84b-b7a3-4bae-8780-60f0f0890a81", "uuid:1841837c-8748-4deb-bb67-f0f507844228")
	*07/08/2015
	drop if inlist(parent_key, "uuid:5c0ac94d-a5a8-47ce-8347-f9e24703bee7")
	replace supervisor_code= 301 if inlist(parent_key, "uuid:339ffbea-7443-4158-b7c0-813537d5c4d9")
	*13/08/2015
	replace supervisor_code= 306 if inlist(parent_key, "uuid:2b483005-7eaf-4f85-b200-b9672a9debd5", "uuid:b54fbb2b-011d-4ff0-9043-958008767175")
	*15/08/2015
	replace supervisor_code= 305 if inlist(parent_key, "uuid:b5ba4a38-f64c-4ad6-a46c-3701031ad3c7")
	replace supervisor_code= 303 if inlist(parent_key, "uuid:a20a1b44-6adb-4ae7-8484-e5685d09584b")	
	*17/08/2015
	replace supervisor_code= 308 if inlist(parent_key, "uuid:c5bdbbb9-121b-4bba-a40b-7cf8f3cbcc07","uuid:70fc4f10-5657-4d58-880d-3da6dc9f0b39")
	*20/08/2015
	replace supervisor_code= 308 if inlist(parent_key, "uuid:01fbecab-265e-4456-9c61-3350b88f440d")
	replace supervisor_code= 305 if inlist(parent_key, "uuid:c6f5faa2-c163-42ce-83e2-0887b52c7f32")
	*22/08/2015
	replace supervisor_code= 304 if inlist(parent_key, "uuid:f860616d-79f8-49cc-b5b3-ede37c3147c9")
	*18/09/2015
	replace supervisor_code= 302 if inlist(parent_key, "uuid:fe681912-04e1-44a4-a005-6d7457d2aa9c")

	//Resolving survey duplicates based on feedback received from Animesh
	*01/08/2015
	drop if inlist(parent_key, "uuid:b89c1204-a6ab-4e2c-92c0-3d10b50f1b8f", "uuid:51800408-c450-499e-8120-58e3e9cf2b39", ///
	"uuid:f8b287eb-9c49-4b43-92fe-c9af50f51c0f")
	drop if inlist(parent_key, "uuid:f493adc2-193c-4800-b565-670ca5ff4885", "uuid:acfe8d9b-6675-4aec-8118-055473a23e0f", ///
	"uuid:6a78cefb-718f-4cae-9146-9c7fe447cfc8")
	drop if inlist(parent_key, "uuid:4b4bd369-d049-4625-90ff-06ddc2b58b04", "uuid:e6b4f39a-0913-4f69-9335-9c3619225d81")
	*09/08/2015
	drop if inlist(parent_key, "uuid:b0826197-6df2-4136-b806-3eeefbbaf1f9", "uuid:971c0ce5-902f-4540-be80-abf5d08bcc60")
	*10/08/2015
	drop if inlist(parent_key, "uuid:02a071c3-52cd-4153-a819-30c77629f1c1")	
	*12/08/2015
	drop if inlist(parent_key, "uuid:a793fa1b-6c44-4389-aca6-8f58c8ca39b1", "uuid:f1011ab5-f489-44c3-a700-d761231841e3")
	drop if inlist(parent_key, "uuid:d555c6b8-69ab-47a7-b278-06c193f3c683", "uuid:8ca3c9d1-312e-44cc-9f09-d91b51b4d68e", ///
	"uuid:faefaaab-2d6e-4369-b465-3f5b5a34dd94")
	*13/08/2015
	drop if inlist(parent_key, "uuid:afec3346-6a6d-4177-9fcb-de4823cd2cbb", "uuid:5f3049eb-86f5-49dc-9374-76c06767d1c6", ///
	"uuid:faefaaab-2d6e-4369-b465-3f5b5a34dd94")
	*14/08/2015
	drop if inlist(parent_key, "uuid:3471fffc-f32f-4759-96ad-b0b69d16a1d1", "uuid:faefaaab-2d6e-4369-b465-3f5b5a34dd94")
	*15/08/2015
	drop if inlist(parent_key, "uuid:61a859c6-d6d4-4091-8a75-710b98ac9fd5")
	*19/08/2015
	drop if inlist(parent_key, "uuid:eec7aec6-f8fb-4b8e-ab7c-61892ab35e09", "uuid:dce29a67-dd3a-4a53-a710-f7ff237ae4d0", ///
	"uuid:aed71c24-616f-40aa-998e-b41cf9906bc3")
	drop if inlist(parent_key, "uuid:592e82b4-2760-4e4b-8373-4846ef5ca92e", "uuid:d45ef3c5-f567-4c02-a02b-c2c19be76d1c", ///
	"uuid:d9456aa5-2fa1-4d95-af15-f0ca6c9742b9")
	drop if inlist(parent_key, "uuid:71e248d1-ec69-4c0b-b5c9-b16001265b3a", "uuid:dc4d2d8f-9c07-4ff2-8f54-906ab4629892")
	*20/08/2015
	drop if inlist(parent_key, "uuid:b7bab1a5-26d8-4328-90a1-7c227a92d5b7", "uuid:d91229ac-96d4-45c3-b98c-af46d66842ea")
	*21/08/2015
	drop if inlist(parent_key, "uuid:f639b282-c606-44c2-9ba1-1eaf057a45cd", "uuid:8ad90541-f355-4e76-8928-8d6b49990acf", ///
	"uuid:d1b3f80b-ed37-45d8-886a-e14eb4cd7cbb")
	*25/08/2015
	drop if inlist(parent_key, "uuid:c80051d5-6c3e-4f59-858f-54d06556df33")
	*08/09/2015
	drop if inlist(parent_key, "uuid:56ac52b0-50a7-41b8-a2b0-3fa53622a640", "uuid:a55acdbd-4d73-4f50-898f-0af4dbe20335")
	*16/09/2015
	drop if inlist(parent_key, "uuid:0952ea24-d656-4793-afda-d9d27c6a9358")

	//Generating area id for tracking results
	generate area_id = string(village_id1)+"-"+string(village_id2)+"-"+string(village_id3)+"-"+string(village_id4)
	gsort village_id1 village_id2 village_id3 village_id4 hh_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 hh_id, generate(duphh)
	tab duphh

	//Outputting duplicate surveys to be resolved							
	preserve
	keep if duphh!=0	
	keep village_id1 village_id2 village_id3 village_id4 area_id hh_id start_date ///
	surveyor_name surveyor_code supervisor_code parent_key 						
	outsheet using "`OUTPUT'/DUPLICATE_SURVEYS_HH_`REPORT_DATE'.xls", replace
	restore
	
	//Merging tracking and survey data
	merge m:1 village_id1 village_id2 village_id3 village_id4 hh_id supervisor_code surveyor_code using "`HH_DAILY_TRACKING'", generate (mergeHHTracking)
	label define tracking 1 "DDC Data only" 2 "Tracking Sheet only" 3 "Both DDC data and Tracking sheet"
	label values mergeHHTracking tracking

	//Outsheeting  surveyor mismatches to be resolved
	preserve
	keep if ((mergeHHTracking==1 & !missing(surveyor_code)) | (mergeHHTracking==2 & !missing(surveyor_code)))
	keep village_id1 village_id2 village_id3 village_id4 area_id hh_id surveyor_code start_date ///
	survey_tracking_date surveyor_name surveyor_code supervisor_code mergeHHTracking parent_key 						
	outsheet using "`OUTPUT'/HH_SURVEYOR_ID_MISMATCH_`REPORT_DATE'.xls", replace
	restore

	//Dropping PII before saving working data on Dropbox
	drop cal_hh_num infost cal_build_name cal_street_name cal_area_name cal_panchayat_name cal_block_name cal_dist_name ///
	cal_pin_code cal_hh_head_name grp2_0hh_num	grp2_0build_name grp2_0street_name grp2_0area_name grp2panchayat_name ///
	grp2block_name grp2dist_name grp2pin_code grp2hh_head_name grp3info2 grp3resp_name grp3phone_num

	//Saving cumulative working files without PII
	cd "`WORKING_DATA'"
	save CUMULATIVE_HH_`REPORT_DATE', replace

	clear


* BUSINESS SURVEY DAILY TRACKING

	use `Business'
	gen survey_start_date = date("24Jul2015","DMY")
	gen today = date("`TDATE'", "DMY")
	gen report_dt = date("`REPORT_DATE'", "DMY")
	gen submission_date = date(submissiondate, "DMYhms")
	gen start_date = date(starttime, "DMYhms")
	gen end_date = date(endtime, "DMYhms")
	format submission_date start_date end_date today %td
	gen survey_mins=(clock(endtime, "DMYhms")-clock(starttime, "DMYhms"))/60000
	format survey_mins %3.2f

	//Eliminating pilot surveys done
	keep if start_date >= survey_start_date
	keep if start_date<=report_dt

	//Removing outliers such as second visits and other outlier cases which take too long
	gen survey_mins_adj=survey_mins
	replace survey_mins_adj=. if survey_mins>120
	  
	//Surveyor and supervisor codes
	rename surveyorsur_name surveyor_name
	rename surveyorsur_code surveyor_code
	rename surveyormoni_code supervisor_code	

	//Renaming village IDs to assign codes to district, pss, feeder and village
	rename grp1vil_id_1 village_id1
	rename grp1vil_id_2 village_id2
	rename grp1vil_id_3 village_id3
	rename grp1vil_id_4 village_id4
	rename firm_id biz_id
	destring village_id* biz_id, replace

	//Making corrections to incorrect IDs entered based on feedback received from Animesh
	*30/07/2015
	replace surveyor_code= 102 if parent_key== "uuid:e2158439-e7df-4ddb-a45f-04076596b2a5"
	*03/08/2015
	replace surveyor_code= 106 if parent_key== "uuid:a0cb0b2b-f73e-480e-8afc-808ab30b0940"
	*05/08/2015
	replace supervisor_code= 303 if parent_key== "uuid:13601624-4e75-4ae9-819e-29907ca3243a"
	drop if parent_key== "uuid:f87c5970-e70f-4fc1-9052-a06fa7139741"
	*13/08/2015
	drop if parent_key== "uuid:52cb45f8-370f-4b6f-b824-5c5a52a9bb66"
	*25/08/2015
	replace supervisor_code= 305 if parent_key== "uuid:ad024e6d-1378-41ff-80b6-bf38bc2c2941"
	
	//Resolving survey duplicates based on feedback received from Animesh
	*01/08/2015
	drop if parent_key== "uuid:b3e8e455-12a3-4c64-8b45-cb57bfd96558"
	*08/08/2015
	drop if parent_key== "uuid:782912b7-1674-4a3b-ae51-7aaf4736bc2b"
	*12/08/2015
	drop if inlist(parent_key, "uuid:9f55d2de-93f2-4510-b5ef-9895affeb029", "uuid:2ac9d61a-b342-49a1-9d15-ddf842c442e2")
	*13/08/2015
	drop if inlist(parent_key, "uuid:7d108f68-ae09-4bc5-8ad5-d0ec7d1f1e91", "uuid:74b2aca8-e91b-452c-945c-a786cdd0fc16" ///
	"uuid:dc4c3f02-bfcd-4148-8717-ef73bf90f1e0")
	*14/08/2015
	drop if inlist(parent_key, "uuid:6f80caf1-00f3-4073-a6a6-e2f996892851", "uuid:dc4c3f02-bfcd-4148-8717-ef73bf90f1e0")
	*21/08/2015
	drop if inlist(parent_key, "uuid:fc7451e8-17f8-49e9-a4af-ceadcebb3a21", "uuid:0b5d0c44-b12c-45d7-939e-48bb890efcad")
	*22/08/2015	
	drop if inlist(parent_key, "uuid:f9dfe53a-1a0a-42ce-b24f-77279cfe699c")
	*08/09/2015
	drop if inlist(parent_key, "uuid:a1b2efc7-60c7-46b0-972e-888574dfda1a", "uuid:f8229419-7e28-4c31-bc63-8ac994c5c617", ///
	"uuid:16191a55-1ea4-423d-b86e-e5accabafdcc")
	drop if inlist(parent_key, "uuid:16a62368-280c-4571-bcc0-1f0d75bb85c4", "uuid:847ffe62-eb38-44f6-ac6b-3ac87d35bf30", ///
	"uuid:57f6b257-6275-480a-8783-598fa5f303d6")
	*18/09/2015
	drop if parent_key== "uuid:a1d1ac6e-ae89-4cd0-9cc1-560ab573cb77"	
	
	//Generating area id for tracking results
	generate area_id = string(village_id1)+"-"+string(village_id2)+"-"+string(village_id3)+"-"+string(village_id4)
	gsort village_id1 village_id2 village_id3 village_id4 biz_id
	duplicates tag village_id1 village_id2 village_id3 village_id4 biz_id, generate(dupbiz)
	tab dupbiz

	//Outputting surveyor duplicates to be resolved							
	preserve
	keep if dupbiz!=0
	keep village_id1 village_id2 village_id3 village_id4 area_id biz_id start_date ///
	surveyor_name surveyor_code supervisor_code parent_key 						
	outsheet using "`OUTPUT'/DUPLICATE_SURVEYS_BIZ_`REPORT_DATE'.xls", replace
	restore

	//Merging tracking and survey data
	merge m:1 village_id1 village_id2 village_id3 village_id4 biz_id supervisor_code surveyor_code using "`BIZ_DAILY_TRACKING'", generate (mergeBizTracking)
	label define tracking 1 "DDC Data only" 2 "Tracking Sheet only" 3 "Both DDC data and Tracking sheet"
	label values mergeBizTracking tracking

	//Outsheeting village and biz id mismatches to be resolved
	preserve
	keep if ((mergeBizTracking==1 )| (mergeBizTracking==2) & !missing(surveyor_code))
	keep village_id1 village_id2 village_id3 village_id4 area_id biz_id ///
	start_date	survey_tracking_date* ///
	surveyor_name surveyor_code supervisor_code mergeBizTracking parent_key 						
	outsheet using "`OUTPUT'/BIZ_SURVEYOR_ID_MISMATCH_`REPORT_DATE'.xls", replace
	restore

	//Dropping PII before saving working data on Dropbox
	drop cal_firm_id infost cal_shop_num cal_street_name cal_area_name cal_panchayat_name cal_block_name cal_dist_name ///
	cal_pin_code cal_bus_name intro4 bg3town_name bg3bloc_name bg3dist_name bg3pin_code bg3bus_name ///
	bg4bus_info bg4bus_name bg4resp_name bg4resp_phno

	//Saving cumulative working files without PII
	cd "`WORKING_DATA'"
	save CUMULATIVE_BIZ_`REPORT_DATE', replace

	clear
