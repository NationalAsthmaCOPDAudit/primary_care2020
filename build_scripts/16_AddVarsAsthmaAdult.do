clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/16_AddVarsAsthmaAdult, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end


use "`data_dir'/builds/asthma_adult_cohort_cm2_mh", clear


// PAINFUL CONDITION

merge 1:1 pracid patid using "`data_dir'/temp/asthma_adult_painful_condition"
drop if _merge == 2
drop _merge   //all from using should be matched
replace pain = 0 if pain == .
tab pain, missing


// SECTION 2 - SPIROMETRY

merge 1:1 pracid patid using "`data_dir'/temp/both_postbd_spirom"
drop if _merge == 2
drop _merge
replace anypostbd = 0 if anypostbd == .
replace anypostbd = . if firstasthma < `end'-(2*365.25)  //DIAGNOSED IN LAST 2 YEARS
replace postbdobstruction = 0 if postbdobstruction == .
replace postbdobstruction = . if firstasthma < `end'-(2*365.25)

tab1 anypostbd postbdobstruction


merge 1:1 pracid patid using "`data_dir'/temp/asthma_prebd_spirom"
drop if _merge == 2
drop _merge
replace anyprebd = 0 if anyprebd == .
replace anyprebd = . if firstasthma < `end'-(2*365.25)  //DIAGNOSED IN LAST 2 YEARS
replace prebdobstruction = 0 if prebdobstruction == .
replace prebdobstruction = . if firstasthma < `end'-(2*365.25)

tab1 anyprebd prebdobstruction


merge 1:1 pracid patid using "`data_dir'/temp/both_any_spirom_ratio"
drop if _merge == 2
drop _merge
replace anyobstruction = 0 if anyobstruction == .
replace anyobstruction = . if firstasthma < `end'-(2*365.25)

tab1 anyobstruction


//spirometry + revesibility

merge 1:1 pracid patid using "`data_dir'/temp/asthma_anyspirom"
drop if _merge == 2
drop _merge

replace anyspirom = 0 if anyspirom == .
replace anyspirom = . if firstasthma < `end'-(2*365.25)

tab anyspirom


merge 1:1 pracid patid using "`data_dir'/temp/asthma_ratio_reversibility"
drop if _merge == 2
drop _merge

replace ratio_reverse = 0 if ratio_reverse == .
replace ratio_reverse = . if firstasthma < `end'-(2*365.25)

tab ratio_reverse


merge 1:1 pracid patid using "`data_dir'/temp/asthma_spirometry_reversibility"
drop if _merge == 2
drop _merge

replace spirom_reverse = 0 if spirom_reverse == .
replace spirom_reverse = . if firstasthma < `end'-(2*365.25)

tab spirom_reverse


//peak flow ever

merge 1:1 pracid patid using "`data_dir'/temp/asthma_ever_anypeakflow"
drop if _merge == 2
drop _merge

replace anypeakflow_ever = 0 if anypeakflow_ever == .

tab anypeakflow_ever, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_ever_pre_post_peakflow"
drop if _merge == 2
drop _merge

replace prepostpeakflow_ever = 0 if prepostpeakflow_ever == .

tab prepostpeakflow_ever, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_ever_peakflow_diary"
drop if _merge == 2
drop _merge

replace peakflowdiary_ever = 0 if peakflowdiary_ever == .

tab peakflowdiary_ever, missing


//peak flow for those diagnosed in the last 2 years

merge 1:1 pracid patid using "`data_dir'/temp/asthma_2yr_anypeakflow"
drop if _merge == 2
drop _merge

replace anypeakflow = 0 if anypeakflow == .
replace anypeakflow = . if firstasthma < `end'-(2*365.25)

tab anypeakflow


merge 1:1 pracid patid using "`data_dir'/temp/asthma_2yr_pre_post_peakflow"
drop if _merge == 2
drop _merge

replace prepostpeakflow = 0 if prepostpeakflow == .
replace prepostpeakflow = . if firstasthma < `end'-(2*365.25)

tab prepostpeakflow


merge 1:1 pracid patid using "`data_dir'/temp/asthma_2yr_peakflow_diary"
drop if _merge == 2
drop _merge

