clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/07_Spirometry, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end


tempfile spirom_cl

use "`code_dir'/Spirometry", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
compress
tab category, missing
save `spirom_cl'

/*
use "`data_dir'/builds/copd_cohort_cm", clear
keep pracid patid gender age wimd_rank firstcopd

drop if firstcopd < `end'-(2*365.25)
count

keep pracid patid  //don't need the other vars any more

merge 1:m pracid patid using "`data_dir'/stata_data/PC_events"
drop if _m == 2   //shouldn't be any from master that don't match
drop _merge
*/
use "`data_dir'/stata_data/PC_events", clear  //comment out if removing above out-commenting
drop if eventdate > `end'

merge m:1 readcode5B using `spirom_cl'
tab category _merge
keep if _m == 3
drop _merge

//FEV1/FVC Ratio after bronchodilator (339m) cleaning
display "FEV1/FVC ratio cleaning:"
gen byte cleanme = 0
replace cleanme = 1 if readcode5B == "3398." | readcode5B == "3399." | readcode5B == "339M." ///
					 | readcode5B == "339O1" | readcode5B == "339R." | readcode5B == "339T." ///
					 | readcode5B == "339U." | readcode5B == "339j." | readcode5B == "339k." ///
					 | readcode5B == "339l." | readcode5B == "339m." | readcode5B == "339r."
sum readcode_value if cleanme == 1, detail
replace readcode_value = readcode_value/100 if readcode_value > 1 & cleanme == 1
replace readcode_value = . if readcode_value > 1   & cleanme == 1
replace readcode_value = . if readcode_value < 0.2 & cleanme == 1

//Check the value has been cleaned properly
tab readcode5B if cleanme == 1
sum readcode_value if cleanme == 1, detail
drop cleanme


preserve  //=========================PEAK FLOW EVER=============================

keep if category == "Peak flow"
tab category, missing

gsort pracid patid -eventdate

gen byte anypeakflow_ever = 1

by pracid patid: keep if _n ==1

keep pracid patid anypeakflow_ever

compress
save "`data_dir'/temp/asthma_ever_anypeakflow", replace

restore, preserve  //===========================================================

keep if category == "Peak flow"
tab category, missing

keep if readcode5B == "339A." | readcode5B == "339B."

gsort pracid patid -eventdate

gen byte prepostpeakflow_ever = 1

by pracid patid: keep if _n == 1

keep pracid patid prepostpeakflow_ever

compress
save "`data_dir'/temp/asthma_ever_pre_post_peakflow", replace

restore, preserve  //===========================================================

keep if category == "Peak flow"
tab category, missing

keep if readcode5B == "66YY."

gsort pracid patid -eventdate

gen byte peakflowdiary_ever = 1

by pracid patid: keep if _n == 1

keep pracid patid peakflowdiary_ever

compress
save "`data_dir'/temp/asthma_ever_peakflow_diary", replace

restore  //=====================================================================

drop if eventdate < `end'-(2*365.25)  //just want events from past 2 years

preserve  //======================PEAK FLOW LAST 2 YEARS========================

keep if category == "Peak flow"
tab category, missing

gsort pracid patid -eventdate

gen byte anypeakflow = 1

by pracid patid: keep if _n ==1

keep pracid patid anypeakflow

compress
save "`data_dir'/temp/asthma_2yr_anypeakflow", replace

restore, preserve  //===========================================================

keep if category == "Peak flow"
tab category, missing

keep if readcode5B == "339A." | readcode5B == "339B."

gsort pracid patid -eventdate

gen byte prepostpeakflow = 1

by pracid patid: keep if _n == 1

keep pracid patid prepostpeakflow

compress
save "`data_dir'/temp/asthma_2yr_pre_post_peakflow", replace

restore, preserve  //===========================================================

keep if category == "Peak flow"
tab category, missing

keep if readcode5B == "66YY."

gsort pracid patid -eventdate

gen byte peakflowdiary = 1

by pracid patid: keep if _n == 1

keep pracid patid peakflowdiary

compress
save "`data_dir'/temp/asthma_2yr_peakflow_diary", replace

