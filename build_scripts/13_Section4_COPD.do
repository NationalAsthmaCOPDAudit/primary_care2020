clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/13_Section4_COPD, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end

local year = 1.25*365.25   //one year defined as 15 months


tempfile pr_cl  inhaledtherapy_cl

use "`code_dir'/Pulmonary Rehabilitation", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab desc, missing  //includes declined/exception codes
compress
save `pr_cl'

use "`code_dir'/Inhalers+LTRAs_v3", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
compress
save `inhaledtherapy_cl'


use "`data_dir'/builds/copd_cohort", clear

merge 1:m pracid patid using "`data_dir'/stata_data/PC_events"
drop if _m == 2   //shouldn't be any from master that don't match
drop _merge

drop if eventdate > `end'   //don't want any events after study date

preserve  //====================================================================

/* PR REFERRAL */

drop if eventdate < `end'-(3*365.25)   //last 3 years

merge m:1 readcode5B using `pr_cl'
keep if _m == 3
drop _merge

gsort pracid patid -eventdate

gen byte pr_ref = 1

// maybe remove declined/unsuitable codes

by pracid patid: keep if _n == 1

keep pracid patid pr_ref

save "`data_dir'/temp/copd_pr_referral", replace

restore  //=====================================================================

/* INHALED THERAPY */

drop if eventdate < `end'-(0.5*365.25)   //last 6 months

merge m:1 readcode5B using `inhaledtherapy_cl'
keep if _m == 3
drop _merge

tab category, missing
keep if category == "ICS" | category == "LABA" | category == "LABA_ICS" ///
		| category == "LAMA" | category == "LABA_LAMA"

gsort pracid patid -eventdate category

gen byte inhaledtherapy = 1

gen byte ics = 1 if category == "ICS" | category == "LABA_ICS"
gen byte laba = 1 if category == "LABA" | category == "LABA_ICS" | category == "LABA_LAMA"
gen byte lama = 1 if category == "LAMA" | category == "LABA_LAMA"

//therapy in the last 90s
by pracid patid: gen ics90 = 1 if eventdate > eventdate[1]-90 & ics == 1
by pracid patid: gen laba90 = 1 if eventdate > eventdate[1]-90 & laba == 1
by pracid patid: gen lama90 = 1 if eventdate > eventdate[1]-90 & lama == 1

by pracid patid: egen ics90_max = max(ics90)
by pracid patid: egen laba90_max = max(laba90)
by pracid patid: egen lama90_max = max(lama90)

by pracid patid: keep if _n == 1

drop ics laba lama ics90 laba90 lama90

label define copdtherapy 1 "ICS" 2 "LABA" 3 "LABA + ICS" 4 "LAMA" 5 "LABA + LAMA" ///
						 6 "Triple therapy"

gen therapy_type = 1 if ics90_max == 1
replace therapy_type = 2 if laba90_max == 1
replace therapy_type = 4 if lama90_max == 1

replace therapy_type = 3 if laba90_max == 1 & ics90_max == 1

replace therapy_type = 5 if laba90_max == 1 & lama90_max == 1

replace therapy_type = 6 if laba90_max == 1 & lama90_max == 1 & ics90_max == 1

label values therapy_type copdtherapy

keep pracid patid inhaledtherapy therapy_type

save "`data_dir'/temp/copd_inhaledtherapy", replace



log close
