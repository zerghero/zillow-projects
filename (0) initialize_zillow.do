* initialize zillow data
* Created by: Danton Noriega, Georgetown University (Feb 2013)
* This .do file does the following:
*	- makes a master list of property IDs with addresses etc
* 	- stacks all the property attibute data and then merges the master property list

*clear all
set more off
pause off

global dir "D:/Dan's Workspace/Zillow/"
cd "$dir"

local import_yn = 1 // toggle importing of data

/* clear data sets and import */
if (`import_yn' == 1) {
	!rmdir "data sets" /s /q
	!mkdir "data sets"
	
	foreach dataset in "data_wo_descriptions" ///
	"data_fields72_75" ///
	"data_descriptions" {
	
		disp "importing `dataset'"
		import delimited "D:/Work/Research/Zillow/raw_data/`dataset'.txt", clear
		
		* make all string lowercase and trim leading blanks
		foreach var of varlist _all {
			capture confirm numeric variable `var' // check to see if string type
			if (!_rc) disp "numeric"
			else {
				replace `var' = lower(`var')	// if no error return (i.e. string), then replace with lower
				replace `var' = trim(`var')
			}
		
		save "data sets/`dataset'", replace
		}
	}
}

/* take the zillow text files and import (if toggled) to stata then append (stack) */
local k = 1
	
/* save one dataset of just property IDs and addresses etc */
foreach dataset in "data_wo_descriptions" ///
"data_fields72_75" ///
"data_descriptions" {
	
	if ("`dataset'" == "data_wo_descriptions") {
		do "$github\(0.1) zillow_property_list.do"
	}
	
	if (`k' == 1) {
		use "data sets/`dataset'", clear
		keep propertyid attributevalue propertyattributetypedisplayname propertyattributetypeid
		save "data sets/zillow_stacked", replace
	}
	else {	
		use "data sets/`dataset'", clear
		keep propertyid attributevalue propertyattributetypedisplayname propertyattributetypeid
		append using "data sets/zillow_stacked"
		save "data sets/zillow_stacked", replace
	}
	
	local k = `k' + 1
	
}

*
sort propertyattributetypeid propertyattributetypedisplayname attributevalue propertyid	
save "data sets/zillow_stacked", replace


* merge data, drop problem ids, then reshape
use "data sets/zillow_stacked", clear
merge m:1 propertyid using "data sets/zillow_property_list", nogen
merge m:1 propertyid using "data sets/list_of_removed_properties", nogen
drop if inputerror == 1 // drop the nonunique/input error properties
drop inputerror // drop the input error variable
sort propertyattributetypeid propertyattributetypedisplayname attributevalue propertyid

* rename variables
rename propertyid pid
rename propertyattributetypeid atype
rename propertyattributetypedisplayname aname
rename attributevalue avalue

label variable pid "Property ID"
label variable atype "property Attribute TYPE id"
label variable aname "property Attribute type display NAME"
label variable avalue "Attribute VALUE"

save "data sets/zillow_stacked_merged", replace




