clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/14_Section4_Asthma, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end

local year = 1.25*365.25   //one year defined as 15 months


tempfile asthma_cl inhaledtherapy_cl inhalercheck_cl fluvax_cl smoking_cl smokcess_cl 

use "`code_dir'/Asthma", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
drop if category == "Asthma resolved"
drop category
compress
save `asthma_cl'

use "`code_dir'/Inhalers+LTRAs_v3", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
compress
save `inhaledtherapy_cl'

use "`code_dir'/Inhaler technique", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
compress
save `inhalercheck_cl'

use "`code_dir'/Flu vaccine", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
compress
save `fluvax_cl'

use "`code_dir'/Smoking status", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
compress
save `smoking_cl'

use "`code_dir'/Smoking cessation", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
compress
save `smokcess_cl'


use "`data_dir'/stata_data/PC_events", clear
drop if eventdate > `end'   //don't want any events after study date

preserve  //====================================================================

/* PERSONALISED ASTHMA ACTION PLAN (PAAP) */

drop if eventdate < `end'-`year'   //just from the past year

merge m:1 readcode5B using `asthma_cl'
keep if _m == 3
drop _merge

tab used_for, missing
keep if used_for == "PAAP"

gsort pracid patid -eventdate

gen byte paap = 1

by pracid patid: keep if _n == 1

keep pracid patid paap

tab paap, missing

save "`data_dir'/temp/asthma_paap", replace

restore, preserve  //===========================================================

/* RCP 3 Asthma Questions */

drop if eventdate < `end'-`year'   //just from the past year

merge m:1 readcode5B using `asthma_cl'
keep if _m == 3
drop _merge

tab used_for, missing
keep if used_for == "RCP 3Qs"

gsort pracid patid -eventdate

gen byte rcp3 = 1

by pracid patid: keep if _n == 1

keep pracid patid rcp3

tab rcp3, missing

save "`data_dir'/temp/asthma_rcp3", replace

restore, preserve  //===========================================================

/* SABA and ICS Inhalers */

drop if eventdate < `end'-365.25   //just from the past 12 months

merge m:1 readcode5B using `inhaledtherapy_cl'
keep if _m == 3
drop _merge

tab category, missing

keep if category == "SABA" | category == "ICS" | category == "LABA_ICS"

gsort pracid patid -eventdate

gen byte saba = 1 if category == "SABA"
by pracid patid: egen saba_count = total(saba)
gen byte saba_morethan2 = (saba_count > 2)

gen byte ics = 1 if category == "ICS" | category == "LABA_ICS"
by pracid patid: egen ics_count = total(ics)
gen byte ics_lessthan6 = (ics_count < 6)

by pracid patid: keep if _n == 1
keep pracid patid saba_count saba_morethan2 ics_count ics_lessthan6

save "`data_dir'/temp/asthma_inhalercounts", replace

restore, preserve  //===========================================================

/* INHALER CHECK */

drop if eventdate < `end'-`year'   //just from the past year

merge m:1 readcode5B using `inhaledtherapy_cl'
drop if _m == 2
rename _merge inhalers_merge

merge m:1 readcode5B using `inhalercheck_cl', update
drop if _m == 2
rename _merge check_merge

drop if inhalers_merge == 1 & check_merge == 1

tab category, missing

drop if category == "LTRA"

gen byte inhaler = 1 if inhalers_merge == 3
gen byte check = 1 if check_merge == 4
drop inhalers_merge check_merge

gsort pracid patid inhaler eventdate   //inhalers on top
by pracid patid: gen firstinhaler = eventdate[1] if inhaler[1] == 1
format %td firstinhaler
drop if eventdate < firstinhaler & check == 1   //remove checks before inhaler prescriptions

by pracid patid: egen inhaler_max = max(inhaler)
by pracid patid: egen check_max = max(check)

by pracid patid: keep if _n == 1

gen byte inhalercheck = (check_max == 1)

keep pracid patid inhalercheck

save "`data_dir'/temp/both_inhalercheck", replace

