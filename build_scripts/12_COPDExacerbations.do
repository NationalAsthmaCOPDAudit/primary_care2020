clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/12_COPDExacerbations, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end

local year = 1.25*365.25   //one year defined as 15 months


tempfile copd_exacer_cl

use "`code_dir'/COPD exacerbations_v3", clear
duplicates list readcode5B
duplicates tag readcode5B, gen(dup)
list if dup > 0
duplicates drop readcode5B, force
drop dup
tab category, missing
compress
save `copd_exacer_cl'


use "`data_dir'/builds/copd_cohort", clear

merge 1:m pracid patid using "`data_dir'/stata_data/PC_events"
drop if _m == 2   //shouldn't be any from master that don't match
drop _merge

drop if eventdate > `end'   //don't want any events after study date

drop if eventdate < `end'-`year'   //just from the past year

merge m:1 readcode5B using `copd_exacer_cl'
keep if _m == 3
drop _merge

//Missing exacerbation count is useless
//(66Yf = Number of COPD exacerbations in past year)
drop if readcode5B == "66Yf." & readcode_value == .

//Remove events before COPD diagnosis
//drop if eventdate < firstcopd

preserve  //=====================GP RECORDED YEARLY TOTAL=======================

keep if readcode5B == "66Yf."

gsort pracid patid -eventdate -readcode_value  //use worst case for same-day counts

by pracid patid: keep if _n == 1

rename readcode_value gp_copdexac_count

tab gp_copdexac_count, missing

keep pracid patid gp_copdexac_count

save "`data_dir'/temp/copd_gprec_exacerbation", replace

restore, preserve  //======================GP RECORDED==========================

drop if eventdate < `end'-365.25   //just from the past 12 months

tab category, missing
label list category
/*
category:
           1 Broad Spectrum Penicillins
           2 Doxycycline
           3 Macrolides
           4 Quinolone
           5 Oral Steroids
           6 LRTI
           7 Exacerbations
*/

//Remove anything other than exacerbation events
keep if category == 7

//Remove GP recorded cumulative exacerbation count
drop if readcode5B == "66Yf."

gsort pracid patid eventdate

//Mark events to be excluded if they are closer together than 14 days
by pracid patid: gen byte exclude = 1 if eventdate[_n-1]+14 > eventdate & _n != 1

//Mark GP recorded exacerbations
by pracid patid: gen byte gp_copdexac = 1 if exclude != 1

by pracid patid: egen gp_copdexacs = total(gp_copdexac)

by pracid patid: keep if _n == 1

tab gp_copdexacs, missing

keep pracid patid gp_copdexacs

save "`data_dir'/temp/copd_gp_exacerbation", replace

restore  //======================VALIDATED METHODOLOGY==========================

drop if eventdate < `end'-365.25   //just from the past 12 months

//Remove GP recorded cumulative exacerbation count
drop if readcode5B == "66Yf."

tab category, missing
label list category
/*
category:
           1 Broad Spectrum Penicillins
           2 Doxycycline
           3 Macrolides
           4 Quinolone
           5 Oral Steroids
           6 LRTI
           7 Exacerbations
*/

//Bottom = Exacerbations, LRTI
gen byte order = 3
//Top = Penicillins, Doxycycline, Marcolides, Quinolone
replace order = 1 if category == 1 | category == 2 | category == 3 | category == 4
//2nd = Oral steroids
replace order = 2 if category == 5

tab category order, missing

gsort pracid patid eventdate order

//Label antibiotics that have an oral steroid prescription on the same day
by pracid patid: gen byte ocs_ab_sameday = 1 ///
			if order == 1 & order[_n+1] == 2 & eventdate == eventdate[_n+1]

tab ocs_ab_sameday, missing

//Drop oral steroid prescriptions or antiobiotic prescriptions that don't occur on the same day
drop if order == 2 | (order == 1 & ocs_ab_sameday != 1)

//Mark events to be excluded if they are closer together than 14 days
by pracid patid: gen byte exclude = 1 if eventdate[_n-1]+14 > eventdate & _n != 1

tab exclude, missing

//Mark separate exacerbation events
by pracid patid: gen byte copdexacer = 1 if exclude != 1

//Generate total number of exacerbations for patient
by pracid patid: egen copdexacerbations = total(copdexacer)

by pracid patid: keep if _n == 1

tab copdexacerbations, missing

keep pracid patid copdexacerbations

save "`data_dir'/temp/copd_validated_exacerbation", replace




log close
