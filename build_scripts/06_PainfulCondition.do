clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/06_PainfulCondition, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end


tempfile pain_cl

use "`code_dir'/comorbidities/Painful conditions_previous", clear
duplicates list readcode5B
duplicates drop readcode5B, force
drop desc  //only need the category
compress
save `pain_cl'


local cohorts "copd asthma_adult"

foreach cohort of local cohorts {

	use "`data_dir'/builds/`cohort'_cohort_cm", clear
	keep pracid patid gender age wimd_rank firstcopd epilepsy

	merge 1:m pracid patid using "`data_dir'/stata_data/PC_events"
	drop if _m == 2   //shouldn't be any from master that don't match
	drop _merge

	drop if eventdate > `end'

	merge m:1 readcode5B using `pain_cl'
	tab category _merge
	keep if _m == 3
	drop _merge

	tab category, missing

	//Remove events more than 12 months ago
	//(we're interested in prescriptions from last 12 months)
	drop if eventdate < `end'-365.25

	label list category
	/*
	category:
			   1 Pain medication
			   2 Epilepsy medication
	*/

	//Remove patients with anti-epileptics if they are epileptic at time of prescription
	gsort pracid patid category eventdate

	by pracid patid category: drop if category == 2 ///
									& epilepsy != . ///
									& epilepsy < eventdate

	/* Patient is defined as having a painful condition if they have 4 or more
	 * prescriptions for analgesics or anti-epileptics (in the absence of an epilepsy
	 * diagnosis [removed by above code]) in the past 12 months */

	gen byte pain = 0
	by pracid patid: replace pain = 1 if _N > 3
	by pracid patid: keep if _n == 1
	keep pracid patid pain
	drop if pain == 0

	compress
	save "`data_dir'/temp/`cohort'_painful_condition", replace
}

/** This is the code to merge in the pain var **
use "`data_dir'/builds/copd_cohort_cm", clear
merge 1:1 pracid patid using `pain_tmp'
drop _merge   //all from using should be matched
replace pain = 0 if pain == .
*/

log close
