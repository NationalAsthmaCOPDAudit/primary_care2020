clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using analysis_logs/AsthmaChild_1-5_analyseddata_byGender, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/asthma_child_1-5_final", clear

drop firstasthma ocs_courses referral gp_exacerbations asthmaexacs saba_count ics_count ///
	 mentalhealth saba_2orfewer ocscourses_morethan2

order obese eczema atopy nasal_polyps reflux hayfever family_history_of_asthma ///
	  allergic_rhinitis mental_health_issues_paeds learning_disability, after(wimd_quintile)

order gp_exacerbations_cat, after(asthmaexacs_cat)


gensumstat age, by(gender)
drop age


local binaryvars "obese eczema atopy nasal_polyps reflux hayfever"
local binaryvars "`binaryvars' family_history_of_asthma allergic_rhinitis"
local binaryvars "`binaryvars' mental_health_issues_paeds learning_disability"
local binaryvars "`binaryvars' ocscourses2orfewer ocs3plusref"
local binaryvars "`binaryvars' paap rcp3 saba_morethan2 ics_lessthan6 inhalercheck"
local binaryvars "`binaryvars' fluvax inhaledtherapy"

foreach binaryvar of local binaryvars {
	
	drop `binaryvar'
}


drop wimd_quintile
drop sh_smoke
drop asthmaexacs_cat
drop gp_exacerbations_cat
drop therapy_type


drop pracid patid

gsort gender
by gender: keep if _n == 1
drop gender
xpose, clear varname
rename _varname Variable
rename v1 National_Male
rename v2 National_Female
order Variable


export delimited outputs/AnalysedPrimaryCareAudit_AsthmaChild_1-5_byGender, replace



log close
