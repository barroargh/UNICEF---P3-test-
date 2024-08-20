
/***********************************************

UNICEF - P3 Statistics & Monitoring specialist Test

Date: 19 August 2023
Objective: Set up main do file

***********************************************/


***********************************************
*	Contents
***********************************************

		*(0.1) Common setup
		*(0.2) Specific setup for this do-file
		*(0.3) Run do-file TASK 1
		*(0.4) Run do-file TASK 2
 
		
************************************************
*(0.1) Common setup
************************************************
		
		global home_dir "C:\Users\Public\UNICEF\UNICEF-P3-assessment-public\Solution" // update the directory as needed
		
		
		global data_dir   "$home_dir/data"
		global data_raw   "$data_dir/raw_data"
		global data_int   "$data_dir/intermediate"
		global data_fin   "$data_dir/final"
		global out_dir    "$home_dir/output"
		global out_graph  "$out_dir/graphs"	
		global code_dir	  "$home_dir/code"
		global log_dir    "$out_dir/logs"
		
		
************************************************
*(0.2) Specific setup for this do-file
************************************************

		clear matrix
		clear 
		set more off
		version 16
		
		capture log close
		
		* local to run TASK 1 and 2 do files
		local task1 		1
		local task2			1
************************************************
*(0.3) Run do-file TASK 1
************************************************
	
	* Task 1
	if (`task1' == 1) {
		do "$code_dir/Task1.do"
	} 
 
	* Task 2
	if (`task2' == 1) {
		do "$code_dir/Task2.do"
	} 
 