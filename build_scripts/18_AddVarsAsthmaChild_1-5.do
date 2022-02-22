clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/18_AddVarsAsthmaChild_1-5, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end


use "`data_dir'/builds/asthma_child_1-5_cohort_cm2", clear


// SECTION 3 - REFERRAL TO SPECIALIST CARE

merge 1:1 pracid patid using "`data_dir'/temp/asthma_ocs"
drop if _merge == 2
drop _merge

replace ocs_courses = 0 if ocs_courses == .

gen byte ocscourses2orfewer = (ocs_courses <= 2)

tab1 ocs_courses ocscourses2orfewer, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_specialist_referral"
drop if _merge == 2
drop _merge

replace referral = 0 if referral == .

gen byte ocs3plusref = (ocs_courses >= 3 & referral == 1)

tab1 referral ocs3plusref, missing


// SECTION 3 - SECOND-HAND SMOKE EXPOSURE

merge 1:1 pracid patid using "`data_dir'/temp/asthma_secondhand_smoke"
drop if _merge == 2
drop _merge

replace sh_smoke = 0 if sh_smoke == .

tab1 sh_smoke, missing


// SECTION 3 - EXACERBATIONS

merge 1:1 pracid patid using "`data_dir'/temp/asthma_gprec_exacerbation"   //GP RECORDED ANNUAL COUNT
drop if _merge == 2
drop _merge

replace gp_asthmaexac_count = 0 if gp_asthmaexac_count == .

tab1 gp_asthmaexac_count, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_gp_exacerbation"   //COUNT OF GP RECORDED EXACERBATIONS
drop if _merge == 2
drop _merge

replace gp_asthmaexacs = 0 if gp_asthmaexacs == .

tab1 gp_asthmaexacs, missing


//remove unlikely values
replace gp_asthmaexac_count = 0 if gp_asthmaexac_count > 26
replace gp_asthmaexacs      = 0 if gp_asthmaexac_count > 26

gen gp_exacerbations     = gp_asthmaexac_count
replace gp_exacerbations = gp_asthmaexacs if gp_asthmaexacs > gp_asthmaexac_count

tab1 gp_exacerbations, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_validated_exacerbation"   //VALIDATED EXACERBATIONS
drop if _merge == 2
drop _merge

replace asthmaexacs = 0 if asthmaexacs == .

tab1 asthmaexacs, missing


//generate categories
label define exacer_cat 3 ">2"

foreach var in gp_exacerbations asthmaexacs {

	gen     `var'_cat = `var'
	replace `var'_cat = 3 if `var' > 2

	label values `var'_cat exacer_cat

	tab `var'_cat, missing
}


// SECTION 4 - PAAPs, RCP 3Qs, SABAs & ICSs

merge 1:1 pracid patid using "`data_dir'/temp/asthma_paap"
drop if _merge == 2
drop _merge

replace paap = 0 if paap == .

tab paap, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_rcp3"
drop if _merge == 2
drop _merge

replace rcp3 = 0 if rcp3 == .

tab rcp3, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_inhalercounts"
drop if _merge == 2
drop _merge

replace saba_count     = 0 if saba_count     == .
replace saba_morethan2 = 0 if saba_morethan2 == .
replace ics_count      = 0 if ics_count      == .
replace ics_lessthan6  = 0 if ics_lessthan6  == .

tab1 saba_count saba_morethan2 ics_count ics_lessthan6, missing


// SECTION 4 - INHALER TECHNIQUE, FLU VACCINE, SMOKING CESSATION

merge 1:1 pracid patid using "`data_dir'/temp/both_inhalercheck"
drop if _merge == 2
drop _merge

tab1 inhalercheck


merge 1:1 pracid patid using "`data_dir'/temp/both_fluvaccine"
drop if _merge == 2
drop _merge

replace fluvax = 0 if fluvax == .

tab1 fluvax, missing


// SECTION 4 - INHALED THERAPY

merge 1:1 pracid patid using "`data_dir'/temp/asthma_inhaledtherapy"
drop if _merge == 2
drop _merge

replace inhaledtherapy = 0 if inhaledtherapy == .

tab1 inhaledtherapy therapy_type


// FINALISE DATASET READY FOR ANALYSIS

gen wimd_quintile = ceil((wimd_rank/1909)*5)  //1 = most deprived
order wimd_quintile, after(wimd_rank)

local cm_asthma_child ""Eczema" "Atopy" "Nasal Polyps" "Reflux" "Hayfever""
local cm_asthma_child "`cm_asthma_child' "Family history of asthma" "Allergic rhinitis""
local cm_asthma_child "`cm_asthma_child' "Mental health issues (paeds)" "Learning disability""

foreach comorbidity of local cm_asthma_child {

	local cm = subinstr("`comorbidity'", "(", "", .)  //remove brackets
	local cm = subinstr("`cm'", ")", "", .)
	local cm = subinstr(lower("`cm'"), " ", "_", .)  //replace spaces with underscores
	
	replace `cm' = 1 if `cm' != .
	replace `cm' = 0 if `cm' == .
	
	format %8.0g `cm'
}


//not needed
drop obese_date gp_asthmaexac_count gp_asthmaexacs wimd_rank


// SECTION 5 - MENTAL HEALTH CROSS TABULATIONS
// mental health varible (exposure)
label define mh 0 "No mental health issues or learning disability" ///
				1 "Mild/moderate mental health issues" ///
				2 "Learning disability"

gen byte mentalhealth = 0
replace mentalhealth  = 1 if mental_health_issues_paeds == 1
replace mentalhealth  = 2 if learning_disability == 1

label values mentalhealth mh

tab mentalhealth, missing


// outcomes - SABA and OCS prescriptions
tab saba_morethan2, missing
gen saba_2orfewer = -(saba_morethan2)+1          //swap 0 and 1 as more than 2 is bad
tab saba_2orfewer, missing

tab ocscourses2orfewer, missing
gen ocscourses_morethan2 = -(ocscourses2orfewer)+1  //swap 0 and 1 as 2 or fewer is bad
tab ocscourses_morethan2, missing



compress
save "`data_dir'/builds/asthma_child_1-5_final", replace



log close
