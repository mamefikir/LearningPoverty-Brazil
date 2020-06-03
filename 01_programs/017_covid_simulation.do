*==============================================================================*
* TASK 017  Simulation od Covid19 impacts on Learning Poverty
* Author:   Diana Goldemberg
*==============================================================================*
quietly {

  *-----------------------------------------------------------------------------
  * Execution parameters
  *-----------------------------------------------------------------------------
  local days_to_simulate "60 90 120"

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

  gen nonprof = (score < 200)  & !missing(score)
  foreach value of local days_to_simulate {
    gen score_`value' = score - `value' * gain_score
    gen nonprof_`value' = (score_`value' < 200)  & !missing(score_`value')
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
  import delimited "${clone}/02_rawdata/HCI_Brazil/hci_edu_brazil.csv", clear
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
    label var learning_poverty_`value' "Share of learning poor if `value' schooldays are lost (%)"
    label var nonprof_`value'          "Share of students below minimum proficiency if `value' schooldays are lost"
    label var net_enrollment_`value'   "Share of kids 10-14 enrolled in school if `value' schooldays are lost"
    label var eys_`value'              "Expected Years of Schooling if `value' schooldays are lost"
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

  * Save DTA and export CSV
  compress
  save "`outputs'/LP_Brazil_covid_simulation.dta", replace
  export delimited "`outputs'/LP_Brazil_covid_simulation.csv", replace

  *-----------------------------------------------------------------------------

  noi disp as txt "{phang}creating chloropleth maps of learning poverty and impacts{p_end}"

  * For maptile compatibility
  clonevar county_code = code

  * Baseline map
  maptile learning_poverty_base, geography(brazil_counties) stateoutline(medium) ///
         fcolor(BuRd) cutvalues(20 40 60 80) legdecimals(0) ///
         twopt(legend(subtitle("LP Baseline (%)"))) ///
         savegraph("`outputs'/LP_Brazil_covid_simulation_base.png") replace

  * For each scenario, the change in percentage points
  foreach value of local days_to_simulate {
    gen lp_increase_`value' = learning_poverty_`value' - learning_poverty_base
    maptile lp_increase_`value', geography(brazil_counties) stateoutline(medium) ///
           fcolor(Reds) cutvalues(5 10 15) legdecimals(0) ///
           twopt(legend(subtitle("LP Increase (pp)"))) ///
           savegraph("`outputs'/LP_Brazil_covid_simulation_change`value'.png") replace
  }

  noi disp as res _newline "Done."

}  

  /*-----------------------------------------------------------------------------

  * Opens brazilfull again to check national spells
  use "`cleandata'/brazilfull.dta", clear
  keep if geography == "country" & idgrade == 5 & threshold == "med" & subject == "read" & private == 9
  tset year
  twoway (tsline learning_poverty), xlabel(2011(2)2019) ylabel(,format(%9.0fc))

  -----------------------------------------------------------------------------*/

  noi disp as txt _newline "Distrubutional analysis"

  * Plot Kernel Densities of Learning Poverty and Mean Score [COUNTY LEVEL DATA]

  kdensity learning_poverty_base , addplot(kdensity learning_poverty_60  || kdensity learning_poverty_90 || kdensity learning_poverty_120)

  kdensity score_base , addplot(kdensity score_60 || kdensity score_90 || kdensity score_120) xline(200)


  * Decompose Change in Learning Poverty (mean and distribution) [REQUIRE STUDENT LEVEL DATA]

  use "${clone}/02_rawdata/INEP_SAEB/SAEB_ALUNO_COVID.dta", clear

  keep if include_student == 1
  rename (score nonprof) (score_base nonprof_base)

  reshape long score_ nonprof_, i(year id*) j(type_str) string

  encode type_str, gen(type)
  recode type 4=0 2=1 3=2 1=3

  gen varpl = 200

  drdecomp score_ [aw = learner_weight] if type==0 | type==1, by(type) varpl(varpl)
  drdecomp score_ [aw = learner_weight] if type==0 | type==2, by(type) varpl(varpl)
  drdecomp score_ [aw = learner_weight] if type==0 | type==3, by(type) varpl(varpl)

*-----------------------------------------------------------------------------
* Learning Poverty Simulation (distributionally neutral)

cap whereis github
if _rc == 0 global clone "`r(github)'/LearningPoverty-Brazil"

cap whereis myados
if _rc == 0 global myados "`r(myados)'"

cd "${myados}\groupdata\src"
discard


use "${clone}\02_rawdata\INEP_SAEB\SAEB_ALUNO_COVID.dta", clear

groupdata score [aw=learner_weight], z(200) benchmark group 

groupdata score [aw=learner_weight], z(200) mu(207.9) benchmark group 
  
*-----------------------------------------------------------------------------
* distribuion all years
  
	clear
	
	forvalues year=2011(2)2017 {
	  append using "${clone}/02_rawdata/INEP_SAEB/Downloads/SAEB_ALUNO_`year'.dta"
	}
	
	keep if in_situacao_censo == 1 & idgrade==5
	
	keep year id* private* score_lp learner_weight_lp
	 
	tw (kdensity score_lp [aw=learner_weight_lp] if year==2011) ///
		(kdensity score_lp [aw=learner_weight_lp] if year==2013) ///
		(kdensity score_lp [aw=learner_weight_lp] if year==2015) ///
		(kdensity score_lp [aw=learner_weight_lp] if year==2017, xline(200))

  /*-----------------------------------------------------------------------------

