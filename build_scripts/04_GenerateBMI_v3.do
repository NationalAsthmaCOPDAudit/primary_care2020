clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using build_logs/04_GenerateBMI_v3, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"
local code_dir "C:\Users\pstone\Desktop\NACAP 2018 Codelists\Final code lists"

local start = date("2018-10-01", "YMD")       //study start
local end = date("2020-03-31", "YMD")         //study end


use "`data_dir'/stata_data/PC_events", clear
drop if eventdate > `end'

merge m:1 readcode5B using "`code_dir'/comorbidities/BMI"
tab category _merge
keep if _m == 3
drop _merge


replace category = "Height" if readcode5B == "229.." | readcode5B == "229Z."
replace category = "Weight" if readcode5B == "22A.." | readcode5B == "22AZ."

tab category
list readcode_value if category == "Height & weight" //looks fairly useless
drop if category == "Height & weight"

//convert all heights to metres
replace readcode_value = readcode_value/100 if category == "Height" & readcode_value > 3

//Arbitrary range of 0.5 to 2.2m considered plausible for height
drop if category == "Height" & readcode_value < 0.5
drop if category == "Height" & readcode_value > 2.2

//Arbitrary range of 2 to 300 Kg considered plausible for weight
drop if category == "Weight" & readcode_value < 2
drop if category == "Weight" & readcode_value > 300

//Arbitrary range of 10 to 80 considered plausible for BMI
drop if readcode5B == "22K.." & readcode_value < 10
drop if readcode5B == "22KB." & readcode_value < 10
drop if readcode5B == "22K.." & readcode_value > 80
drop if readcode5B == "22KB." & readcode_value > 80


/**** CHECK THAT ALL READ CODES ARE ACCOUNTED FOR HERE ****/
display in red "Check that this list in the comments matches the result of tabulation"
/**** IF NOT OTHER READ CODES NEED TO BE ADDED TO LIST BELOW ****/
/*
 readcode5B |      Freq.     Percent
------------+-----------------------
      22K.. |  1,644,001       96.51     Body Mass Index
      22K1. |      6,727        0.39     Body Mass Index normal K/M2
      22K2. |      7,979        0.47     Body Mass Index high K/M2
      22K3. |      1,398        0.08     Body Mass Index low K/M2
      22K4. |      8,913        0.52     Body mass index index 25-29 - overweight
      22K5. |     23,345        1.37     Body mass index 30+ - obesity
      22K6. |      1,060        0.06     Body mass index less than 20
      22K7. |      4,978        0.29     Body mass index 40+ - severely obese
      22K8. |      4,989        0.29     Body mass index 20-24 - normal
      22K9. |          6        0.00     Body mass index centile
      22K90 |          3        0.00     Baseline body mass index centile
      22K91 |          3        0.00     Child body mass index centile
      22K99 |          1        0.00     Child body mass index 26th-49th centile
      22K9G |          1        0.00     Child body mass index on 98th centile
      22K9H |          1        0.00     Child body mass index 98.1st-99.6th centile
      22K9J |          3        0.00     Child body mass index greater than 99.6th centile
      22KB. |          2        0.00     Baseline body mass index
      22KC. |         26        0.00     Obese class I (body mass index 30.0 - 34.9)
      22KD. |         27        0.00     Obese class II (body mass index 35.0 - 39.9)
      22KE. |         24        0.00     Obese class III (BMI equal to or greater than 40.0)
------------+-----------------------
      Total |  1,703,487      100.00
*/
tab readcode5B if category == "BMI"

drop if readcode5B == "22K9." & readcode_value == .  //BMI centile value codes
drop if readcode5B == "22K90" & readcode_value == .
drop if readcode5B == "22K91" & readcode_value == .

tempfile obese_tmp bmi_centile_tmp bmi_tmp height_tmp weight_tmp

preserve

keep if category == "BMI"
drop if readcode5B == "22K.." | readcode5B == "22KB."   //BMI value codes
drop if readcode5B == "22K9." | readcode5B == "22K90" | readcode5B == "22K91"  //BMI centile value codes
gen byte obese_code = (readcode5B == "22K5." | readcode5B == "22K7." | ///
						readcode5B == "22K9G" | readcode5B == "22K9H" | ///
						readcode5B == "22K9J" | readcode5B == "22KC." | ///
						readcode5B == "22KD." | readcode5B == "22KE.")
gsort pracid patid -eventdate
by pracid patid: keep if _n == 1
rename eventdate obese_code_date
keep pracid patid obese_code obese_code_date
tab obese_code
compress
save `obese_tmp'

restore, preserve

keep if readcode5B == "22K9." | readcode5B == "22K90" | readcode5B == "22K91"  //BMI centile value codes
gsort pracid patid -eventdate
by pracid patid: keep if _n == 1
rename readcode_value bmi_centile
rename eventdate bmi_centile_date
keep pracid patid bmi_centile bmi_centile_date
sum bmi_centile, detail
save `bmi_centile_tmp'

