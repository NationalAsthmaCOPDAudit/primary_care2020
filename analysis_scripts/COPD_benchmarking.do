clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using analysis_logs/COPD_benchmarking, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


import excel "`data_dir'/raw_data/Master registration list.xlsx", firstrow clear

foreach var of varlist _all {
	
	replace `var' = strtrim(stritrim(`var'))
	
	local lowercase = lower("`var'")
	rename `var' `lowercase'
}
compress

replace participating = "0" if participating == "No"
replace participating = "1" if participating == "Yes"
destring participating, replace

rename wcode pracid

save "`data_dir'/stata_data/lhb_cluster_codes", replace


merge 1:m pracid using "`data_dir'/builds/copd_final"
drop if _merge == 1
drop _merge participating

gsort pracid patid

save "`data_dir'/builds/copd_final_lhb_cluster",replace


keep pracid lhbshortdesc postbdobstruction mrc35_prref


foreach var in postbdobstruction mrc35_prref {

	tab `var'
	
	by pracid: egen prac_`var' = total(`var')
	by pracid: egen prac_`var'_denom = count(`var')
	by pracid: gen double prac_`var'_pc = round((prac_`var'/prac_`var'_denom)*100, 0.01)
}

by pracid: keep if _n == 1


foreach var in postbdobstruction mrc35_prref {

	sum prac_`var'_pc, detail

	gen prac_`var'_pc_p25 = r(p25)
	gen prac_`var'_pc_p50 = r(p50)
	gen prac_`var'_pc_p75 = r(p75)
}


//fix spirometry at 25/50/75 rather than using absurd actual results
replace prac_postbdobstruction_pc_p25 = 25
replace prac_postbdobstruction_pc_p50 = 50
replace prac_postbdobstruction_pc_p75 = 75


label define colour 1 "Red" 2 "Yellow" 3 "Green"

foreach var in postbdobstruction mrc35_prref {
	
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

keep lhbshortdesc lhb_postbdobstruction lhb_postbdobstruction_pc postbdobstruction_colour ///
	 lhb_mrc35_prref lhb_mrc35_prref_pc mrc35_prref_colour

label var lhb_postbdobstruction    "People diagnosed with COPD in the past 2 years who have a post-bronchodilator FEV1/FVC <0.7 (n)"
label var lhb_postbdobstruction_pc "People diagnosed with COPD in the past 2 years who have a post-bronchodilator FEV1/FVC <0.7 (%)"
label var postbdobstruction_colour "People diagnosed with COPD in the past 2 years who have a post-bronchodilator FEV1/FVC <0.7 (colour)"
label var lhb_mrc35_prref    "People with COPD who are breathless (MRC score 3-5) and have been referred to PR in the last 3 years (n)"
label var lhb_mrc35_prref_pc "People with COPD who are breathless (MRC score 3-5) and have been referred to PR in the last 3 years (%)"
label var mrc35_prref_colour "People with COPD who are breathless (MRC score 3-5) and have been referred to PR in the last 3 years (colour)"


export excel outputs/COPD_Benchmarking.xlsx, firstrow(var) replace


log close
