
/***********************************************

UNICEF - P3 Statistics & Monitoring specialist Test

Date: 19 August 2024
Objective: Solution TASK 2

***********************************************/

***********************************************
*	Contents
***********************************************
*(1.0) Task 2
			*1. import data
			*2. prepare the data 
			*3. gen descriptive statistics
			*4. trend analysis
			*5. generate visualization
			
		
		
************************************************
*(1.0) Task 2
************************************************

	
	*1. import data
	
		import delimited using "$data_raw/Zimbabwe_children_under5_interview.csv",   clear 
		
		
	*2. prepare the data 
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
		misstable summarize
		
		return list
		local N_miss =   r(N_eq_dot)
		local N_ =   r(N_lt_dot)
		
		di `N_miss'/`N_' * 100  // = 1.0437575 -- given that the percentage of missing observatio is only 1% I prefer to drop missing observations instead of impute missing values. Another approach could be to impute missing data using the median value of the variable, using regression, or multiple imputation.
		
		* drop missing data
		drop if age_months_rounded == .
		
		* Inspect data
		summarize

	
	*3. gen descriptive statistics
	
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
		
		
		*4. trend analysis
		
		* Create a new dataset with the mean proportions by age month
		collapse (mean) literacy_math_prop physical_prop learning_prop socio_emotional_prop, by(age_months_rounded)

		* Line graph for literacy and math
		twoway (line literacy_math_prop age_months_rounded) (lfit literacy_math_prop age_months_rounded), ///
			title("Literacy and Math Performance by Age in Months", size(3)) ///
			ytitle("Proportion Meeting Milestones", size(2)) ///
			xtitle("Age in Months", size(2)) ///
			xscale(range(48 60)) ///
			xlabel(48(2)60) ///
			legend(off)
		graph save "$out_graph/literacy_math_prop.gph", replace	
			

		* Line graph for physical development
		twoway (line physical_prop age_months_rounded) (lfit physical_prop age_months_rounded), ///
			title("Physical Development by Age in Months", size(3)) ///
			ytitle("Proportion Meeting Milestones", size(2)) ///
			xtitle("Age in Months", size(2)) ///
			xscale(range(48 60)) ///
			xlabel(48(2)60) ///
			legend(off)
		
		graph save "$out_graph/physical_prop.gph", replace	
		
		
		* Line graph for learning
		twoway (line learning_prop age_months_rounded) (lfit learning_prop age_months_rounded), ///
			title("Learning Performance by Age in Months",  size(3)) ///
			ytitle("Proportion Meeting Milestones", size(2)) ///
			xtitle("Age in Months", size(2)) ///
			xscale(range(48 60)) ///
			xlabel(48(2)60) ///
			legend(off)
		
		graph save "$out_graph/learning_prop.gph", replace	
		
		
		* Line graph for socio-emotional development
		twoway (line socio_emotional_prop age_months_rounded)  (lfit socio_emotional_prop age_months_rounded), ///
			title("Socio-emotional Development by Age in Months", size(3)) ///
			ytitle("Proportion Meeting Milestones", size(2)) ///
			xtitle("Age in Months", size(2)) ///
			xscale(range(48 60)) ///
			xlabel(48(2)60) ///
			legend(off)

		graph save "$out_graph/socio_emotional_prop.gph", replace		


	*5. generate visualization
	
		* Combine the graphs into panels
		graph combine "$out_graph/literacy_math_prop.gph" "$out_graph/physical_prop.gph" "$out_graph/learning_prop.gph" "$out_graph/socio_emotional_prop.gph" , ///
			title("Educational Performance Trends by Age in Months") ///
			subtitle("Zimbabwe MICS6 Survey Data (2019)") ///
			

		graph export "$out_graph/panel.png", replace		