restore, preserve  //===========================================================

/* INFLUENZA IMMUNISATION */

//preceeding 1st August to 31st March
drop if eventdate < date("01/08/2018", "DMY")
drop if eventdate > date("31/03/2019", "DMY")
sum eventdate, format

merge m:1 readcode5B using `fluvax_cl'
keep if _m == 3
drop _merge

gsort pracid patid -eventdate

gen byte fluvax = 1

by pracid patid: keep if _n == 1

keep pracid patid fluvax

save "`data_dir'/temp/both_fluvaccine", replace

restore, preserve  //===========================================================

/* SMOKING CESSATION - CURRENT SMOKER IN LAST 2 YEARS */

drop if eventdate < `end'-(2*365.25)

merge m:1 readcode5B using `smoking_cl'
keep if _m == 3
drop _merge

tab category, missing

keep if category == "Current smoker"

gsort pracid patid -eventdate

gen byte smokerlast2yrs = 1

by pracid patid: keep if _n == 1

keep pracid patid smokerlast2yrs

save "`data_dir'/temp/both_smokingcess_smokerslast2yrs", replace

restore, preserve  //===========================================================

/* SMOKING CESSATION - BEHAVIOUR CHANGE INTERVENTION + DRUG */

drop if eventdate < `end'-`year'   //just from the past year

merge m:1 readcode5B using `smokcess_cl'
keep if _m == 3
drop _merge

tab category, missing
label list cat
/*
cat:
           1 Behavioural change intervention
           2 Drug
*/

gsort pracid patid -eventdate

gen bci  = 1 if cat == 1
gen drug = 1 if cat == 2

by pracid patid: egen smokcess_bci  = max(bci)
by pracid patid: egen smokcess_drug = max(drug)

by pracid patid: keep if _n == 1

keep pracid patid smokcess_bci smokcess_drug

save "`data_dir'/temp/both_smokingcess_bci_drug", replace

restore  //=====================================================================

/* INHALED THERAPY */

drop if eventdate < `end'-(0.5*365.25)   //last 6 months

merge m:1 readcode5B using `inhaledtherapy_cl'
keep if _m == 3
drop _merge

tab category, missing
keep if category == "ICS" | category == "LABA" | category == "LABA_ICS" ///
		| category == "LTRA"

gsort pracid patid -eventdate category

gen byte inhaledtherapy = 1

gen byte ics = 1 if category == "ICS" | category == "LABA_ICS"
gen byte laba = 1 if category == "LABA" | category == "LABA_ICS"
gen byte ltra = 1 if category == "LTRA"

//therapy in the last 90s
by pracid patid: gen ics90 = 1 if eventdate > eventdate[1]-90 & ics == 1
by pracid patid: gen laba90 = 1 if eventdate > eventdate[1]-90 & laba == 1
by pracid patid: gen ltra90 = 1 if eventdate > eventdate[1]-90 & ltra == 1

by pracid patid: egen ics90_max = max(ics90)
by pracid patid: egen laba90_max = max(laba90)
by pracid patid: egen ltra90_max = max(ltra90)

by pracid patid: keep if _n == 1

drop ics laba ltra ics90 laba90 ltra90

label define asthmatherapy 1 "ICS" 2 "LABA" 3 "LABA + ICS" 4 "LTRA" ///
						   5 "LTRA + ICS" 6 "LTRA + LABA + ICS"

gen therapy_type = 1 if ics90_max == 1
replace therapy_type = 2 if laba90_max == 1
replace therapy_type = 4 if ltra90_max == 1

replace therapy_type = 3 if laba90_max == 1 & ics90_max == 1

replace therapy_type = 5 if ltra90_max == 1 & ics90_max == 1

replace therapy_type = 6 if ltra90_max == 1 & laba90_max == 1 & ics90_max == 1

label values therapy_type asthmatherapy

keep pracid patid inhaledtherapy therapy_type

save "`data_dir'/temp/asthma_inhaledtherapy", replace



log close