replace peakflowdiary = 0 if peakflowdiary == .
replace peakflowdiary = . if firstasthma < `end'-(2*365.25)

tab peakflowdiary


// SECTION 2 - FeNO

merge 1:1 pracid patid using "`data_dir'/temp/asthma_feno"
drop if _merge == 2
drop _merge

replace feno = 0 if feno == .
replace feno = . if firstasthma < `end'-(2*365.25)

tab1 feno


//GENERATE OBJECTIVE MEASUREMENT VARIABLE

gen byte objectivemeasure = (anyspirom == 1 | anypeakflow == 1 | feno == 1)
replace objectivemeasure = . if firstasthma < `end'-(2*365.25)

tab objectivemeasure


// SECTION 3 - REFERRAL TO SPECIALIST CARE

merge 1:1 pracid patid using "`data_dir'/temp/asthma_ocs"
drop if _merge == 2
drop _merge

replace ocs_courses = 0 if ocs_courses == .

gen byte ocscourses2orfewer = (ocs_courses <= 2)

tab1 ocs_courses ocscourses2orfewer, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_specialist_referral"
drop if _merge == 2
drop _merge

replace referral = 0 if referral == .

gen byte ocs3plusref = (ocs_courses >= 3 & referral == 1)

tab1 referral ocs3plusref, missing


// SECTION 3 - SMOKING STATUS, SECOND-HAND SMOKE EXPOSURE

merge 1:1 pracid patid using "`data_dir'/temp/both_smokstat"
drop if _merge == 2
drop _merge

replace smokstat = 0 if smokstat == .

tab1 smokstat, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_secondhand_smoke"
drop if _merge == 2
drop _merge

replace sh_smoke = 0 if sh_smoke == .

tab1 sh_smoke, missing


// SECTION 3 - EXACERBATIONS

merge 1:1 pracid patid using "`data_dir'/temp/asthma_gprec_exacerbation"   //GP RECORDED ANNUAL COUNT
drop if _merge == 2
drop _merge

replace gp_asthmaexac_count = 0 if gp_asthmaexac_count == .

tab1 gp_asthmaexac_count, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_gp_exacerbation"   //COUNT OF GP RECORDED EXACERBATIONS
drop if _merge == 2
drop _merge

replace gp_asthmaexacs = 0 if gp_asthmaexacs == .

tab1 gp_asthmaexacs, missing


//remove unlikely values
replace gp_asthmaexac_count = 0 if gp_asthmaexac_count > 26
replace gp_asthmaexacs      = 0 if gp_asthmaexac_count > 26

gen gp_exacerbations     = gp_asthmaexac_count
replace gp_exacerbations = gp_asthmaexacs if gp_asthmaexacs > gp_asthmaexac_count

tab1 gp_exacerbations, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_validated_exacerbation"   //VALIDATED EXACERBATIONS
drop if _merge == 2
drop _merge

replace asthmaexacs = 0 if asthmaexacs == .

tab1 asthmaexacs, missing


//generate categories
label define exacer_cat 3 ">2"

foreach var in gp_exacerbations asthmaexacs {

	gen     `var'_cat = `var'
	replace `var'_cat = 3 if `var' > 2

	label values `var'_cat exacer_cat

	tab `var'_cat, missing
}


// SECTION 4 - PAAPs, RCP 3Qs, SABAs & ICSs

merge 1:1 pracid patid using "`data_dir'/temp/asthma_paap"
drop if _merge == 2
drop _merge

replace paap = 0 if paap == .

tab paap, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_rcp3"
drop if _merge == 2
drop _merge

replace rcp3 = 0 if rcp3 == .

tab rcp3, missing


merge 1:1 pracid patid using "`data_dir'/temp/asthma_inhalercounts"
drop if _merge == 2
drop _merge

replace saba_count     = 0 if saba_count     == .
replace saba_morethan2 = 0 if saba_morethan2 == .
replace ics_count      = 0 if ics_count      == .
replace ics_lessthan6  = 0 if ics_lessthan6  == .

tab1 saba_count saba_morethan2 ics_count ics_lessthan6, missing


