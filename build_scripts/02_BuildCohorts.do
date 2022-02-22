clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* Create log file */
capture log close
log using build_logs/02_BuildCohorts, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end


tempfile copd asthma

use "`code_dir'/COPD", clear
duplicates list readcode5B
duplicates drop readcode5B, force
save `copd'

use "`code_dir'/Asthma", clear
duplicates list readcode5B
duplicates drop readcode5B, force
save `asthma'

//==============================================================================

use "`data_dir'/stata_data/PC_patients", clear

duplicates list pracid patid   //there shouldn't be any

tab gender, missing
drop if gender == 3   //very few unknown, won't be used in any analysis, not worth keeping.
tab gender, missing

sum age, detail
drop if age < 1
drop if age > 120

merge 1:m pracid patid using "`data_dir'/stata_data/PC_events"
drop if _merge == 2
drop _merge

sum eventdate, detail format
drop if eventdate > `end'

preserve  //====================================================================

merge m:1 readcode5B using `copd'
keep if _merge == 3
drop _merge

tab category, missing

gsort pracid patid -eventdate -category  //resolved codes at top if on same day

gen byte resolved = 0
by pracid patid: replace resolved = 1 if category[1] == "COPD resolved"

tab resolved
drop if resolved == 1  //remove patients with most recent code as resolved
drop resolved


gsort pracid patid eventdate -category
by pracid patid: gen resolved = 1 if category[1] == "COPD resolved"
tab resolved

//remove first code(s) if it's a resolved code
gen drop = 0
by pracid patid: replace drop = 1 if (resolved == 1 & _n == 1) | ///
									 (resolved == 1 & drop[_n-1] == 1 & ///
									 category == "COPD resolved")
drop if drop == 1
drop resolved drop

by pracid patid: keep if _n == 1
rename eventdate firstcopd

drop readcode5B readcode_value category desc

drop if age < 35

compress
count
save "`data_dir'/builds/copd_cohort", replace

restore  //=====================================================================

merge m:1 readcode5B using `asthma'
keep if _merge == 3
drop _merge

tab category, missing

gsort pracid patid -eventdate -category  //resolved codes at top if on same day

gen byte resolved = 0
by pracid patid: replace resolved = 1 if category[1] == "Asthma resolved"

tab resolved
drop if resolved == 1  //remove patients with most recent code as resolved
drop resolved

drop if eventdate < `end' - (3*365.25)  //only want recent diagnoses (last 3 yrs)

gsort pracid patid eventdate -category
by pracid patid: gen resolved = 1 if category[1] == "Asthma resolved"
tab resolved

//remove first code(s) if it's a resolved code
gen drop = 0
by pracid patid: replace drop = 1 if (resolved == 1 & _n == 1) | ///
									 (resolved == 1 & drop[_n-1] == 1 & ///
									 category == "Asthma resolved")
drop if drop == 1
drop resolved drop

by pracid patid: keep if _n == 1
rename eventdate firstasthma

drop readcode5B readcode_value category desc used_in used_for

preserve
drop if age <= 18
compress
count
save "`data_dir'/builds/asthma_adult_cohort", replace
restore

drop if age > 18

preserve
drop if age < 6
compress
count
save "`data_dir'/builds/asthma_child_6-18_cohort", replace
restore

drop if age > 5
drop if age < 1
compress
count
save "`data_dir'/builds/asthma_child_1-5_cohort", replace


log close
