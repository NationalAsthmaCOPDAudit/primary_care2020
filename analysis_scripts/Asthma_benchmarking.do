clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using analysis_logs/Asthma_benchmarking, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/asthma_adult_final"
append using "`data_dir'/builds/asthma_child_6-18_final"
append using "`data_dir'/builds/asthma_child_1-5_final"

gsort pracid patid

tempfile asthma
save `asthma'


use "`data_dir'/stata_data/lhb_cluster_codes", clear

merge 1:m pracid using `asthma'
drop if _merge == 1
drop _merge participating

gsort pracid patid

save "`data_dir'/builds/asthma_all_final_lhb_cluster", replace

keep pracid lhbshortdesc objectivemeasure ics_lessthan6


foreach var in objectivemeasure ics_lessthan6 {

	tab `var'
	
	by pracid: egen prac_`var' = total(`var')
	by pracid: egen prac_`var'_denom = count(`var')
	by pracid: gen double prac_`var'_pc = round((prac_`var'/prac_`var'_denom)*100, 0.01)
}

by pracid: keep if _n == 1


foreach var in objectivemeasure ics_lessthan6 {

	sum prac_`var'_pc, detail

	gen prac_`var'_pc_p25 = r(p25)
	gen prac_`var'_pc_p50 = r(p50)
	gen prac_`var'_pc_p75 = r(p75)
}


label define colour 1 "Red" 2 "Yellow" 3 "Green"

foreach var in objectivemeasure ics_lessthan6 {
	
	bysort lhbshortdesc: egen lhb_`var' = total(prac_`var')
	bysort lhbshortdesc: egen lhb_`var'_denom = total(prac_`var'_denom)
	bysort lhbshortdesc: gen double lhb_`var'_pc = round((lhb_`var'/lhb_`var'_denom)*100, 0.01)
	
	gen byte `var'_colour = 1 if lhb_`var'_pc < prac_`var'_pc_p25
	
	replace  `var'_colour = 2 if lhb_`var'_pc >= prac_`var'_pc_p25 ///
							   & lhb_`var'_pc <= prac_`var'_pc_p75
	
	replace  `var'_colour = 3 if lhb_`var'_pc > prac_`var'_pc_p75
	
	label values `var'_colour colour
}


by lhbshortdesc: keep if _n == 1

keep lhbshortdesc lhb_objectivemeasure lhb_objectivemeasure_pc objectivemeasure_colour ///
	 lhb_ics_lessthan6 lhb_ics_lessthan6_pc ics_lessthan6_colour


export excel outputs/Asthma_Benchmarking.xlsx, firstrow(var) replace


log close
