clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/09_Section3_COPD, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end

local year = 1.25*365.25   //one year defined as 15 months


tempfile mrc_cl fev1pp_cl o2_cl

use "`code_dir'/MRC Score", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
compress
save `mrc_cl'

use "`code_dir'/Spirometry", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
keep if category == "FEV1 %-predicted"
compress
save `fev1pp_cl'

use "`code_dir'/Oxygen_v3", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
compress
save `o2_cl'



use "`data_dir'/builds/copd_cohort_cm", clear
keep pracid patid firstcopd

merge 1:m pracid patid using "`data_dir'/stata_data/PC_events"
drop if _m == 2   //shouldn't be any from master that don't match
drop _merge

drop if eventdate > `end'   //don't want any events after study date

preserve  //====================================================================

/* MRC GRADE EVER */

merge m:1 readcode5B using `mrc_cl'
keep if _m == 3
drop _merge

tab desc, missing

gen mrc_grade_ever = substr(desc, 33, 1)
destring mrc_grade_ever, replace

tab desc mrc_grade_ever, missing

label define mrc 0 "Not recorded" 1 "MRC grade 1" 2 "MRC grade 2" 3 "MRC grade 3" ///
				 4 "MRC grade 4" 5 "MRC grade 5"
label values mrc_grade_ever mrc

tab mrc_grade_ever, missing

gsort pracid patid -eventdate -mrc_grade   //use worst case

by pracid patid: keep if _n == 1
keep pracid patid mrc_grade_ever

save "`data_dir'/temp/copd_mrc_ever", replace

restore, preserve  //===========================================================

/* MRC GRADE IN THE LAST YEAR */

drop if eventdate < `end'-`year'

merge m:1 readcode5B using `mrc_cl'
keep if _m == 3
drop _merge

tab desc, missing

gen mrc_grade = substr(desc, 33, 1)
destring mrc_grade, replace

tab desc mrc_grade, missing

label define mrc 0 "Not recorded" 1 "MRC grade 1" 2 "MRC grade 2" 3 "MRC grade 3" ///
				 4 "MRC grade 4" 5 "MRC grade 5"
label values mrc_grade mrc

tab mrc_grade, missing

gsort pracid patid -eventdate -mrc_grade   //use worst case

by pracid patid: keep if _n == 1
keep pracid patid mrc_grade

save "`data_dir'/temp/copd_mrc", replace

restore, preserve  //===========================================================

drop if eventdate < `end'-`year'

merge m:1 readcode5B using `fev1pp_cl'
keep if _m == 3
drop _merge

gsort pracid patid -eventdate

gen fev1pp = 1

by pracid patid: keep if _n == 1
keep pracid patid fev1pp

save "`data_dir'/temp/copd_fev1pp", replace

restore  //=====================================================================

drop if eventdate < `end'-(2*365.25)   //in the last 2 years

merge m:1 readcode5B using `o2_cl'
keep if _m == 3
drop _merge

tab category, missing
label list cat
/*
cat:
           1 Oxygen assessment
           2 Oxygen saturation
           3 Oxygen therapy
*/

drop if category == 2 & readcode_value > 92  //remove O2 sats over 92%

gen byte order = 2
replace order = 1 if category == 2

gsort pracid patid order -eventdate

//drop patients who don't have a recording of oxygen saturation
by pracid patid: drop if order[1] == 2

gen byte o2assess_single = 1
by pracid patid: replace o2assess_single = 0 if order[_N] == 1

by pracid patid: gen satgap = eventdate[_n-1]-eventdate if category == 2
gen satin90days = 1 if satgap <= 90
by pracid patid: egen satin90days_max = max(satin90days)

gen byte o2assess_persist = 1 if satin90days_max == 1
by pracid patid: replace o2assess_persist = 0 if satin90days_max == 1 & order[_N] == 1

by pracid patid: keep if _n == 1
keep pracid patid o2assess_single o2assess_persist

save "`data_dir'/temp/copd_o2assessment", replace




log close
