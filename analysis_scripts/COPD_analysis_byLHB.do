clear
set more off
capture log close

cd "D:\GitHub\nacap\primary_care2020"


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/copd_final_lhb", clear

gsort pracid patid

//generate binary outcome vars for exacerbations (for SECTION 5)
gen byte exacerbation_gp    = (gp_exacerbations  >= 1)
gen byte exacerbation_valid = (copdexacerbations >= 1)


//only 2 practices in Powys therefore "Powys Teaching LHB" has been excluded
local lhbs ""Aneurin Bevan ULHB" "Betsi Cadwaladr ULHB" "Cardiff & Vale ULHB" "Cwm Taf Morgannwg ULHB" "Hywel Dda ULHB" "Swansea Bay ULHB""

foreach lhb of local lhbs {

	preserve
	
	display "LHB: `lhb'"
	
	keep if localhealthboard == "`lhb'"
	
	//== LHB ANALYSIS ===========================================================
	
	log using "analysis_logs/COPD_analysis_`lhb'", smcl replace
	
	tab localhealthboard, missing
	
	// SECTION 1

	tab gender, missing

	sum age, detail
	bysort gender: sum age, detail
	gsort pracid patid

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

	tab mentalhealth postbdobstruction, row chi
	tab mentalhealth anyobstruction, row chi

	tab mentalhealth exacerbation_valid, row chi
	tab mentalhealth exacerbation_gp, row chi

	tab mentalhealth mrc35_prref, row chi
	tab mentalhealth anymrc_prref, row chi
	
	log close
	translate "analysis_logs/COPD_analysis_`lhb'.smcl" "outputs/COPD_analysis_`lhb'.pdf"
	
	//== CLUSTER ANALYSIS ======================================================
	
	log using "analysis_logs/COPD_analysis_`lhb'_cluster", smcl replace
	
	tab1 localhealthboard clustername, missing
	
	// SECTION 1

	bysort clustername: tab gender, missing

	bysort clustername: sum age, detail
	bysort clustername gender: sum age, detail
	gsort pracid patid

	bysort clustername: tab wimd_quintile, missing   //1 = most deprived; 0 = no data

	bysort clustername: tab1 asthma bronchiectasis chd diabetes heart_failure hypertension ///
						 lung_cancer pain stroke osteoporosis obese serious_mental_illness ///
						 anxiety anxiety2yr depression depression2yr learning_disability, missing


	// SECTION 2

	bysort clustername: tab1 anypostbd postbdobstruction anyobstruction

	bysort clustername: tab xrayin6months


	// SECTION 3

	bysort clustername: tab mrc_grade, missing

	bysort clustername: tab fev1pp, missing

	bysort clustername: tab1 o2assess_single o2assess_persist

	bysort clustername: tab smokstat, missing

	bysort clustername: tab1 gp_exacerbations_cat copdexacerbations_cat, missing


	// SECTION 4

	bysort clustername: tab1 mrc35_prref anymrc_prref

	bysort clustername: tab inhalercheck

	bysort clustername: tab fluvax, missing

	bysort clustername: tab smokbcidrug

	bysort clustername: tab inhaledtherapy, missing
	bysort clustername: tab therapy_type


	// SECTION 5

	//exposure
	bysort clustername: tab mentalhealth, missing

	//cross-tabulations
	bysort clustername: tab mentalhealth postbdobstruction, row chi
	bysort clustername: tab mentalhealth anyobstruction, row chi

	bysort clustername: tab mentalhealth exacerbation_valid, row chi
	bysort clustername: tab mentalhealth exacerbation_gp, row chi

	bysort clustername: tab mentalhealth mrc35_prref, row chi
	bysort clustername: tab mentalhealth anymrc_prref, row chi
	
	log close
	translate "analysis_logs/COPD_analysis_`lhb'_cluster.smcl" "outputs/COPD_analysis_`lhb'_cluster.pdf"
	
	//==========================================================================
	
	restore
}
