
/***********************************************

UNICEF - P3 Statistics & Monitoring specialist Test

Date: 24 April 2023
Objective: Solution to the test

***********************************************/


***********************************************

*	Contents
***********************************************

		*(0.1) Common setup
		*(0.2) Specific setup for this do-file
		
		
		*(1.0) Task 1
		*(2.0) Task 2
		
************************************************

*(0.1) Common setup
************************************************
		
		global home_dir "C:\Users\Public\UNICEF\UNICEF-P3-assessment-public\Solution" // update the directory as needed
		
		
		global data_dir   "$home_dir/data"
		global out_dir    "$home_dir/output"
		global code		  "$home_dir/code"
		global log_dir    "$out_dir/logs"
		
		
************************************************

*(0.2) Specific setup for this do-file
************************************************

		clear matrix
		clear 
		set more off
		
		
		capture log close
		log using "$log_dir/test_august2024.smcl", replace
		
************************************************

*(1.0) Import data
************************************************
