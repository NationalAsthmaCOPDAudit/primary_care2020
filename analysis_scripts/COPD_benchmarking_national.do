clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using analysis_logs/COPD_benchmarking_national, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/copd_final", clear

gsort pracid patid


foreach var in postbdobstruction mrc35_prref {

	tab `var'
	
	by pracid: egen prac_`var' = total(`var')
	by pracid: egen prac_`var'_denom = count(`var')
	by pracid: gen double prac_`var'_pc = round((prac_`var'/prac_`var'_denom)*100, 0.01)
}

keep pracid prac_postbdobstruction prac_postbdobstruction_denom prac_postbdobstruction_pc ///
	 prac_mrc35_prref prac_mrc35_prref_denom prac_mrc35_prref_pc

by pracid: keep if _n == 1


foreach var in postbdobstruction mrc35_prref {

	sum prac_`var'_pc, detail

	gen `var'_pc_p25 = r(p25)
	gen `var'_pc_p50 = r(p50)
	gen `var'_pc_p75 = r(p75)
}


keep if _n == 1

keep postbdobstruction_pc_p25 postbdobstruction_pc_p50 postbdobstruction_pc_p75 ///
	 mrc35_prref_pc_p25 mrc35_prref_pc_p50 mrc35_prref_pc_p75


export delimited outputs/COPD_Benchmarking_national, replace


log close
