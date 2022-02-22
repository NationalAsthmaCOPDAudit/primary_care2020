clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using analysis_logs/COPD_analysis, smcl replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/copd_final", clear


// SECTION 1

tab gender, missing

sum age, detail
preserve
bysort gender: sum age, detail
restore

tab wimd_quintile, missing   //1 = most deprived; 0 = no data

tab1 asthma bronchiectasis chd diabetes heart_failure hypertension lung_cancer ///
	 pain stroke osteoporosis obese serious_mental_illness anxiety anxiety2yr ///
	 depression depression2yr learning_disability, missing


// SECTION 2

tab1 anypostbd postbdobstruction anyobstruction

tab xrayin6months


// SECTION 3

tab mrc_grade, missing

tab fev1pp, missing

tab1 o2assess_single o2assess_persist

tab smokstat, missing

tab1 gp_exacerbations_cat copdexacerbations_cat, missing


// SECTION 4

tab1 mrc35_prref anymrc_prref

tab inhalercheck

tab fluvax, missing

tab smokbcidrug

tab inhaledtherapy, missing
tab therapy_type


// SECTION 5

//exposure
tab mentalhealth, missing

//generate binary outcome vars for exacerbations
gen byte exacerbation_gp    = (gp_exacerbations  >= 1)
gen byte exacerbation_valid = (copdexacerbations >= 1)


tab mentalhealth postbdobstruction, row chi
tab mentalhealth anyobstruction, row chi

tab mentalhealth exacerbation_valid, row chi
tab mentalhealth exacerbation_gp, row chi

tab mentalhealth mrc35_prref, row chi
tab mentalhealth anymrc_prref, row chi


log close
translate analysis_logs/COPD_analysis.smcl outputs/COPD_analysis.pdf
