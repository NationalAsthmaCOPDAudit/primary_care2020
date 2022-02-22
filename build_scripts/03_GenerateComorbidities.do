clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/03_GenerateComorbidities, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end

local comorbidities ""Allergic rhinitis" "Anxiety" "Atopy" "Bronchiectasis""
local comorbidities "`comorbidities' "CHD" "Depression" "Diabetes" "Eczema" "Epilepsy""
local comorbidities "`comorbidities' "Family history of asthma" "Hayfever" "Heart Failure""
local comorbidities "`comorbidities' "Hypertension" "Learning disability" "Lung cancer""
local comorbidities "`comorbidities' "Mental health issues (paeds)" "Nasal Polyps""
local comorbidities "`comorbidities' "Osteoporosis""
local comorbidities "`comorbidities' "Reflux" "Serious Mental Illness" "Stroke""


foreach comorbidity of local comorbidities {

	display "Comorbidity: `comorbidity'"
	
	local cm = subinstr("`comorbidity'", "(", "", .)  //remove brackets
	local cm = subinstr("`cm'", ")", "", .)
	local cm = subinstr(lower("`cm'"), " ", "_", .)  //replace spaces with underscores
	display "Cleaned string: `cm'"
	
	tempfile `cm'_cl `cm'_tmp
	
	use "`code_dir'/comorbidities/`comorbidity'", clear
	duplicates list readcode5B
	duplicates drop readcode5B, force
	compress
	save ``cm'_cl'
	
	if "`comorbidity'" == "Family history of asthma" {
		
		local comorbidity = "FH asthma"
		display "Renamed 'Family history of asthma' to 'FH asthma' for category var"
	}
	else if "`comorbidity'" == "Serious Mental Illness" {
	
		local comorbidity = "Psychosis"
		display "Renamed 'Serious Mental Illness' to 'Psychosis' for category var"
	}

	use "`data_dir'/stata_data/PC_events", clear

	merge m:1 readcode5B using ``cm'_cl'
	capture noisily tab category _merge
	keep if _m == 3
	drop _merge

	capture noisily tab category
	capture noisily keep if category == "`comorbidity'" | category == "`comorbidity' resolved"
	capture noisily tab category
	
	gsort pracid patid -eventdate
	capture noisily gsort pracid patid -eventdate category

	//find most recent diagnosis (diagnosed or resolved) before end of study period
	drop if eventdate > `end'
	by pracid patid: keep if _n == 1
	
	//can remove patients with most recent code as resolved
	capture noisily drop if category == "`comorbidity' resolved"
	
	rename eventdate `cm'

	keep pracid patid `cm'
	
	compress
	save ``cm'_tmp'
}


local cm_copd ""Bronchiectasis" "CHD" "Diabetes" "Heart Failure" "Hypertension""
local cm_copd "`cm_copd' "Lung cancer" "Stroke" "Osteoporosis" "Serious Mental Illness""
local cm_copd "`cm_copd' "Anxiety" "Depression" "Learning disability" "Epilepsy""

use "`data_dir'/builds/copd_cohort", clear

merge 1:1 pracid patid using "`data_dir'/builds/asthma_adult_cohort", keep(master match) nogen

//exclude asthma in 2 yrs prior to COPD diagnosis
replace firstasthma = . if firstasthma > firstcopd-(2*365.25)

foreach comorbidity of local cm_copd {
	
	local cm = subinstr("`comorbidity'", "(", "", .)  //remove brackets
	local cm = subinstr("`cm'", ")", "", .)
	local cm = subinstr(lower("`cm'"), " ", "_", .)  //replace spaces with underscores
	
	display "Merging `comorbidity'..."
	merge 1:1 pracid patid using ``cm'_tmp', keep(master match) nogen
}

save "`data_dir'/builds/copd_cohort_cm", replace


local cm_asthma ""Bronchiectasis" "CHD" "Diabetes" "Heart Failure" "Hypertension""
local cm_asthma "`cm_asthma' "Lung cancer" "Stroke""
local cm_asthma "`cm_asthma' "Osteoporosis" "Eczema" "Atopy" "Nasal Polyps""
local cm_asthma "`cm_asthma' "Reflux" "Hayfever" "Family history of asthma""
local cm_asthma "`cm_asthma' "Allergic rhinitis" "Serious Mental Illness" "Anxiety""
local cm_asthma "`cm_asthma' "Depression" "Learning disability" "Epilepsy""

use "`data_dir'/builds/asthma_adult_cohort", clear

merge 1:1 pracid patid using "`data_dir'/builds/copd_cohort", keep(master match) nogen
	
foreach comorbidity of local cm_asthma {
	
	local cm = subinstr("`comorbidity'", "(", "", .)  //remove brackets
	local cm = subinstr("`cm'", ")", "", .)
	local cm = subinstr(lower("`cm'"), " ", "_", .)  //replace spaces with underscores
	
	display "Merging `comorbidity'..."
	merge 1:1 pracid patid using ``cm'_tmp', keep(master match) nogen
}

save "`data_dir'/builds/asthma_adult_cohort_cm", replace


local cm_asthma_child ""Eczema" "Atopy" "Nasal Polyps" "Reflux" "Hayfever""
local cm_asthma_child "`cm_asthma_child' "Family history of asthma" "Allergic rhinitis""
local cm_asthma_child "`cm_asthma_child' "Mental health issues (paeds)" "Learning disability""

use "`data_dir'/builds/asthma_child_6-18_cohort", clear
	
foreach comorbidity of local cm_asthma_child {
	
	local cm = subinstr("`comorbidity'", "(", "", .)  //remove brackets
	local cm = subinstr("`cm'", ")", "", .)
	local cm = subinstr(lower("`cm'"), " ", "_", .)  //replace spaces with underscores
	
	display "Merging `comorbidity'..."
	merge 1:1 pracid patid using ``cm'_tmp', keep(master match) nogen
}

save "`data_dir'/builds/asthma_child_6-18_cohort_cm", replace


use "`data_dir'/builds/asthma_child_1-5_cohort", clear
	
foreach comorbidity of local cm_asthma_child {
	
	local cm = subinstr("`comorbidity'", "(", "", .)  //remove brackets
	local cm = subinstr("`cm'", ")", "", .)
	local cm = subinstr(lower("`cm'"), " ", "_", .)  //replace spaces with underscores
	
	display "Merging `comorbidity'..."
	merge 1:1 pracid patid using ``cm'_tmp', keep(master match) nogen
}

save "`data_dir'/builds/asthma_child_1-5_cohort_cm", replace


log close
