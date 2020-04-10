*==============================================================================*
* TASK 017  Simulation od Covid19 impacts on Learning Poverty
* Author:   Diana Goldemberg
*==============================================================================*
quietly {

  *-----------------------------------------------------------------------------
  * Execution parameters
  *-----------------------------------------------------------------------------
  local days_to_simulate "25 50 75 100"

  * Paths for file manipulation in this program
  local cleandata   "${clone}/03_cleandata"
  local outputs     "${clone}/04_outputs"
  local proficiency_raw   "${clone}/02_rawdata/INEP_SAEB"
  *-----------------------------------------------------------------------------


  noi disp as txt _newline "Simulating Covid-19 impact..."


  * Open Brazilfull, which is the consolidated and ready to use dataset
  use "`cleandata'/brazilfull.dta", clear
  keep if threshold == "med"
  keep if subject   == "read"
  * CHANGE HERE FOR PUBLIC ONLY (private ==1  or both private and public, private == 9)
  keep if private   == 9

  * Generate variable to compare cohort progress
  gen int cohort = .
  replace cohort = (year - idgrade + 1) if idgrade != 0
  label var cohort "Year the cohort begin primary school"
  * The only two cohorts that are observed two points in time
  keep if inlist(cohort, 2007, 2009)

  * Reshape to cohort view
  local i_vars "geography uf statecode code countyname threshold subject private"
  local value_vars "year learning_poverty nonprof score net_enrollment population_1014"
  keep `i_vars' `value_vars' cohort  idgrade
  reshape wide `value_vars', i(`i_vars' cohort) j(idgrade)

  * Average daily gain in score and in bmp (800 school days in 4 years)
  gen gain_score = (score9 - score5) / 800
  label var gain_score "Average daily learning gain (points)"

  * Double check that gains are usually positive, at least for scores (yes in 99.9%)
  gen positive_gain_score = (gain_score > 0) if !missing(gain_score)
  tab positive_gain_score

  * Keep only the average gains, to plug into the latest LP
  keep `i_vars' gain_score cohort
  collapse (mean) gain_score, by(`i_vars')

  * Only the bare minimum to merge with proficiency
  keep if geography == "county"
  rename code idcounty
  keep idcounty gain_score
  save "`outputs'/LP_Brazil_schoolproductivity.dta", replace

  noi disp as txt "{phang}daily learning gains averaged from two cohorts between 5 and 9 grades{p_end}"

  *-----------------------------------------------------------------------------

  noi disp as txt "{phang}use 2017 microdata to simulate impact and collapse{p_end}"

  * New section of code (lame shortcut from proficiency script)

  use "${clone}/02_rawdata/INEP_SAEB/Downloads/SAEB_ALUNO_2017.dta", clear
  keep if idgrade == 5
  drop score_mt learner_weight_mt
  rename (score_lp learner_weight_lp) (score learner_weight)
  gen subject = "read"
  gen threshold = "med"
  label var subject    "Subject (read | math)"
  label var threshold  "Threshold used (low | med | adv)"
  * To be clear this is no longer 2017 data and that is both private and public
  * we will pretend this is data from 2019 = 2017 + simulated covid impact
  replace year = 2019
  replace private = 9

  * To replicate the aggregated data released by INEP, should filter this
  gen byte include_student = (in_situacao_censo==1)
  replace  include_student = 1 if missing(in_situacao_censo)

  * Brings the dataset of daily gains (county average)
  merge m:1 idcounty using "`outputs'/LP_Brazil_schoolproductivity.dta", nogen
  * Impute the (non-weighted) state average for municipalities with missing gain
  bys idstate: egen aux_gain_score = mean(gain_score)
  replace gain_score = aux_gain_score if missing(gain_score)
  drop aux_gain_score

  gen nonprof = (score < 200) if !missing(score)
  foreach value of local days_to_simulate {
    gen score_`value' = score - `value' * gain_score
    gen nonprof_`value' = (score_`value' < 200) if !missing(score_`value')
  }

  order year id* subject threshold private* in* learner_weight score* nonprof*
  save "`proficiency_raw'/SAEB_ALUNO_COVID.dta", replace

  * Collapse this dataset 3 times, one for each aggregation level
  foreach geography in county state country {
    preserve

      noi disp as txt "{phang2}at the `geography' level{p_end}"

      * Auxiliary variable for the collapse of country
      gen idcountry = 0

      collapse (mean) score_* nonprof_* if  include_student [aw = learner_weight], ///
              by(year idgrade private subject threshold id`geography')

      * Saves codes in such a way that we can append all later
      gen geography = "`geography'"
      gen code = id`geography'
      drop id`geography'

      save "`proficiency_raw'/SAEB_collapsed_`geography'.dta", replace

    restore
  }

  * Append county, state and country all together
  use          "`proficiency_raw'/SAEB_collapsed_country.dta", replace
  append using "`proficiency_raw'/SAEB_collapsed_state.dta"
  append using "`proficiency_raw'/SAEB_collapsed_county.dta"
  order year geography code private idgrade subject threshold score* nonprof*

  * Compress, check, save
  compress
  isid year geography code private idgrade subject threshold
  * This is the dataset that has nonprof_* and score_* that we'll plug in brazilfull
  save "`proficiency_raw'/SAEB_collapsed_covid.dta", replace

  * Tentativelly erase files no longer needed (same as in proficiency.do)
  foreach geography in county state country {
    cap erase "`proficiency_raw'/SAEB_collapsed_`geography'.dta"
  }

  *-----------------------------------------------------------------------------

  * Dropout estimation interlude
  * this section serves only to get the 2 locals: score_coeff & lp_coeff_eys

  noi disp as txt "{phang}interlude for coefficients on schooling{p_end}"

  tempfile dropout hci

  * Taxas de transição = Dropout is average (2011,2012,2013,2014)
  import delimited "${clone}/02_rawdata/INEP_Transicao/Taxa_Transicao_2011_14_EFI_EFF.csv", clear
  label var mean_dropout "Average annual drop-out rate (2011-14; EFI-EFF)"
  save "`dropout'", replace

  * Open brazilfull and keep only compatible years & settings
  use "${clone}/03_cleandata/brazilfull.dta", clear
  keep if geography == "county" & threshold == "med" & subject == "read" & private == 9 & inlist(year, 2011, 2013)
  * Average both years (score becomes average 2011 & 2013)
  collapse (mean) score enrolled_grade, by(code statecode countyname uf idgrade)
  merge 1:1 code idgrade using "`dropout'", keep(match master) nogen

  * Model the average dropout in EF1 (grade 1-5)
  reg mean_dropout score if idgrade == 5
  matrix coeff = e(b)
  * Save the coefficient on score
  local score_coeff = coeff[1,1]

  * HCI component Expected Years of Schooling
  import delimited "${clone}/02_rawdata/HCI/hci_edu_brazil.csv", clear
  rename code code6
  label var eys "Expected Years of Schooling"
  label var hlo "Adjusted Learning, All Grades"
  label var lays "exp(0.08*(EYS x HLO - 12))"
  keep if year == 2017
  save "`hci'", replace

  * Open brazilfull and keep only compatible years & settings
  use "${clone}/03_cleandata/brazilfull.dta", clear
  keep if geography == "county" & threshold == "med" & subject == "read" & private == 9 & year == 2017 & idgrade == 5
  * The last digit in IBGE7 code is a "verification" digit and can be safely dropped
  gen code6 = int(code/10)
  merge 1:1 code6 using "`hci'", keep(match master) nogen
  drop code6

  * Model the Expected Years of Schooling as linear in learningpoverty
  reg eys learning_poverty
  matrix coeff = e(b)
  * Save the coefficient on score
  local lp_coeff_eys = coeff[1,1]

  *-----------------------------------------------------------------------------
  * Back to the estimates

  * Opens brazilfull to starting point of 2017
  use "`cleandata'/brazilfull.dta", clear
  keep if year == 2017 & idgrade == 5 & threshold == "med" & subject == "read" & private == 9
  drop gap* behind* *test* *part* private_1014 year

  * The last digit in IBGE7 code is a "verification" digit and can be safely dropped
  gen code6 = int(code/10) if geography == "county"
  replace code6 = code if geography != "county"
  merge 1:1 code6 using "`hci'", keepusing(eys) keep(match master) nogen
  drop code6

  * Rename current values before adding 2019 estimated values
  foreach var in score nonprof learning_poverty net_enrollment eys {
    rename `var' `var'_base
  }
  * This brings the score_* and nonprof_*
  merge 1:1 code idgrade threshold subject private using "`proficiency_raw'/SAEB_collapsed_covid.dta", keep(match) nogen

  * Chosen score scenario
  foreach value of local days_to_simulate {

    * Use the regression on score to estimate the (lower) enrollment
    gen net_enrollment_`value' = net_enrollment_base + `score_coeff' * (score_base - score_`value')
    * Recalculate learning poverty
    gen learning_poverty_`value' = (nonprof_`value' * net_enrollment_`value') + (100 - net_enrollment_`value')
    * Calculate impact on eys
    gen eys_`value' = eys_base + (learning_poverty_`value' - learning_poverty_base) * `lp_coeff_eys'

    * Label those -value- specific vars (scenarios)
    label var learning_poverty_`value' "Share of learning poor if `value' school days are lost (%)"
    label var nonprof_`value'          "Share of students below minimum proficiency if `value' school days are lost"
    label var net_enrollment_`value'   "Share of kids 10-14 enrolled in school if `value' school days are lost"
    label var eys_`value'              "Expected Years of Schooling if `value' school days are lost"
    label var score_`value'            "Mean score if `value' schooldays are lost (%)"
  }

  * Aggregate average EYS for states and country
  levelsof statecode if geography == "state", local(states)
  foreach value in base `days_to_simulate' {

    * National number
    sum eys_`value' if geography == "county" [aw=population_1014], meanonly
    replace eys_`value' = `r(mean)' if geography == "country"

    * State numbers
    foreach state of local states {
    	sum eys_`value' if statecode == `state' & geography == "county" [aw=population_1014], meanonly
      replace eys_`value' = `r(mean)' if geography == "state" & statecode == `state'
    }
  }

  * Beautify
  local idvars "code idgrade threshold subject private"
  local traitvars "geography statecode uf countyname"
  local valuevars "score* nonprof* learning_poverty* net_enrollment* eys* enrolled_grade population_1014"
  order `idvars' `valuevars' `traitvars'
  keep `idvars' `valuevars' `traitvars'
  format score* nonprof* learning_poverty* net_enrollment* eys* %5.1f
  format nonprof* %5.2f


  *-----------------------------------------------------------------------------

  noi disp as txt "{phang}creating chloropleth maps of learning poverty and impacts{p_end}"

  * For maptile compatibility
  clonevar county_code = code

  * Baseline map
  maptile learning_poverty_base, geography(brazil_counties) stateoutline(medium) ///
         fcolor(BuRd) cutvalues(20 40 60 80) legdecimals(0) ///
         twopt(legend(subtitle("LP Baseline (%)"))) ///
         savegraph("`outputs'/LP_Brazil_covid_simulation_base.png") replace

  * For each scenario, the change in Learning poverty
  foreach value of local days_to_simulate {

    * LP change in percentage points
    gen lp_increase_`value' = learning_poverty_`value' - learning_poverty_base
    label var lp_increase_`value' "Learning Poverty increase if `value' school days are lost (pp)"

    * Map the intensity of the lp increase
    maptile lp_increase_`value', geography(brazil_counties) stateoutline(medium) ///
           fcolor(Reds) cutvalues(2 4 6 8) legdecimals(0) ///
           twopt(legend(subtitle("LP Change (pp)"))) ///
           savegraph("`outputs'/LP_Brazil_covid_simulation_change`value'.png") replace

    sum lp_increase_`value' if geography == "county", detail
    local lpi_median : di %2.1f `r(p50)'
    local note "Median = `lpi_median'"

    histogram lp_increase_`value' if geography == "county" & lp_increase_`value' <= 18, ///
              lcolor(black) fcolor(orange_red%60) scheme(s1color) ///
              xline(`r(p50)', lwidth(thick) lcolor(maroon)) ///
              xlabel(0(3)18) ylabel(0(.2).7) text(.5 `lpi_median' "`note'", place(e))
    graph export "`outputs'/LP_Brazil_covid_histogram_change`value'.png", replace

  }
   

  * Save DTA and export CSV
  compress
  save "`outputs'/LP_Brazil_covid_simulation.dta", replace
  export delimited "`outputs'/LP_Brazil_covid_simulation.csv", replace

  *-----------------------------------------------------------------------------
  * HOTSPOT ANALYSIS
  
  * Load hotspot ado
  do "${clone}/01_programs/Hotspot_ado/hotspot.ado
    
  * Importing centroids txt (hosted in Repo - was calculated in ArcGIS based on shapefile downloaded from IBGE)
  import delimited "${clone}/02_rawdata/IBGE_Shapefile/IBGE_counties_centroids.txt", encoding("utf-8") clear
  rename cd_geocmu code
  save "${clone}/02_rawdata/IBGE_Shapefile/IBGE_counties_centroids.dta", replace

  * Reopen covid dataset
  use "${clone}/04_outputs/LP_Brazil_covid_simulation.dta", clear

  * Merge centroid information
  merge m:1 code using "${clone}/02_rawdata/IBGE_Shapefile/IBGE_counties_centroids.dta", keep(match) nogen
  
  * Change LPV variable weighted based on the population
  gen wgt_change = (lp_increase_50) * population_1014/100

  putmata popw = population_1014, replace

  hotspot lp_increase_50 wgt_change, xcoord(x_cent) ycoord(y_cent) radius(500) nei(1)

  * Map the intensity of the lp increase
  foreach var in goS_lp_increase_50 goZ_lp_increase_50 goS_wgt_change goZ_wgt_change {
    maptile `var', geography(brazil_counties) stateoutline(medium) ///
          fcolor(Reds) twopt(legend(off)) ///
          savegraph("${clone}/04_outputs/HotSpot_change50_`var'.png") replace
  }
  *-----------------------------------------------------------------------------
  
  * HISTOGRAM IN EXCEL
  
  keep if geography == "county"
  keep code lp_increase_*
  reshape long lp_increase_, i(code) j(days)
  gen bin_lp_change = int(lp_increase_)
  collapse (count) code, by(bin_lp_change days)
  gen share_counties = code / 5523


  keep if geography == "county"
  keep code lp_increase_*
  reshape long lp_increase_, i(code) j(days)
  gen bin_lp_change = int(lp_increase_)
  foreach value of local days_to_simulate {
    gen int bin_`value' = int(lp_increase_`value')
  }
  collapse (count) code, by(bin_*)

  noi disp as res _newline "Done."

}

  /*-----------------------------------------------------------------------------

  * Opens brazilfull again to check national spells
  use "`cleandata'/brazilfull.dta", clear
  keep if geography == "country" & idgrade == 5 & threshold == "med" & subject == "read" & private == 9
  tset year
  twoway (tsline learning_poverty), xlabel(2011(2)2019) ylabel(,format(%9.0fc))

  -----------------------------------------------------------------------------*/