// SECTION 4 - INHALER TECHNIQUE, FLU VACCINE, SMOKING CESSATION

merge 1:1 pracid patid using "`data_dir'/temp/both_inhalercheck"
drop if _merge == 2
drop _merge

tab1 inhalercheck


merge 1:1 pracid patid using "`data_dir'/temp/both_fluvaccine"
drop if _merge == 2
drop _merge

replace fluvax = 0 if fluvax == .

tab1 fluvax, missing


merge 1:1 pracid patid using "`data_dir'/temp/both_smokingcess_smokerslast2yrs"
drop if _merge == 2
drop _merge

replace smokerlast2yrs = 0 if smokerlast2yrs == .

tab1 smokerlast2yrs, missing


merge 1:1 pracid patid using "`data_dir'/temp/both_smokingcess_bci_drug"
drop if _merge == 2
drop _merge

replace smokcess_bci = 0 if smokcess_bci == .
replace smokcess_drug = 0 if smokcess_drug == .

tab1 smokcess_bci smokcess_drug, missing


//generate variable for smokers who've received BCI & drug
gen byte smokbcidrug = (smokcess_bci == 1 & smokcess_drug == 1)
replace smokbcidrug = . if smokerlast2yrs == 0

tab1 smokbcidrug


// SECTION 4 - INHALED THERAPY

merge 1:1 pracid patid using "`data_dir'/temp/asthma_inhaledtherapy"
drop if _merge == 2
drop _merge

replace inhaledtherapy = 0 if inhaledtherapy == .

tab1 inhaledtherapy therapy_type


// FINALISE DATASET READY FOR ANALYSIS

gen wimd_quintile = ceil((wimd_rank/1909)*5)  //1 = most deprived
order wimd_quintile, after(wimd_rank)

local cm_asthma ""Bronchiectasis" "CHD" "Diabetes" "Heart Failure" "Hypertension""
local cm_asthma "`cm_asthma' "Lung cancer" "Stroke""
local cm_asthma "`cm_asthma' "Osteoporosis" "Eczema" "Atopy" "Nasal Polyps""
local cm_asthma "`cm_asthma' "Reflux" "Hayfever" "Family history of asthma""
local cm_asthma "`cm_asthma' "Allergic rhinitis" "Serious Mental Illness" "Anxiety""
local cm_asthma "`cm_asthma' "Depression" "Learning disability" "Epilepsy""

foreach comorbidity of local cm_asthma {

	local cm = subinstr("`comorbidity'", "(", "", .)  //remove brackets
	local cm = subinstr("`cm'", ")", "", .)
	local cm = subinstr(lower("`cm'"), " ", "_", .)  //replace spaces with underscores
	
	replace `cm' = 1 if `cm' != .
	replace `cm' = 0 if `cm' == .
	
	format %8.0g `cm'
}

rename firstcopd copd
replace copd = 1 if copd != .
replace copd = 0 if copd == .
format %8.0g copd


//not needed
drop anxiety_screen anxiety_screen_declined depression_screen depression_screen_declined ///
	 epilepsy obese_date gp_asthmaexac_count gp_asthmaexacs smokcess_bci smokcess_drug wimd_rank


// SECTION 5 - MENTAL HEALTH CROSS TABULATIONS
// mental health varible (exposure)
label define mh 0 "No mental illness" 1 "Anxiety and/or depression" 2 "Severe mental illness"

gen byte mentalhealth = 0
replace mentalhealth  = 1 if depression == 1 | anxiety == 1
replace mentalhealth  = 2 if serious_mental_illness == 1

label values mentalhealth mh

tab mentalhealth, missing


// outcomes - SABA and OCS prescriptions
tab saba_morethan2, missing
gen saba_2orfewer = -(saba_morethan2)+1          //swap 0 and 1 as more than 2 is bad
tab saba_2orfewer, missing

tab ocscourses2orfewer, missing
gen ocscourses_morethan2 = -(ocscourses2orfewer)+1  //swap 0 and 1 as 2 or fewer is bad
tab ocscourses_morethan2, missing



compress
save "`data_dir'/builds/asthma_adult_final", replace



log close
