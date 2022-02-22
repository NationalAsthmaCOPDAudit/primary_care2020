clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/11_AsthmaExacerbations, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end

local year = 1.25*365.25   //one year defined as 15 months


tempfile asthma_cl ocs_cl

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

use "`code_dir'/Asthma attack_v3", clear   //defined using OCS codes
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
drop category
compress
save `ocs_cl'



use "`data_dir'/stata_data/PC_events"
drop if eventdate > `end'   //don't want any events after study date

drop if eventdate < `end'-`year'   //just from the past year

preserve  //=====================GP RECORDED YEARLY TOTAL=======================

merge m:1 readcode5B using `asthma_cl'
keep if _m == 3
drop _merge

tab used_for, missing
keep if used_for == "Exacerbation"
tab desc, missing

//663y. - Number of asthma exacerbations in past year
keep if readcode5B == "663y."
drop if readcode_value == .

gen gp_asthmaexac_count = readcode_value

gsort pracid patid -eventdate -gp_asthmaexac_count  //use worst case for same-day counts

by pracid patid: keep if _n == 1

tab gp_asthmaexac_count, missing

keep pracid patid gp_asthmaexac_count

save "`data_dir'/temp/asthma_gprec_exacerbation", replace

restore, preserve  //======================GP RECORDED==========================

drop if eventdate < `end'-365.25   //just from the past 12 months

merge m:1 readcode5B using `asthma_cl'
keep if _m == 3
drop _merge

tab used_for, missing
keep if used_for == "Exacerbation"
tab desc, missing

drop if readcode5B == "663y."

gsort pracid patid eventdate

//Mark events to be excluded if they are closer together than 14 days
by pracid patid: gen byte exclude = 1 if eventdate[_n-1]+14 > eventdate & _n != 1

//Mark GP recorded exacerbations
by pracid patid: gen byte gp_asthmaexac = 1 if exclude != 1

by pracid patid: egen gp_asthmaexacs = total(gp_asthmaexac)

by pracid patid: keep if _n == 1

tab gp_asthmaexacs, missing

keep pracid patid gp_asthmaexacs

save "`data_dir'/temp/asthma_gp_exacerbation", replace

restore  //======================VALIDATED METHODOLOGY==========================

drop if eventdate < `end'-365.25   //just from the past 12 months

merge m:1 readcode5B using `ocs_cl'
drop if _m == 2
rename _merge ocs_merge

merge m:1 readcode5B using `asthma_cl', update
drop if _m == 2
rename _merge asthma_merge

drop if ocs_merge == 1 & asthma_merge == 1
drop if ocs_merge == 1 & used_for != "Validated Exacerbation"

gen annualreview = (used_for == "Validated Exacerbation")

drop ocs_merge asthma_merge used_in used_for

//remove patients that only have annual review codes
gsort pracid patid annualreview
by pracid patid: drop if annualreview[1] == 1

gsort pracid patid eventdate -annualreview

//exclude prescriptions on same day as review
//exclude events closer than 14 days
//count events

by pracid patid eventdate: gen byte revday = 1 if annualreview[1] == 1

gsort pracid patid annualreview eventdate

//Mark events to be excluded if they are closer together than 14 days
by pracid patid: gen byte exclude = 1 if eventdate[_n-1]+14 > eventdate & _n != 1 ///
									   & annualreview == 0

//Mark exacerbations
by pracid patid: gen byte asthmaexac = 1 if exclude != 1 & revday != 1

by pracid patid: egen asthmaexacs = total(asthmaexac)

by pracid patid: keep if _n == 1

tab asthmaexacs, missing

keep pracid patid asthmaexacs

save "`data_dir'/temp/asthma_validated_exacerbation", replace



log close
