clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/08_Section2, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end


tempfile xray_cl feno_cl

use "`code_dir'/Chest x-ray", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
compress
save `xray_cl'

use "`code_dir'/FeNO", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
compress
save `feno_cl'


use "`data_dir'/builds/copd_cohort_cm", clear
keep pracid patid firstcopd

drop if firstcopd < `end'-(2*365.25)   //COPD diagnoses in the past 2 years
count

merge 1:m pracid patid using "`data_dir'/stata_data/PC_events"
drop if _m == 2   //shouldn't be any from master that don't match
drop _merge

drop if eventdate > `end'

merge m:1 readcode5B using `xray_cl'
keep if _m == 3
drop _merge


gen before_copd = eventdate if eventdate <= firstcopd
gen after_copd = eventdate if eventdate > firstcopd

gsort pracid patid -before_copd
by pracid patid: gen xray_before = before_copd[1]
drop before_copd

gsort pracid patid after_copd
by pracid patid: gen xray_after = after_copd[1]
drop after_copd

format %td xray_before xray_after

by pracid patid: keep if _n == 1
keep pracid patid xray_before xray_after

compress
save "`data_dir'/temp/copd_xray", replace



use "`data_dir'/stata_data/PC_events", clear
drop if eventdate > `end'
drop if eventdate < `end'-(2*365.25)  //just want events from past 2 years

merge m:1 readcode5B using `feno_cl'
keep if _m == 3
drop _merge

gsort pracid patid -eventdate

gen byte feno = 1

by pracid patid: keep if _n == 1
keep pracid patid feno

compress
save "`data_dir'/temp/asthma_feno", replace



log close
