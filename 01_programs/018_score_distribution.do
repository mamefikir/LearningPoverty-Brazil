*==============================================================================*
* TASK 018  Plot, compare and analyze score microdata across years
*==============================================================================*
quietly {

  *-----------------------------------------------------------------------------
  * Execution parameters
  *-----------------------------------------------------------------------------
  * Choose between "lp" (reading) or "mt" (math)
  local subject   "lp"
  * Choose between "low" "med" and "adv"
  local threshold "med"

  * Paths for file manipulation in this program
  local proficiency_raw   "${clone}/02_rawdata/INEP_SAEB"
  *-----------------------------------------------------------------------------

  noi disp as txt _newline "Appending all the microdata (2011/13/15/17)..."



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

  /*-----------------------------------------------------------------------------

  * Generate data to put in Povcalnet Engine (20 points)
  * http://iresearch.worldbank.org/PovcalNet/PovCalculator.aspx

  keep if type == 0

  sum score_ [aw = learner_weight]

  alorenz score_ [aw = learner_weight] , points(20) fullview

  apoverty score_ [aw = learner_weight] , line(200)

  * Beta Lorenz is a superior approximation to the Microdata
  ** Microdata: 42.819
  ** Headcount(HC): 41.2164 (General Quadratic Lorenz curve)
  ** Headcount(HC): 42.136 (Beta Lorenz curve)

  /*
  Type 5
		2.81	118.24
		3.28	137.94
		3.57	150.26
		3.81	160.41
		4.03	169.41
		4.22	177.66
		4.41	185.33
		4.58	192.54
		4.74	199.55
		4.91	206.42
		5.07	213.13
		5.23	219.89
		5.39	226.83
		5.56	233.95
		5.74	241.41
		5.93	249.51
		6.15	258.64
		6.41	269.5
		6.76	284.26
		7.41	311.93
  */


  /*-----------------------------------------------------------------------------

  * A chunck of half-baked code that was crashing 017 and has been moved here

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
