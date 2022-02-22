clear
set more off

cd "D:\GitHub\nacap\primary_care2020"


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/asthma_child_1-5_final_lhb", clear

gsort pracid patid

drop clustercode patid

drop firstasthma ocs_courses referral gp_exacerbations asthmaexacs saba_count ics_count ///
	 mentalhealth saba_2orfewer ocscourses_morethan2

order obese eczema atopy nasal_polyps reflux hayfever family_history_of_asthma ///
	  allergic_rhinitis mental_health_issues_paeds learning_disability, after(wimd_quintile)

order gp_exacerbations_cat, after(asthmaexacs_cat)


local binaryvars "obese eczema atopy nasal_polyps reflux hayfever"
local binaryvars "`binaryvars' family_history_of_asthma allergic_rhinitis"
local binaryvars "`binaryvars' mental_health_issues_paeds learning_disability"
local binaryvars "`binaryvars' ocscourses2orfewer ocs3plusref"
local binaryvars "`binaryvars' paap rcp3 saba_morethan2 ics_lessthan6 inhalercheck"
local binaryvars "`binaryvars' fluvax inhaledtherapy"


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


local levels "clustername lhb pracid"

foreach level of local levels {

	preserve
	
	if "`level'" == "pracid" {

		drop lhb clustername localhealthboard
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

	foreach binaryvar of local binaryvars {
		
		gennumdenom `binaryvar', pc by(`level')
		drop `binaryvar'
	}


	gennumdenom gender, num(3) pc by(`level')
	drop gender

	gennumdenom wimd_quintile, num(5) zero pc by(`level')
	drop wimd_quintile

	gennumdenom sh_smoke, num(2) zero pc by(`level')
	drop sh_smoke

	gennumdenom asthmaexacs_cat, num(3) zero pc by(`level')
	drop asthmaexacs_cat

	gennumdenom gp_exacerbations_cat, num(3) zero pc by(`level')
	drop gp_exacerbations_cat

	gennumdenom therapy_type, num(6) pc by(`level')
	drop therapy_type
	
	
	by `level': keep if _n == 1

	export delimited "outputs/AnalysedPrimaryCareAudit_AsthmaChild_1-5_`level'", replace

	restore
}