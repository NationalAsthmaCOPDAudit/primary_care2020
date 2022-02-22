//Run this to add in LHB and cluster info

clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/LHB_merge, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end


import excel "`data_dir'/raw_data/Welsh GP Practices registered (Clusters added) Updated 16.11.20.xlsx", firstrow case(lower)

keep wcode localhealthboard clustercode clustername practicename

rename wcode pracid

tempfile lhbs
save `lhbs'


local builds "copd asthma_adult asthma_child_1-5 asthma_child_6-18"

foreach build of local builds {
	
	use "`data_dir'/builds/`build'_final", clear

	merge m:1 pracid using `lhbs'
	drop if _merge == 2
	drop _merge

	order localhealthboard clustername clustercode practicename

	save "`data_dir'/builds/`build'_final_lhb", replace
}


log close