restore, preserve

keep if readcode5B == "22K.." | readcode5B == "22KB."   //BMI value codes
gsort pracid patid -eventdate
by pracid patid: keep if _n == 1
rename readcode_value bmi
rename eventdate bmi_date
keep pracid patid bmi bmi_date
sum bmi, detail
save `bmi_tmp'

restore, preserve

keep if category == "Height"
gsort pracid patid -eventdate
by pracid patid: keep if _n == 1
rename readcode_value height
rename eventdate height_date
keep pracid patid height height_date
sum height, detail
save `height_tmp'

restore

keep if category == "Weight"
gsort pracid patid -eventdate
by pracid patid: keep if _n == 1
rename readcode_value weight
rename eventdate weight_date
keep pracid patid weight weight_date
sum weight, detail
save `weight_tmp'


label define obeselbl 0 "Not obese" 1 "Obese" 2 "Unknown BMI"


local cohorts "copd asthma_adult"

foreach cohort of local cohorts {

	use "`data_dir'/builds/`cohort'_cohort_cm", clear

	merge 1:1 pracid patid using `obese_tmp', nogen keep(master match)
	merge 1:1 pracid patid using `bmi_tmp', nogen keep(master match)
	merge 1:1 pracid patid using `height_tmp', nogen keep(master match)
	merge 1:1 pracid patid using `weight_tmp', nogen keep(master match)
	
	//check height/weight/bmi is from adulthood
	gen ageatheight = age - (yofd(`end') - yofd(height_date))
	quietly count if ageatheight < 15
	display "No. of cohort with a height measured when younger than 15 yrs: " = r(N)
	
	gen ageatweight = age - (yofd(`end') - yofd(weight_date))
	quietly count if ageatweight < 15
	display "No. of cohort with a weight measured when younger than 15 yrs: " = r(N)
	
	gen ageatbmi = age - (yofd(`end') - yofd(bmi_date))
	quietly count if ageatbmi < 15
	display "No. of cohort with a BMI measured when younger than 15 yrs: " = r(N)
	
	sum ageatheight ageatweight ageatbmi, detail
	tab ageatheight if ageatheight < 15
	tab ageatweight if ageatweight < 15
	tab ageatbmi if ageatbmi < 15
	
	replace height = . if ageatheight < 15
	replace weight = . if ageatweight < 15
	replace bmi    = . if ageatbmi    < 15
	
	gen double bmi_calc = round(weight/(height^2), 0.1)
	
	gen double bmi_difference = sqrt((bmi-bmi_calc)^2)
	sum bmi_difference, detail

	//GP BMIs look generally the most plausible
	replace bmi_calc    = bmi      if bmi_difference > 10 & bmi != .
	replace weight_date = bmi_date if bmi_difference > 10 & bmi != .
	
	egen most_recent = rowmax(obese_code_date bmi_date weight_date)
	format %td most_recent

	gen most_recent_bmi = bmi_calc if weight_date == most_recent
	replace most_recent_bmi = bmi if bmi_date == most_recent
	
	gen most_recent_obese_code = obese_code if obese_code_date == most_recent
	
	//remove BMIs that are from more than 5 years ago
	replace most_recent_bmi = . if most_recent < (`end' - (5*365.25))
	replace most_recent_obese_code = . if most_recent < (`end' - (5*365.25))
	
	gen obese = most_recent_obese_code
	replace obese = 1 if most_recent_bmi >= 30 & most_recent_bmi != .
	replace obese = 0 if most_recent_bmi < 30
	
	tab obese, missing
	
	//label people with unknown BMI
	label obese obeselbl
	replace obese = 2 if obese == .
	tab obese, missing
	
	rename most_recent obese_date
	
	drop ageatheight ageatweight ageatbmi obese_code_date obese_code bmi bmi_date ///
		height height_date weight weight_date bmi_calc bmi_difference ///
		most_recent_bmi most_recent_obese_code

	save "`data_dir'/builds/`cohort'_cohort_cm2", replace
}


local cohorts "asthma_child_6-18 asthma_child_1-5"

foreach cohort of local cohorts {
	
	use "`data_dir'/builds/`cohort'_cohort_cm", clear

	merge 1:1 pracid patid using `obese_tmp', nogen keep(master match)
	merge 1:1 pracid patid using `bmi_centile_tmp', nogen keep(master match)
	merge 1:1 pracid patid using `bmi_tmp', nogen keep(master match)
	merge 1:1 pracid patid using `height_tmp', nogen keep(master match)
	merge 1:1 pracid patid using `weight_tmp', nogen keep(master match)
	
	//check height/weight are within 6 months of each other
	gen toofar = (sqrt((height_date - weight_date)^2) > (365.25/2))
	
	replace height      = . if toofar == 1
	replace height_date = . if toofar == 1
	replace weight      = . if toofar == 1
	replace weight_date = . if toofar == 1
	
	gen double bmi_calc = round(weight/(height^2), 0.1)
	
	gen double bmi_difference = sqrt((bmi-bmi_calc)^2)
	sum bmi_difference, detail

	//remove unlikely BMIs
	replace bmi_calc = . if bmi_calc > 100
	
	egen most_recent = rowmax(obese_code_date bmi_centile_date bmi_date weight_date)
	format %td most_recent

	gen most_recent_bmi = bmi if bmi_date == most_recent
	replace most_recent_bmi = bmi_calc if weight_date == most_recent
	
	//remove BMIs that are more than a year old
	replace most_recent_bmi = . if most_recent < (`end' - 365.25)
	
	gen most_recent_obese_code = obese_code if obese_code_date == most_recent
	
	gen most_recent_centile = bmi_centile if bmi_centile_date == most_recent
	
	gen obese = most_recent_obese_code
	replace obese = 1 if most_recent_centile >= 98 & bmi_centile != .
	replace obese = 0 if most_recent_centile < 98
	
	
	//Boys 2-18
	replace obese = 1 if age == 2 & gender == 1 & most_recent_bmi >= 18.5 & most_recent_bmi != .
	replace obese = 0 if age == 2 & gender == 1 & most_recent_bmi < 18.5
	
	replace obese = 1 if age == 3 & gender == 1 & most_recent_bmi >= 18 & most_recent_bmi != .
	replace obese = 0 if age == 3 & gender == 1 & most_recent_bmi < 18
	
	replace obese = 1 if age == 4 & gender == 1 & most_recent_bmi >= 18.5 & most_recent_bmi != .
	replace obese = 0 if age == 4 & gender == 1 & most_recent_bmi < 18.5
	
	replace obese = 1 if age == 5 & gender == 1 & most_recent_bmi >= 18.5 & most_recent_bmi != .
	replace obese = 0 if age == 5 & gender == 1 & most_recent_bmi < 18.5
	
	
	replace obese = 1 if age == 6 & gender == 1 & most_recent_bmi >= 19 & most_recent_bmi != .
	replace obese = 0 if age == 6 & gender == 1 & most_recent_bmi < 19
	
	replace obese = 1 if age == 7 & gender == 1 & most_recent_bmi >= 19.5 & most_recent_bmi != .
	replace obese = 0 if age == 7 & gender == 1 & most_recent_bmi < 19.5
	
	replace obese = 1 if age == 8 & gender == 1 & most_recent_bmi >= 20.5 & most_recent_bmi != .
	replace obese = 0 if age == 8 & gender == 1 & most_recent_bmi < 20.5
	
	replace obese = 1 if age == 9 & gender == 1 & most_recent_bmi >= 21.5 & most_recent_bmi != .
	replace obese = 0 if age == 9 & gender == 1 & most_recent_bmi < 21.5
	
	replace obese = 1 if age == 10 & gender == 1 & most_recent_bmi >= 22 & most_recent_bmi != .
	replace obese = 0 if age == 10 & gender == 1 & most_recent_bmi < 22
	
	replace obese = 1 if age == 11 & gender == 1 & most_recent_bmi >= 23 & most_recent_bmi != .
	replace obese = 0 if age == 11 & gender == 1 & most_recent_bmi < 23
	
	replace obese = 1 if age == 12 & gender == 1 & most_recent_bmi >= 24 & most_recent_bmi != .
	replace obese = 0 if age == 12 & gender == 1 & most_recent_bmi < 24
	
	replace obese = 1 if age == 13 & gender == 1 & most_recent_bmi >= 24.5 & most_recent_bmi != .
	replace obese = 0 if age == 13 & gender == 1 & most_recent_bmi < 24.5
	
	replace obese = 1 if age == 14 & gender == 1 & most_recent_bmi >= 25.5 & most_recent_bmi != .
	replace obese = 0 if age == 14 & gender == 1 & most_recent_bmi < 25.5
	
	replace obese = 1 if age == 15 & gender == 1 & most_recent_bmi >= 26.5 & most_recent_bmi != .
	replace obese = 0 if age == 15 & gender == 1 & most_recent_bmi < 26.5
	
	replace obese = 1 if age == 16 & gender == 1 & most_recent_bmi >= 27 & most_recent_bmi != .
	replace obese = 0 if age == 16 & gender == 1 & most_recent_bmi < 27
	
	replace obese = 1 if age == 17 & gender == 1 & most_recent_bmi >= 27.5 & most_recent_bmi != .
	replace obese = 0 if age == 17 & gender == 1 & most_recent_bmi < 27.5
	
	replace obese = 1 if age == 18 & gender == 1 & most_recent_bmi >= 28.5 & most_recent_bmi != .
	replace obese = 0 if age == 18 & gender == 1 & most_recent_bmi < 28.5
	
	
	//Girls 2-18
	replace obese = 1 if age == 2 & gender == 2 & most_recent_bmi >= 18.5 & most_recent_bmi != .
	replace obese = 0 if age == 2 & gender == 2 & most_recent_bmi < 18.5
	
	replace obese = 1 if age == 3 & gender == 2 & most_recent_bmi >= 18.5 & most_recent_bmi != .
	replace obese = 0 if age == 3 & gender == 2 & most_recent_bmi < 18.5
	
	replace obese = 1 if age == 4 & gender == 2 & most_recent_bmi >= 19 & most_recent_bmi != .
	replace obese = 0 if age == 4 & gender == 2 & most_recent_bmi < 19
	
	replace obese = 1 if age == 5 & gender == 2 & most_recent_bmi >= 19.5 & most_recent_bmi != .
	replace obese = 0 if age == 5 & gender == 2 & most_recent_bmi < 19.5
	
	
	replace obese = 1 if age == 6 & gender == 2 & most_recent_bmi >= 20 & most_recent_bmi != .
	replace obese = 0 if age == 6 & gender == 2 & most_recent_bmi < 20
	
	replace obese = 1 if age == 7 & gender == 2 & most_recent_bmi >= 20.5 & most_recent_bmi != .
	replace obese = 0 if age == 7 & gender == 2 & most_recent_bmi < 20.5
	
	replace obese = 1 if age == 8 & gender == 2 & most_recent_bmi >= 21.5 & most_recent_bmi != .
	replace obese = 0 if age == 8 & gender == 2 & most_recent_bmi < 21.5
	
	replace obese = 1 if age == 9 & gender == 2 & most_recent_bmi >= 22.5 & most_recent_bmi != .
	replace obese = 0 if age == 9 & gender == 2 & most_recent_bmi < 22.5
	
	replace obese = 1 if age == 10 & gender == 2 & most_recent_bmi >= 23.5 & most_recent_bmi != .
	replace obese = 0 if age == 10 & gender == 2 & most_recent_bmi < 23.5
	
	replace obese = 1 if age == 11 & gender == 2 & most_recent_bmi >= 24.5 & most_recent_bmi != .
	replace obese = 0 if age == 11 & gender == 2 & most_recent_bmi < 24.5
	
	replace obese = 1 if age == 12 & gender == 2 & most_recent_bmi >= 25.5 & most_recent_bmi != .
	replace obese = 0 if age == 12 & gender == 2 & most_recent_bmi < 25.5
	
	replace obese = 1 if age == 13 & gender == 2 & most_recent_bmi >= 26 & most_recent_bmi != .
	replace obese = 0 if age == 13 & gender == 2 & most_recent_bmi < 26
	
	replace obese = 1 if age == 14 & gender == 2 & most_recent_bmi >= 27 & most_recent_bmi != .
	replace obese = 0 if age == 14 & gender == 2 & most_recent_bmi < 27
	
	replace obese = 1 if age == 15 & gender == 2 & most_recent_bmi >= 27.5 & most_recent_bmi != .
	replace obese = 0 if age == 15 & gender == 2 & most_recent_bmi < 27.5
	
	replace obese = 1 if age == 16 & gender == 2 & most_recent_bmi >= 28 & most_recent_bmi != .
	replace obese = 0 if age == 16 & gender == 2 & most_recent_bmi < 28
	
	replace obese = 1 if age == 17 & gender == 2 & most_recent_bmi >= 28.5 & most_recent_bmi != .
	replace obese = 0 if age == 17 & gender == 2 & most_recent_bmi < 28.5
	
	replace obese = 1 if age == 18 & gender == 2 & most_recent_bmi >= 28.5 & most_recent_bmi != .
	replace obese = 0 if age == 18 & gender == 2 & most_recent_bmi < 28.5

	
	tab obese, missing
	
	//label people with unknown BMI
	label obese obeselbl
	replace obese = 2 if obese == .
	tab obese, missing
	
	rename most_recent obese_date
	
	drop toofar obese_code_date obese_code bmi_centile bmi_centile_date bmi bmi_date ///
		height height_date weight weight_date bmi_calc bmi_difference ///
		most_recent_centile most_recent_bmi most_recent_obese_code

	save "`data_dir'/builds/`cohort'_cohort_cm2", replace
}


log close
