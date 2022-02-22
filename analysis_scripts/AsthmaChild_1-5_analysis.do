clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using analysis_logs/AsthmaChild_1-5_analysis, smcl replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/asthma_child_1-5_final", clear


// SECTION 1

tab gender, missing

sum age, detail
preserve
bysort gender: sum age, detail
restore

tab wimd_quintile, missing   //1 = most deprived; 0 = no data

tab1 obese eczema atopy nasal_polyps reflux hayfever family_history_of_asthma ///
	 allergic_rhinitis mental_health_issues_paeds learning_disability, missing


// SECTION 2

//nothing for children under 6


// SECTION 3

tab ocscourses2orfewer, missing
tab ocs3plusref, missing

tab sh_smoke, missing

tab1 gp_exacerbations_cat asthmaexacs_cat, missing


// SECTION 4

tab paap, missing

tab rcp3, missing

tab saba_morethan2, missing

tab ics_lessthan6, missing

tab inhalercheck

tab fluvax, missing

tab inhaledtherapy, missing
tab therapy_type


// SECTION 5

//exposure
tab mentalhealth, missing

//saba and ocs recoded variables
tab saba_2orfewer, missing
tab ocscourses_morethan2, missing

//cross-tabulations
tab mentalhealth rcp3, row chi

tab mentalhealth saba_2orfewer, row chi

tab mentalhealth ocscourses_morethan2, row chi


log close
translate analysis_logs/AsthmaChild_1-5_analysis.smcl outputs/AsthmaChild_1-5_analysis.pdf
