clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/15_AddVarsCOPD, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end


use "`data_dir'/builds/copd_cohort_cm2_mh", clear


// PAINFUL CONDITION

merge 1:1 pracid patid using "`data_dir'/temp/copd_painful_condition"
drop if _merge == 2
drop _merge   //all from using should be matched
replace pain = 0 if pain == .
tab pain, missing


// SECTION 2 - SPIROMETRY

merge 1:1 pracid patid using "`data_dir'/temp/both_postbd_spirom"
drop if _merge == 2
drop _merge
replace anypostbd = 0 if anypostbd == .
replace anypostbd = . if firstcopd < `end'-(2*365.25)  //DIAGNOSED IN LAST 2 YEARS
replace postbdobstruction = 0 if postbdobstruction == .
replace postbdobstruction = . if firstcopd < `end'-(2*365.25)

tab1 anypostbd postbdobstruction


merge 1:1 pracid patid using "`data_dir'/temp/both_any_spirom_ratio"
drop if _merge == 2
drop _merge
replace anyobstruction = 0 if anyobstruction == .
replace anyobstruction = . if firstcopd < `end'-(2*365.25)

tab1 anyobstruction


// SECTION 2 - CHEST X-RAY OR CT SCAN

merge 1:1 pracid patid using "`data_dir'/temp/copd_xray"
drop if _merge == 2
drop _merge

gen byte before6months = ((xray_before > firstcopd-(0.5*365.25)) & xray_before != .)
replace before6months = . if firstcopd < `end'-(2*365.25)
gen byte after6months = (xray_after < firstcopd+(0.5*365.25))
replace after6months = . if firstcopd < `end'-(2*365.25)

gen byte xrayin6months = (before6months == 1 | after6months == 1)
replace xrayin6months = . if firstcopd < `end'-(2*365.25)

tab1 xrayin6months


// SECTION 3 - MRC GRADE, FEV1 % PREDICTED, OXYGEN ASSESSMENT

merge 1:1 pracid patid using "`data_dir'/temp/copd_mrc_ever"   //EVER
drop if _merge == 2
drop _merge
replace mrc_grade_ever = 0 if mrc_grade_ever == .

tab1 mrc_grade_ever, missing

merge 1:1 pracid patid using "`data_dir'/temp/copd_mrc"     //LAST YEAR
drop if _merge == 2
drop _merge
replace mrc_grade = 0 if mrc_grade == .

tab1 mrc_grade, missing


merge 1:1 pracid patid using "`data_dir'/temp/copd_fev1pp"
drop if _merge == 2
drop _merge
replace fev1pp = 0 if fev1pp == .

tab1 fev1pp, missing


merge 1:1 pracid patid using "`data_dir'/temp/copd_o2assessment"
drop if _merge == 2
drop _merge

tab1 o2assess_single o2assess_persist


// SECTION 3 - SMOKING STATUS

merge 1:1 pracid patid using "`data_dir'/temp/both_smokstat"
drop if _merge == 2
drop _merge

replace smokstat = 0 if smokstat == .

tab1 smokstat, missing


// SECTION 3 - EXACERBATIONS

merge 1:1 pracid patid using "`data_dir'/temp/copd_gprec_exacerbation"   //GP RECORDED ANNUAL COUNT
drop if _merge == 2
drop _merge

replace gp_copdexac_count = 0 if gp_copdexac_count == .

tab1 gp_copdexac_count, missing


merge 1:1 pracid patid using "`data_dir'/temp/copd_gp_exacerbation"   //COUNT OF GP RECORDED EXACERBATIONS
drop if _merge == 2
drop _merge

replace gp_copdexacs = 0 if gp_copdexacs == .

tab1 gp_copdexacs, missing


//remove unlikely values
replace gp_copdexac_count = 0 if gp_copdexac_count > 26
replace gp_copdexacs      = 0 if gp_copdexac_count > 26

gen gp_exacerbations     = gp_copdexac_count
replace gp_exacerbations = gp_copdexacs if gp_copdexacs > gp_copdexac_count

tab1 gp_exacerbations, missing


merge 1:1 pracid patid using "`data_dir'/temp/copd_validated_exacerbation"   //VALIDATED EXACERBATIONS
drop if _merge == 2
drop _merge

replace copdexacerbations = 0 if copdexacerbations == .

tab1 copdexacerbations, missing


//generate categories
label define exacer_cat 3 ">2"

foreach var in gp_exacerbations copdexacerbations {

	gen     `var'_cat = `var'
	replace `var'_cat = 3 if `var' > 2

	label values `var'_cat exacer_cat

	tab `var'_cat, missing
}


// SECTION 4 - PR REFERRAL

merge 1:1 pracid patid using "`data_dir'/temp/copd_pr_referral"
drop if _merge == 2
drop _merge

tab1 pr_ref mrc_grade_ever, missing

gen byte mrc35_prref = (mrc_grade_ever >= 3 & pr_ref == 1)
replace mrc35_prref  = . if mrc_grade_ever < 3

gen byte anymrc_prref = (mrc_grade_ever != 0 & pr_ref == 1)
replace anymrc_prref  = . if mrc_grade_ever == 0

tab1 mrc35_prref anymrc_prref


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

merge 1:1 pracid patid using "`data_dir'/temp/copd_inhaledtherapy"
drop if _merge == 2
drop _merge

replace inhaledtherapy = 0 if inhaledtherapy == .

tab1 inhaledtherapy therapy_type


// FINALISE DATASET READY FOR ANALYSIS

gen wimd_quintile = ceil((wimd_rank/1909)*5)  //1 = most deprived
order wimd_quintile, after(wimd_rank)

local cm_copd ""Bronchiectasis" "CHD" "Diabetes" "Heart Failure" "Hypertension""
local cm_copd "`cm_copd' "Lung cancer" "Stroke" "Osteoporosis" "Serious Mental Illness""
local cm_copd "`cm_copd' "Anxiety" "Depression" "Learning disability" "Epilepsy""

foreach comorbidity of local cm_copd {

	local cm = subinstr("`comorbidity'", "(", "", .)  //remove brackets
	local cm = subinstr("`cm'", ")", "", .)
	local cm = subinstr(lower("`cm'"), " ", "_", .)  //replace spaces with underscores
	
	replace `cm' = 1 if `cm' != .
	replace `cm' = 0 if `cm' == .
	
	format %8.0g `cm'
}

rename firstasthma asthma
replace asthma = 1 if asthma != .
replace asthma = 0 if asthma == .
format %8.0g asthma


//not needed
drop anxiety_screen anxiety_screen_declined depression_screen depression_screen_declined ///
	 epilepsy obese_date xray_before xray_after before6months after6months ///
	 gp_copdexac_count gp_copdexacs pr_ref smokcess_bci smokcess_drug wimd_rank


// mental health varible (SECTION 5)
label define mh 0 "No mental illness" 1 "Anxiety and/or depression" 2 "Severe mental illness"

gen byte mentalhealth = 0
replace mentalhealth  = 1 if depression == 1 | anxiety == 1
replace mentalhealth  = 2 if serious_mental_illness == 1

label values mentalhealth mh

tab mentalhealth, missing


compress
save "`data_dir'/builds/copd_final", replace



log close
