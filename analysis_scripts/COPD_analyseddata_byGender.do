clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using analysis_logs/COPD_analyseddata_byGender, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/copd_final", clear

drop firstcopd mrc_grade_ever gp_exacerbations copdexacerbations smokerlast2yrs mentalhealth

order asthma bronchiectasis chd diabetes heart_failure hypertension lung_cancer ///
	  pain stroke osteoporosis obese serious_mental_illness anxiety anxiety2yr ///
	  depression depression2yr learning_disability, after(wimd_quintile)

order gp_exacerbations_cat, after(copdexacerbations_cat)


gensumstat age, by(gender)
drop age


local binaryvars "asthma bronchiectasis chd diabetes heart_failure hypertension"
local binaryvars "`binaryvars' lung_cancer pain stroke osteoporosis obese"
local binaryvars "`binaryvars' serious_mental_illness anxiety anxiety2yr"
local binaryvars "`binaryvars' depression depression2yr learning_disability"
local binaryvars "`binaryvars' anypostbd postbdobstruction anyobstruction xrayin6months"
local binaryvars "`binaryvars' fev1pp o2assess_single o2assess_persist"
local binaryvars "`binaryvars' mrc35_prref anymrc_prref inhalercheck fluvax smokbcidrug"
local binaryvars "`binaryvars' inhaledtherapy"

foreach binaryvar of local binaryvars {
	
	drop `binaryvar'
}

drop wimd_quintile
drop mrc_grade
drop smokstat
drop copdexacerbations_cat
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


export delimited outputs/AnalysedPrimaryCareAudit_COPD_byGender, replace



log close