restore, preserve  //================SPIROMETRY & REVERSIBILITY=================

drop if category == "Peak flow"
tab category, missing

gsort pracid patid -eventdate

gen byte anyspirom = 1

by pracid patid: keep if _n ==1

keep pracid patid anyspirom

compress
save "`data_dir'/temp/asthma_anyspirom", replace

restore, preserve  //===========================================================

drop if category == "Peak flow"
tab category, missing

keep if readcode5B == "339M." | readcode5B == "339l." | readcode5B == "339m." ///
		| category == "Reversibility"

tab readcode5B category, missing

gsort pracid patid -eventdate

by pracid patid: gen ratio = 1 if category == "FEV1/FVC ratio"
by pracid patid: gen reverse = 1 if category == "Reversibility"

by pracid patid: egen ratioever = max(ratio)
by pracid patid: egen reverseever = max(reverse)

by pracid patid: gen ratio_reverse = 1 if ratioever == 1 & reverseever == 1

by pracid patid: keep if _n == 1
keep if ratio_reverse == 1

keep pracid patid ratio_reverse

compress
save "`data_dir'/temp/asthma_ratio_reversibility", replace

restore, preserve  //===========================================================

drop if category == "Peak flow"
tab category, missing

gsort pracid patid -eventdate

by pracid patid: gen spirom = 1 if category != "Reversibility"
by pracid patid: gen reverse = 1 if category == "Reversibility"

by pracid patid: egen spiromever = max(spirom)
by pracid patid: egen reverseever = max(reverse)

by pracid patid: gen spirom_reverse = 1 if spiromever == 1 & reverseever == 1

by pracid patid: keep if _n == 1
keep if spirom_reverse == 1

keep pracid patid spirom_reverse

compress
save "`data_dir'/temp/asthma_spirometry_reversibility", replace

restore  //=====================================================================

keep if category == "FEV1/FVC ratio"

preserve  //=========================FEV1/FVC RATIO=============================

keep if readcode5B == "339m."

gsort pracid patid -eventdate readcode_value
by pracid patid: keep if _n == 1

gen byte anypostbd = 1
gen byte postbdobstruction = 1 if readcode_value < 0.7 & readcode_value >= 0.2

keep pracid patid anypostbd postbdobstruction

compress
save "`data_dir'/temp/both_postbd_spirom", replace

restore, preserve  //===========================================================

keep if readcode5B == "339m."
drop if readcode_value == .

gsort pracid patid -eventdate readcode_value
by pracid patid: keep if _n == 1

gen byte valid_postbdobs = 1 if readcode_value < 0.7 & readcode_value >= 0.2
label var valid_postbdobs "Most recent valid obstruction result"

keep if valid_postbdobs == 1
keep pracid patid valid_postbdobs

compress
save "`data_dir'/temp/both_postbd_spirom_valid", replace

restore, preserve  //===========================================================

gsort pracid patid -eventdate readcode_value
by pracid patid: keep if _n == 1

gen byte anyobstruction = 1 if readcode_value < 0.7 & readcode_value >= 0.2

keep if anyobstruction == 1
keep pracid patid anyobstruction

compress
save "`data_dir'/temp/both_any_spirom_ratio", replace

restore, preserve  //===========================================================

drop if readcode_value == .

gsort pracid patid -eventdate readcode_value
by pracid patid: keep if _n == 1

gen byte valid_anyobs = 1 if readcode_value < 0.7 & readcode_value >= 0.2

keep if valid_anyobs == 1
keep pracid patid valid_anyobs

compress
save "`data_dir'/temp/both_any_spirom_ratio_valid", replace

restore  //=====================================================================

keep if readcode5B == "339l."  //pre-bonchodilator

gsort pracid patid -eventdate readcode_value
by pracid patid: keep if _n == 1

gen byte anyprebd = 1
gen byte prebdobstruction = 1 if readcode_value < 0.7 & readcode_value >= 0.2

keep pracid patid anyprebd prebdobstruction

compress
save "`data_dir'/temp/asthma_prebd_spirom", replace



log close
