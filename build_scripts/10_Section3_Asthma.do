clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/10_Section3_Asthma, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end

local year = 1.25*365.25   //one year defined as 15 months


tempfile ocs_cl specialist_referral_cl smoking_cl SHsmoke_cl

use "`code_dir'/Asthma attack_v3", clear   //defined using OCS codes
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
compress
save `ocs_cl'

use "`code_dir'/Asthma specialist referral", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
compress
save `specialist_referral_cl'

use "`code_dir'/Smoking status", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
compress
save `smoking_cl'

use "`code_dir'/Secondhand smoke", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
compress
save `SHsmoke_cl'



use "`data_dir'/stata_data/PC_events", clear
drop if eventdate > `end'   //don't want any events after study date

drop if eventdate < `end'-`year'   //just from the past year

preserve  //====================================================================

drop if eventdate < `end'-365.25   //just from the past 12 months

merge m:1 readcode5B using `ocs_cl'
keep if _m == 3
drop _merge

gsort pracid patid eventdate

by pracid patid: gen skip = 1 if eventdate[_n-1]+14 > eventdate & _n != 1  //if previous <14 days ago

by pracid patid: gen course = 1 if skip != 1
by pracid patid: egen ocs_courses = total(course)

by pracid patid: keep if _n == 1
keep pracid patid ocs_courses

tab ocs_courses, missing

save "`data_dir'/temp/asthma_ocs", replace

restore, preserve  //===========================================================

drop if eventdate < `end'-365.25   //just from the past 12 months

merge m:1 readcode5B using `specialist_referral_cl', update
keep if _m == 3
drop _merge

gen referral = 1

gsort pracid patid -eventdate

by pracid patid: keep if _n == 1

keep pracid patid referral

save "`data_dir'/temp/asthma_specialist_referral", replace

restore, preserve  //===========================================================

merge m:1 readcode5B using `smoking_cl'
keep if _m == 3
drop _merge

label define smokstat 0 "Not asked about smoking" 1 "Never smoker" 2 "Ex smoker" ///
					  3 "Current smoker"
gen byte smokstat = 1 if category == "Never smoker"
replace smokstat = 2 if category == "Ex smoker"
replace smokstat = 3 if category == "Current smoker"
label values smokstat smokstat

gsort pracid patid -eventdate -smokstat

gen eversmoke = 1 if smokstat == 2 | smokstat == 3
by pracid patid: egen eversmoke_max = max(eversmoke)

by pracid patid: keep if _n == 1

//make never-smokers ex-smokers if they have smoking code in the past
replace smokstat = 2 if smokstat == 1 & eversmoke_max == 1

keep pracid patid smokstat

save "`data_dir'/temp/both_smokstat", replace

restore  //=====================================================================

merge m:1 readcode5B using `SHsmoke_cl'
keep if _m == 3
drop _merge

label define sh_smoke 0 "Not asked about second-hand smoke exposure" ///
					  1 "Not exposed to second-hand smoke" ///
					  2 "Exposed to second-hand smoke"

gen byte sh_smoke = 1 if category == "No Secondhand smoke"
replace sh_smoke = 2 if category == "Secondhand smoke"

label values sh_smoke sh_smoke

gsort pracid patid -eventdate -sh_smoke

gen eversh = 1 if sh_smoke == 2
by pracid patid: egen eversh_max = max(eversh)

by pracid patid: keep if _n == 1

//make never-exposed exposed if they have exposed code in the past
replace sh_smoke = 2 if eversh_max == 1

keep pracid patid sh_smoke

save "`data_dir'/temp/asthma_secondhand_smoke", replace



log close
