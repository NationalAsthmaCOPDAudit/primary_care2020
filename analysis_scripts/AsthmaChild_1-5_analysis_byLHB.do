clear
set more off
capture log close

cd "D:\GitHub\nacap\primary_care2020"


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/asthma_child_1-5_final_lhb", clear

gsort pracid patid


//only 2 practices in Powys therefore "Powys Teaching LHB" has been excluded
local lhbs ""Aneurin Bevan ULHB" "Betsi Cadwaladr ULHB" "Cardiff & Vale ULHB" "Cwm Taf Morgannwg ULHB" "Hywel Dda ULHB" "Swansea Bay ULHB""

foreach lhb of local lhbs {
	
	preserve
	
	keep if localhealthboard == "`lhb'"
	
	//== LHB ANALYSIS ==========================================================
	
	log using "analysis_logs/AsthmaChild_1-5_analysis_`lhb'", smcl replace
	
	tab localhealthboard, missing
	
	// SECTION 1

	tab gender, missing

	sum age, detail
	bysort gender: sum age, detail
	gsort pracid patid

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
	translate "analysis_logs/AsthmaChild_1-5_analysis_`lhb'.smcl" ///
			  "outputs/AsthmaChild_1-5_analysis_`lhb'.pdf"
	
	//== CLUSTER ANALYSIS ======================================================
	
	log using "analysis_logs/AsthmaChild_1-5_analysis_`lhb'_cluster", smcl replace
	
	tab1 localhealthboard clustername, missing

	// SECTION 1

	bysort clustername: tab gender, missing

	bysort clustername: sum age, detail
	bysort clustername gender: sum age, detail
	gsort pracid patid

	bysort clustername: tab wimd_quintile, missing   //1 = most deprived; 0 = no data

	bysort clustername: tab1 obese eczema atopy nasal_polyps reflux hayfever ///
							 family_history_of_asthma allergic_rhinitis ///
							 mental_health_issues_paeds learning_disability, missing


	// SECTION 2

	//nothing for children under 6


	// SECTION 3

	bysort clustername: tab ocscourses2orfewer, missing
	bysort clustername: tab ocs3plusref, missing

	bysort clustername: tab sh_smoke, missing

	bysort clustername: tab1 gp_exacerbations_cat asthmaexacs_cat, missing


	// SECTION 4

	bysort clustername: tab paap, missing

	bysort clustername: tab rcp3, missing

	bysort clustername: tab saba_morethan2, missing

	bysort clustername: tab ics_lessthan6, missing

	bysort clustername: tab inhalercheck

	bysort clustername: tab fluvax, missing

	bysort clustername: tab inhaledtherapy, missing
	bysort clustername: tab therapy_type


	// SECTION 5

	//exposure
	bysort clustername: tab mentalhealth, missing

	//saba and ocs recoded variables
	bysort clustername: tab saba_2orfewer, missing
	bysort clustername: tab ocscourses_morethan2, missing

	//cross-tabulations
	bysort clustername: tab mentalhealth rcp3, row chi

	bysort clustername: tab mentalhealth saba_2orfewer, row chi

	bysort clustername: tab mentalhealth ocscourses_morethan2, row chi
	
	log close
	translate "analysis_logs/AsthmaChild_1-5_analysis_`lhb'_cluster.smcl" ///
			  "outputs/AsthmaChild_1-5_analysis_`lhb'_cluster.pdf"
	
	//==========================================================================
	
	restore
}
