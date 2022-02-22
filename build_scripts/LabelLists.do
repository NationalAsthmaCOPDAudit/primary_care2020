clear
set more off

cd "D:\GitHub\nacap\primary_care2020"

/* create log file */
capture log close
log using outputs/COPD_labels, text replace


local data_dir "D:\National Asthma and COPD Audit Programme (NACAP)\2020 Primary Care Audit"


use "`data_dir'/builds/copd_final", clear

label list

log close


log using outputs/AsthmaAdult_labels, text replace

use "`data_dir'/builds/asthma_adult_final", clear

label list

log close


log using outputs/AsthmaChild_1-5_labels, text replace

use "`data_dir'/builds/asthma_child_1-5_final", clear

label list

log close


log using outputs/AsthmaChild_6-18_labels, text replace

use "`data_dir'/builds/asthma_child_6-18_final", clear

label list

log close
