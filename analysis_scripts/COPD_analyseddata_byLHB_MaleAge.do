clear
set more off

cd "D:\GitHub\nacap\primary_care2020"


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/copd_final_lhb", clear
drop clustercode patid

drop firstcopd mrc_grade_ever gp_exacerbations copdexacerbations smokerlast2yrs mentalhealth

order asthma bronchiectasis chd diabetes heart_failure hypertension lung_cancer ///
	  pain stroke osteoporosis obese serious_mental_illness anxiety anxiety2yr ///
	  depression depression2yr learning_disability, after(wimd_quintile)

order gp_exacerbations_cat, after(copdexacerbations_cat)


local binaryvars "asthma bronchiectasis chd diabetes heart_failure hypertension"
local binaryvars "`binaryvars' lung_cancer pain stroke osteoporosis obese"
local binaryvars "`binaryvars' serious_mental_illness anxiety anxiety2yr"
local binaryvars "`binaryvars' depression depression2yr learning_disability"
local binaryvars "`binaryvars' anypostbd postbdobstruction anyobstruction xrayin6months"
local binaryvars "`binaryvars' fev1pp o2assess_single o2assess_persist"
local binaryvars "`binaryvars' mrc35_prref anymrc_prref inhalercheck fluvax smokbcidrug"
local binaryvars "`binaryvars' inhaledtherapy"


//encode practices and clusters with numeric categories (no gaps) and labels that match var names
rename pracid prac
encode prac, gen(pracid)
order pracid, after(prac)
drop prac practicename

rename clustername cluster
encode cluster, gen(clustername)
order clustername, after(cluster)
drop cluster

encode localhealthboard, gen(lhb)
order lhb, after(localhealthboard)


//restrict to just men
tab gender, missing
keep if gender == 1
tab gender, missing


//remove unused variables (only need age)
foreach binaryvar of local binaryvars {
		
	drop `binaryvar'
}

drop gender wimd_quintile mrc_grade smokstat copdexacerbations_cat gp_exacerbations_cat therapy_type


local levels "lhb clustername pracid"

foreach level of local levels {

	preserve

	if "`level'" == "pracid" {

		drop localhealthboard lhb clustername
	}
	else if "`level'" == "clustername" {

		//only 2 practices in Powys
		drop if localhealthboard == "Powys Teaching LHB"
		drop pracid lhb localhealthboard
	}
	else if "`level'" == "lhb" {

		//only 2 practices in Powys
		drop if localhealthboard == "Powys Teaching LHB"
		drop pracid clustername localhealthboard
	}

	gensumstat age, by(`level')
	drop age
	

	bysort `level': keep if _n == 1

	export delimited outputs/AnalysedPrimaryCareAudit_COPD_`level'_MaleAge, replace
	
	restore
}
