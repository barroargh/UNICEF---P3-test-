
/***********************************************

UNICEF - P3 Statistics & Monitoring specialist Test

Date: 20 August 2024
Objective: Solution TASK 2

***********************************************/


* log task 2
log using "$log_dir/UNICEFP3_log_task2_august2024.smcl", replace
***********************************************
*	Contents
***********************************************
*(2.0) Task 2
			*2.1. import data
			*2.2. prepare the data 
			*2.3. gen descriptive statistics
			*2.4. trend analysis
			*2.5. generate visualization
			
		
************************************************
*(2.0) Task 2
************************************************
	
	*2.1. import data
	
		import delimited using "$data_raw/Zimbabwe_children_under5_interview.csv",   clear 
		
		
	*2.2. prepare the data 
		rename ïinterview_date interview_date
	
		* Convert date variables
		gen interview_date_ = date(interview_date, "YMD")
		gen child_birthday_ = date(child_birthday, "YMD")

		format interview_date_ child_birthday_ %td

		* Create age in months
		gen age_months = (interview_date_ - child_birthday_)/30 // assuming 30 days per in each month

		keep if age_months >= 12*4 & age_months <= 12*5 // keep only observation for students between 4 and 5 years old included
		
		* round age_month to the nearest whole number
		gen age_months_rounded = round(age_months)

		* Handle missing data 
		* Check for missing data
		misstable summarize // for the selected sub-sample of students between 48 and 60 months there are no missing values in any of the indicators. No further analysis needed
		
		* Inspect data
		summarize

	
	*2.3. gen descriptive statistics
	
		* Proportion of students meeting literacy and math milestones
		gen literacy_math = (ec6 == 1) + (ec7 == 1) + (ec8 == 1)
		gen literacy_math_prop = literacy_math / 3

		* Proportion of students meeting physical milestones
		gen physical = (ec9 == 1) + (ec10 == 1)
		gen physical_prop = physical / 2

		* Proportion of students meeting learning milestones
		gen learning = (ec11 == 1) + (ec12 == 1)
		gen learning_prop = learning / 2

		* Proportion of students meeting socio-emotional milestones
		gen socio_emotional = (ec13 == 1) + (ec14 == 1) + (ec15 == 1)
		gen socio_emotional_prop = socio_emotional / 3

		* Summary statistics by age month
		bysort age_months_rounded: summarize literacy_math_prop physical_prop learning_prop socio_emotional_prop
		
		sum learning_prop
		
		* save dataset
		save "$data_fin/Mother_Caregiver_cu5_level_dataset.dta", replace
		
	*2.4. trend analysis
		
		* Create a new dataset with the mean proportions by age month
		collapse (mean) literacy_math_prop physical_prop learning_prop socio_emotional_prop, by(age_months_rounded)
		
		* save dataset
		save "$data_fin/Mother_Caregiver_cmau5_level_dataset.dta", replace
		
		* Regression for Literacy and Math
		regress literacy_math_prop age_months_rounded
		test _b[age_months_rounded] = 0

		* Regression for Physical Development
		regress physical_prop age_months_rounded
		test _b[age_months_rounded] = 0

		* Regression for Learning
		regress learning_prop age_months_rounded
		test _b[age_months_rounded] = 0

		* Regression for Socio-emotional Development
		regress socio_emotional_prop age_months_rounded
		test _b[age_months_rounded] = 0
				
		
		* Line graph for literacy and numeracy
		twoway (lfitci literacy_math_prop age_months_rounded, color("222 235 247") lwidth(.05) lwidth(medium)) (lfit literacy_math_prop age_months_rounded, color(red) lwidth(.5) lpattern(dash))  (line literacy_math_prop age_months_rounded, msize(medium) color(edkblue)), ///
			   title("Literacy and Math Performance by Age in Months", size(3)) ///
			   ytitle("Proportion Meeting Milestones", size(2)) ///
			   xtitle("Age in Months", size(2)) ///
			   xscale(range(48 60)) ///
			   xlabel(48(2)60) ///
			   legend(off) ///
			   graphregion(color(white)) bgcolor(white) ///
			   note("Trend statistically different from zero at the 5% level", size(2))
		
		* save graph literacy and numeracy
		graph save "$out_graph/literacy_math_prop.gph", replace	
			

		* Line graph for physical development
		twoway (lfitci physical_prop age_months_rounded, color("222 235 247") lwidth(.05) lwidth(medium)) (lfit physical_prop age_months_rounded, color(red) lwidth(.5) lpattern(dash)) (line physical_prop age_months_rounded, msize(medium) color(edkblue)), ///
			   title("Physical Development by Age in Months", size(3)) ///
			   ytitle("Proportion Meeting Milestones", size(2)) ///
			   xtitle("Age in Months", size(2)) ///
			   xscale(range(48 60)) ///
			   xlabel(48(2)60) ///
			   legend(off) ///
			   graphregion(color(white)) bgcolor(white) ///
			   note("Trend statistically different from zero at the 5% level", size(2))
		
		* save graph physical development
		graph save "$out_graph/physical_prop.gph", replace	
		
		
		* Line graph for learning
		twoway (lfitci learning_prop age_months_rounded, color("222 235 247") lwidth(.05) lwidth(medium)) (lfit learning_prop age_months_rounded, color(red) lwidth(.5) lpattern(dash)) (line learning_prop age_months_rounded, msize(medium) color(edkblue)), ///
			   title("Learning Performance by Age in Months", size(3)) ///
			   ytitle("Proportion Meeting Milestones", size(2)) ///
			   xtitle("Age in Months", size(2)) ///
			   xscale(range(48 60)) ///
			   xlabel(48(2)60) ///
			   legend(off) ///
			   graphregion(color(white)) bgcolor(white) ///
			   note("Trend NOT statistically different from zero", size(2))
		
		* save graph learning achivements
		graph save "$out_graph/learning_prop.gph", replace	
		
		
		* Line graph for socio-emotional development
		twoway (lfitci socio_emotional_prop age_months_rounded, color("222 235 247") lwidth(.05) lwidth(medium)) (lfit socio_emotional_prop age_months_rounded, color(red) lwidth(.5) lpattern(dash)) (line socio_emotional_prop age_months_rounded, msize(medium) color(edkblue)), ///
			   title("Socio-emotional Development by Age in Months", size(3)) ///
			   ytitle("Proportion Meeting Milestones", size(2)) ///
			   xtitle("Age in Months", size(2)) ///
			   xscale(range(48 60)) ///
			   xlabel(48(2)60) ///
			   legend(off) ///
			   graphregion(color(white)) bgcolor(white) ///
			   note("Trend statistically different from zero at the 10% level", size(2))
		
		* save graph learning socio-emotional development
		graph save "$out_graph/socio_emotional_prop.gph", replace		


	*2.5. generate visualization
	
		* Combine the graphs into panels
		graph combine "$out_graph/literacy_math_prop.gph" "$out_graph/physical_prop.gph" "$out_graph/learning_prop.gph" "$out_graph/socio_emotional_prop.gph" , ///
			title("Educational Performance Trends by Age in Months") ///
			subtitle("Zimbabwe MICS6 Survey Data (2019)") ///
			
		* save and export combined graph of literacy and numeracy, physical development, socio-emotional development, and socio-emotional development
		graph export "$out_graph/panel.png", replace
		
		capture log close