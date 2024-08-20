* log task 1
log using "$log_dir/UNICEFP3_log_task1_august2024.smcl", replace
/***********************************************

UNICEF - P3 Statistics & Monitoring specialist Test

Date: 19 August 2024
Objective: Solution TASK 1

***********************************************/

***********************************************
*	Contents
***********************************************
		*(1.0) Task 1
			*1.1 import data
			*1.2 merge datasets
			*1.3 population-weighted coverage for on-track and off-track countries for ANC4 
			*1.4 population-weighted coverage for on-track and off-track countries for SAB 
			*1.5 Graph 
		
		
************************************************
*(1.0) Task 1
************************************************


	* 1.1 import and clean datasets
 
		* Import UNICEF Global Data Repository
		import excel using "$data_raw/GLOBAL_DATAFLOW_2018-2022.xlsx", sheet("Unicef data") cellrange("A1:U448") firstrow clear 
		
		desc 
		
		destring  TIME_PERIOD OBS_VALUE, replace 
		ta ObservationStatus
		
		* encode var ObservationStatus Sex
		local varlist ObservationStatus Sex Indicator
		foreach var in 	`varlist' {
			encode `var', gen(`var'_encoded)
			drop `var'  // drop string variable
		}
		
		* drop variables with all missing observations (LOWER_BOUND, UPPER_BOUND, WGTD_SAMPL_SIZE, SERIES_FOOTNOTE, CUSTODIAN, REF_PERIOD)
		 foreach var of varlist _all {
		   capture assert mi(`var')
			 if !_rc {
				di "`var'"
				drop `var'
			 }
		}
		
		rename Geographicarea OfficialName
		
		* Keep all 142 countires since the time period of the indicator value for ANC4 and SAB is within the time period 2018-2022 for each country in the dataset 
		 ta TIME_PERIOD	
		
		*Keep only the most recent observation of ANC4 and SAB indicator
		assert !missing(OfficialName)
		bysort OfficialName: egen max_time_period = max(TIME_PERIOD)
		keep if max_time_period == TIME_PERIOD 

		
		* keep relevant variables
		keep   OfficialName Indicator_encoded TIME_PERIOD OBS_VALUE  ObservationStatus Sex
		label define indicator_2 ///
			 1 "ANC4" ///
			 2 "SAB"
		label value  Indicator_encoded indicator_2
		
		
		* save intermediate dataset 
		preserve 
			keep if Indicator_encoded == 1 
			save "$data_int/ANC4.dta", replace
		restore
		
		preserve 
			keep if Indicator_encoded == 2
			save "$data_int/SAB.dta", replace
		restore
		
		
		* import United Nations World Population Prospects population estimates
		import excel using "$data_raw/WPP2022_GEN_F01_DEMOGRAPHIC_INDICATORS_COMPACT_REV1.xlsx", sheet("Projections") cellrange("A17:BM22615") clear firstrow
	
		desc
		
		* drop variables with all missing observations (NO VARIABLES DROPPED)
		 foreach var of varlist _all {
		   capture assert mi(`var')
			 if !_rc {
				di "`var'"
				drop `var'
			 }
		}
		
		* rename according to dataset name
		rename (BJ BK) (MaleMortalitybetweenAge15and60 FemaleMortalitybetweenAge15and60)
		
		* drop line for aggregate region
		drop if Regionsubregioncountryorar == "Sustainable Development Goal (SDG) regions" | Regionsubregioncountryorar == "UN development groups" | Regionsubregioncountryorar == "World Bank income groups" | Regionsubregioncountryorar == "Geographic regions" 
		
		* replace string value with missing for all numeric variables
		foreach var of varlist TotalPopulationasof1Januar-NetMigrationRateper1000po { 
    replace `var' = "" if `var' == "..."
}
		* destring all pulation projections
		destring TotalPopulationasof1Januar-NetMigrationRateper1000po, replace  
		
		encode Type , gen(type_encoded)
		drop Type
		
		sort Regionsubregioncountryorar
		
		*drop aggregate estimates 
		drop if ISO3Alphacode == ""
		unique ISO3Alphacode // 237 country in the record
		rename ISO3Alphacode ISO3Code
		
		replace ISO3Code = "RKS" if ISO3Code == "XKX" // replaced ISO3Code for Kosovo because ISO3Alphacode is different than under five mortality dataset 
		keep if Year == 2022 // keep only year 2022 as per the task instructions
		count 
		assert _N == 237
		
		* save intermediate dataset 
		save "$data_int/pop_projection.dta", replace

		

		* import Under-five mortality on-track and off-track classifications
		import excel using "$data_raw/On-track and off-track countries.xlsx", sheet("Sheet1") clear firstrow
		
		desc
		
		encode StatusU5MR, gen (statusu5mr_encoded) 
		drop StatusU5MR
		
		unique ISO3Code 
		local _N = r(unique)
		
		* save intermediate dataset 
		save "$data_int/u5mr.dta", replace
	
	
	*1.2 merge datasets
	
		use "$data_int/u5mr.dta", clear // use the list of countries with on-track and off-track data as master list

		* merge with population estimates
		merge 1:m ISO3Code using "$data_int/pop_projection.dta" // the dataset with the population estimates contains more countries than the master. Keep only exact matches
		
		unique ISO3Code if _merge == 3
		local _N_merge = r(unique)
		drop _merge
		
		* check that all countries have an exact match
		assert `_N' == `_N_merge'
		
		* check that offical name of the countries in the two dataset matches 
		gen check_off_name = OfficialName == Regionsubregioncountryorar
		
		* Identify countries with Offical Name missmatch - decide to use OfficalName for the merge with ANC4 and SAB because name of the country matches wth OfficalName variable
		preserve	
			keep OfficialName Regionsubregioncountryorar check_off_name
			duplicates drop 
			list OfficialName Regionsubregioncountryorar if check_off_name == 0 
		
		
		/*
		 +-------------------------------------------------------------------------+
     |                          OfficialName        Regionsubregioncountryorar |
     |-------------------------------------------------------------------------|
 62. |      Micronesia (Federated States of)       Micronesia (Fed. States of) |
132. |          Netherlands (Kingdom of the)                       Netherlands |
145. | Democratic People's Republic of Korea   Dem. People's Republic of Korea |
150. |                   Kosovo (UNSCR 1244)     Kosovo (under UNSC res. 1244) |
189. |                         United States          United States of America |
     +-------------------------------------------------------------------------+
		*/
		restore
		
		* temporarely save dataset for use for the SAB dataset
		save "$data_int/pop_est_u5mr.dta", replace
		
		* merge with ANC4 dataset
		merge m:m OfficialName using "$data_int/ANC4.dta"
		
		* Investigate non matches
		preserve 
			keep ISO3Code OfficialName _merge
			duplicates drop 
			keep if _merge == 2
			count
			list OfficialName 
			
			/*
		+-----------------------------------------+
     |                            OfficialName |
     |-----------------------------------------|
  1. |                                  Africa |
  2. |                                Americas |
  3. |                             Arab States |
  4. |                    Asia and the Pacific |
  5. |                               Caribbean |
     |-----------------------------------------|
  6. |                         Central America |
  7. |                            Central Asia |
  8. |                   East Asia and Pacific |
  9. |                East and Southern Africa |
 10. |                          Eastern Africa |
     |-----------------------------------------|
 11. |                            Eastern Asia |
 12. |         Eastern Europe and Central Asia |
 13. |                   Eastern Mediterranean |
 14. |             Eastern and Southern Africa |
 15. |                                  Europe |
     |-----------------------------------------|
 16. |                 Europe and Central Asia |
 17. | Landlocked developing countries (LLDCs) |
 18. |         Latin America and the Caribbean |
 19. |               Least developed countries |
 20. |                           Middle Africa |
     |-----------------------------------------|
 21. |            Middle East and North Africa |
 22. |                           North America |
 23. |                         Northern Africa |
 24. |                                 Oceania |
 25. |   Small Island Developing States (SIDS) |
     |-----------------------------------------|
 26. |                           South America |
 27. |                              South Asia |
 28. |                      South-Eastern Asia |
 29. |                          Southeast Asia |
 30. |                         Southern Africa |
     |-----------------------------------------|
 31. |                           Southern Asia |
 32. |                      Sub-Saharan Africa |
 33. |       UNICEF Programme Regions - Global |
 34. |                 West and Central Africa |
 35. |                          Western Africa |
     |-----------------------------------------|
 36. |                            Western Asia |
 37. |                         Western Pacific |
 38. |                                   World |

			*/
		restore
		
		* drop all non matches from using because are data for aggregate countries
		drop if _merge == 2
		
		* drop all non matches from master because it is missing the antenatal care data
		drop if _merge == 1
		
		drop _merge
	
		unique OfficialName	// 72 Countries are unique with ANC4 data
		local _N_countries_AN4 = r(unique)
	
		assert _N == `_N_countries_AN4'
		
		keep ISO3Code OfficialName statusu5mr_encoded Year TotalPopulationasof1Januar Birthsthousands TIME_PERIOD OBS_VALUE ObservationStatus_encoded Sex_encoded Indicator_encoded
		
		*save dataset for ANC4 anaysis
		save "$data_fin/ANC4_data.dta", replace
		
		
		* create datasewt for SAB analysis
		use "$data_int/pop_est_u5mr.dta", clear
		
		*merge with SAB dataset
		merge m:m OfficialName using "$data_int/SAB.dta"
		
		* Investigate non matches
		preserve 
			keep ISO3Code OfficialName _merge
			duplicates drop 
			keep if _merge == 2
			count
			list OfficialName 
			
			/*
	   +-----------------------------------+
     |                      OfficialName |
     |-----------------------------------|
  1. |                            Africa |
  2. |                          Americas |
  3. |                           Bermuda |
  4. |             East Asia and Pacific |
  5. |             Eastern Mediterranean |
     |-----------------------------------|
  6. |       Eastern and Southern Africa |
  7. |                            Europe |
  8. |           Europe and Central Asia |
  9. |   Latin America and the Caribbean |
 10. |      Middle East and North Africa |
     |-----------------------------------|
 11. |                     North America |
 12. |                        South Asia |
 13. |                    Southeast Asia |
 14. |                Sub-Saharan Africa |
 15. | UNICEF Programme Regions - Global |
     |-----------------------------------|
 16. |           West and Central Africa |
 17. |                   Western Pacific |
 18. |                             World |
     +-----------------------------------+


			*/
		restore
		
		* drop all non matches from using because are data for aggregate countries
		drop if _merge == 2
		
		* drop all non matches from master because it is missing the SAB data
		drop if _merge == 1
		
		drop _merge
	
		unique OfficialName	// 130 Countries are unique with SAB data
		local _N_countries_SAB = r(unique)
		 
		*Keep only the population estimate value corresponding to the most recent coverage time for AN4 data
		
		assert _N == `_N_countries_SAB'
		
		keep ISO3Code OfficialName statusu5mr_encoded Year TotalPopulationasof1Januar Birthsthousands TIME_PERIOD OBS_VALUE ObservationStatus_encoded Sex_encoded Indicator_encoded
		save "$data_fin/SAB_data.dta", replace
		
	
	*1.3 population-weighted coverage for on-track and off-track countries for ANC4 

		use "$data_fin/ANC4_data.dta", replace
		
		
		* achived - on track countries
		gen weighted_pb =  (OBS_VALUE/100) * Birthsthousands if statusu5mr_encoded == 2 | statusu5mr_encoded == 3
		egen sum_wpb = total(weighted_pb)   if statusu5mr_encoded == 2 | statusu5mr_encoded == 3 // sum of weighted projected birth
		egen sum_pb = total(Birthsthousands)  if statusu5mr_encoded == 2 | statusu5mr_encoded == 3  // sum of projected birth
		
		* Weighted coverage for ANC4
		gen wc_anc4 = (sum_wpb/sum_pb) * 100 if statusu5mr_encoded == 2 | statusu5mr_encoded == 3
		
		
		* accellearion needed countries
		replace weighted_pb =  (OBS_VALUE/100) * Birthsthousands if statusu5mr_encoded == 1
		egen sum_wpb_acc = total(weighted_pb)   if statusu5mr_encoded == 1 // sum of weighted projected birth
		egen sum_pb_acc = total(Birthsthousands)  if statusu5mr_encoded == 1  // sum of projected birth
		
		* Weighted coverage for ANC4
		replace wc_anc4 = (sum_wpb_acc/sum_pb_acc) * 100 if statusu5mr_encoded == 1
		
		gen group = 1 if statusu5mr_encoded == 1
		replace group  = 2 if statusu5mr_encoded == 2 | statusu5mr_encoded == 3 
		egen N_countrie_a = count(ISO3Code) if statusu5mr_encoded == 1
		egen N_countries_b = count(ISO3Code) if statusu5mr_encoded == 2 | statusu5mr_encoded == 3 
		gen N_countries_anc4 = N_countrie_a 
		replace  N_countries_anc4 = N_countries_b if missing(N_countries_anc4)
		
		
		label define group ///
		 1 "Accelleration needed" ///
		 2 "On-track/Achived"
		label value group group
		
		collapse  wc_anc4 N_countries_anc4, by(group)

		rename (wc_anc4 N_countries_anc4) (indice_1 N_countries_1)
		tempfile wc_anc4
		save `wc_anc4'
		

	*1.4 population-weighted coverage for on-track and off-track countries for SAB 
	
		use "$data_fin/SAB_data.dta", replace
				
		* achived - on track countries
		gen weighted_pb =  (OBS_VALUE/100) * Birthsthousands if statusu5mr_encoded == 2 | statusu5mr_encoded == 3
		egen sum_wpb = total(weighted_pb)   if statusu5mr_encoded == 2 | statusu5mr_encoded == 3 // sum of weighted projected birth
		egen sum_pb = total(Birthsthousands)  if statusu5mr_encoded == 2 | statusu5mr_encoded == 3  // sum of projected birth
		
		* Weighted coverage for ANC4
		gen wc_sab = (sum_wpb/sum_pb) * 100  if statusu5mr_encoded == 2 | statusu5mr_encoded == 3
		
		
		* accellearion needed countries
		replace weighted_pb =  (OBS_VALUE/100) * Birthsthousands if statusu5mr_encoded == 1
		egen sum_wpb_acc = total(weighted_pb)   if statusu5mr_encoded == 1 // sum of weighted projected birth
		egen sum_pb_acc = total(Birthsthousands)  if statusu5mr_encoded == 1  // sum of projected birth
		
		* Weighted coverage for ANC4
		replace wc_sab = (sum_wpb_acc/sum_pb_acc) * 100  if statusu5mr_encoded == 1
		
		
		gen group = 1 if statusu5mr_encoded == 1
		replace group  = 2 if statusu5mr_encoded == 2 | statusu5mr_encoded == 3 
		egen N_countrie_a = count(ISO3Code) if statusu5mr_encoded == 1
		egen N_countries_b = count(ISO3Code) if statusu5mr_encoded == 2 | statusu5mr_encoded == 3 
		gen N_countries_sab = N_countrie_a 
		replace  N_countries_sab = N_countries_b if missing(N_countries_sab)
		
		
		label define group ///
		 1 "Accelleration needed" ///
		 2 "On-track/Achived"
		label value group group
		
		collapse  wc_sab N_countries_sab, by(group)
	
		rename (wc_sab N_countries_sab) (indice_2 N_countries_2)
		
		* merge 
		merge 1:1 group using `wc_anc4', assert(3) nogen 
		

	*1.5 Graph 
	
	reshape long indice_ N_countries_, i(group) j(var)
	
	tostring var, replace
	replace var = "ANC4" if var == "1"
	replace var = "SAB" if var == "2"
	
	* set global graph settings
    global graph_opts1    ///
				///
           graphregion(color(white))          ///
           legend(region(lc(none) fc(none)))  ///
           ylab(,angle(0) nogrid)             ///
           title(, justification(center) color(black) span pos(17)) ///
           subtitle(, justification(left) color(black))
		   
	graph bar indice_ ///
        , ///
          asy ///
		  over(group) ///
		  over(var) ///
          bargap(20) ///
          nofill ///
          blabel(bar, format(%9.2f)) ///
          ${graph_opts1} ///
          bar(1 , lc(black) lw(thin) fi(100) color(ltblue )) ///
          bar(2 , lc(black) lw(thin) fi(100) color(blue)) ///
          legend(r(1) ///
          order(0 "Weighted averages:" 1 "off-track" 2 "on-track")) ///
          ytit("Percentage {&rarr}", ///
               placement(bottom) ///
               justification(left)) ///
          ylab(${pct}) ///
		  title("Weighted averages of ANC4 and SAB") ///
		  note("Note: For ANC4, both on-track and off-track weighted averages are composed by 36 countries." ///
		  "	     For SAB, off-track countries are 33 and on-track countries are 97. " ///
		  ,size(2)) ///
                ysize(4) ///
				xsize (10)
	
	* save and export bar plot of anc4 and sab
	graph export "$out_graph/bar_plot_anc4_sab.png", replace	

	capture log close	  