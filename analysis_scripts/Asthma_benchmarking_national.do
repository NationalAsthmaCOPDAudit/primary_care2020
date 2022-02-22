clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using analysis_logs/Asthma_benchmarking_national, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/asthma_adult_final"
append using "`data_dir'/builds/asthma_child_6-18_final"
append using "`data_dir'/builds/asthma_child_1-5_final"

gsort pracid patid

keep pracid objectivemeasure ics_lessthan6


foreach var in objectivemeasure ics_lessthan6 {

	tab `var'
	
	by pracid: egen prac_`var' = total(`var')
	by pracid: egen prac_`var'_denom = count(`var')
	by pracid: gen double prac_`var'_pc = round((prac_`var'/prac_`var'_denom)*100, 0.01)
}

by pracid: keep if _n == 1


foreach var in objectivemeasure ics_lessthan6 {

	sum prac_`var'_pc, detail

	gen `var'_pc_p25 = r(p25)
	gen `var'_pc_p50 = r(p50)
	gen `var'_pc_p75 = r(p75)
}


keep if _n == 1

keep objectivemeasure_pc_p25 objectivemeasure_pc_p50 objectivemeasure_pc_p75 ///
	 ics_lessthan6_pc_p25 ics_lessthan6_pc_p50 ics_lessthan6_pc_p75


export delimited outputs/Asthma_Benchmarking_national, replace


log close
