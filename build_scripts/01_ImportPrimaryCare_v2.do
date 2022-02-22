clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* Create log file */
capture log close
log using build_logs/01_ImportPrimaryCare_v2, smcl replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"

local extraction = date("2020-10-07", "YMD")  //date of data extraction


//list of practice files
local files : dir "`data_dir'/raw_data/download_2020-10-14/decrypt/unzip" files "*_ASTCOPD18_P.csv"

local practices ""
local count = 0

foreach file in `files' {  //extract list of practice IDs
	
	local count = `count' + 1
	local practice = substr(upper("`file'"), 1, 6)
	local practices "`practices' `practice'"
}

display "`count' practices"

foreach practice of local practices {

	tempfile `practice'_pts `practice'_evnts1 `practice'_evnts2

	import delimited "`data_dir'/raw_data/download_2020-10-14/decrypt/unzip/`practice'_ASTCOPD18_P.csv", ///
			varnames(nonames) rowrange(2) asdouble clear
	keep v1-v5
	rename v1 pracid
	rename v2 patid
	rename v3 gender
	rename v4 age
	rename v5 wimd_rank
	save ``practice'_pts'
	
	import delimited "`data_dir'/raw_data/download_2020-10-14/decrypt/unzip/`practice'_ASTCOPD18.csv", ///
			varnames(nonames) rowrange(2) asdouble clear
	keep v1-v5
	rename v1 pracid
	rename v2 patid
	rename v3 readcode5B
	rename v4 readcode_value
	rename v5 eventdate
	save ``practice'_evnts1'
	
	import delimited "`data_dir'/raw_data/download_2020-10-14/decrypt/unzip/`practice'_ASTCOPD18_2.csv", ///
			varnames(nonames) rowrange(2) asdouble clear
	keep v1-v5
	rename v1 pracid
	rename v2 patid
	rename v3 readcode5B
	rename v4 readcode_value
	rename v5 eventdate
	save ``practice'_evnts2'
}


local firstprac `: word 1 of `practices''

foreach practice of local practices {

	if "`practice'" == "`firstprac'" {
		
		display "First Practice: `firstprac'"
		use ``practice'_pts', clear
	}
	else {
		
		append using ``practice'_pts'
		display "Appended: `practice'"
	}
}

replace gender = "1" if gender == "M"
replace gender = "2" if gender == "F"
replace gender = "3" if gender == "U"
destring gender, replace
label define gender 1 "Male" 2 "Female" 3 "Unknown"
label values gender gender

compress

duplicates list pracid patid
duplicates tag pracid patid, gen(dup)
tab dup, missing
drop if dup > 0   //remove all patients with duplicate IDs
drop dup

count
tab pracid, missing
tab gender, missing
summarize age, detail
summarize wimd_rank, detail
tab wimd_rank, missing
tab pracid if wimd_rank == 0

save "`data_dir'/stata_data/PC_patients", replace


foreach practice of local practices {

	if "`practice'" == "`firstprac'" {
		
		display "First Practice: `firstprac'"
		use ``practice'_evnts1', clear
	}
	else {
		
		append using ``practice'_evnts1'
		display "Appended: `practice'_evnts1"
	}
	
	append using ``practice'_evnts2'
	display "Appended: `practice'_evnts2"
}

replace readcode5B = substr(strtrim(readcode5B)+"....", 1, 5)

tostring eventdate, gen(ed)
replace eventdate = date(ed, "YMD")
format eventdate %td
display "eventdate before date conversion..."
codebook ed
drop ed
display "eventdate after date conversion..."
codebook eventdate

drop if eventdate == .   //remove events with erroneous dates
drop if eventdate < date("1902-02-02", "YMD")   //remove unlikely dates
drop if eventdate > `extraction'                //remove events after first extraction

compress

tab readcode5B, missing
codebook readcode_value
summarize readcode_value, detail
sum eventdate, detail format

save "`data_dir'/stata_data/PC_events", replace


log close
set linesize 100
translate build_logs/01_ImportPrimaryCare_v2.smcl build_logs/01_ImportPrimaryCare_v2.log, replace
