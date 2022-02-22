clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/05_MentalHealthScreening, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end


foreach mentalhealth in Anxiety Depression {

	display "Mental health screening: `mentalhealth'"
	
	local mh = lower("`mentalhealth'")
	display "Cleaned string: `mh'"
	
	tempfile `mh'screen_cl `mh'screen_tmp
	
	use "`code_dir'/comorbidities/`mentalhealth'", clear
	duplicates list readcode5B
	duplicates drop readcode5B, force
	compress
	save ``mh'screen_cl'

	use "`data_dir'/stata_data/PC_events", clear
	drop if eventdate > `end'

	merge m:1 readcode5B using ``mh'screen_cl'
	tab category _merge
	keep if _m == 3
	drop _merge

	tab category
	keep if category == "`mentalhealth' screening" | ///
			category == "`mentalhealth' screening declined"
	tab category
	
	gsort pracid patid -eventdate
	gsort pracid patid -eventdate category

	//find most recent event before end of study period
	drop if eventdate > `end'
	by pracid patid: keep if _n == 1
	
	//binary variable to indicate that patient declined on date shown
	gen `mh'_screen_declined = (category == "`mentalhealth' screening declined")
	tab `mh'_screen_declined
	
	rename eventdate `mh'_screen

	keep pracid patid `mh'_screen `mh'_screen_declined
	
	compress
	save ``mh'screen_tmp'
}


foreach cohort in copd_cohort_cm2 asthma_adult_cohort_cm2 {

	use "`data_dir'/builds/`cohort'", clear

	foreach mentalhealth in Anxiety Depression {
		
		local mh = lower("`mentalhealth'")
		
		display "Merging `mentalhealth' Screening..."
		merge 1:1 pracid patid using ``mh'screen_tmp', keep(master match) nogen
		
		//check screening or diagnosis is in past 2 years
		gen byte `mh'2yr = 0
		
		replace `mh'2yr = 1 if `mh'        != . & ///
							   `mh'         > `end' - (2*365.25)
							   
		replace `mh'2yr = 1 if `mh'_screen != . & ///
							   `mh'_screen  > `end' - (2*365.25)
		
		order `mh'_screen `mh'_screen_declined `mh'2yr, after(`mh')
	}

	save "`data_dir'/builds/`cohort'_mh", replace
}


log close
