*==============================================================================*
* TASK 015  Combine population, enrollment, proficiency into Learning Poverty
* Author:   Diana Goldemberg
*==============================================================================*
quietly {

  *-----------------------------------------------------------------------------
  * Execution parameters
  *-----------------------------------------------------------------------------
  * Path for file manipulation in this program
  local cleandata "${clone}/03_cleandata"
  *-----------------------------------------------------------------------------


  noi disp as txt _newline "Combining population, enrollment, proficiency into Learning Poverty"


  *-----------------------------------------------------------------------------
  * Merge all relevant data sources
  *-----------------------------------------------------------------------------

  * Start with population 10-14 per county
  use "`cleandata'/IBGE_population.dta", clear

  * Clone variable to be able to perform the merges
  clonevar county_house  = code
  clonevar county_school = code

  * Merge total enrollment of ages 10-14 per county (GRADES 1-12; PUBLIC & PRIVATE)
  merge 1:1 year county_house using "`cleandata'/INEP_School_Census_enrollment_by_age.dta", nogen

  * Calculate net enrollment rate
  gen       net_enrollment = 100 * enrolled_1014 / population_1014
  replace   net_enrollment = 100 if net_enrollment > 100

  * Merge proficiency for grades 5 & 9 per county (PUBLIC schools only!)
  * because for PRIVATE schools, participation in the NLA is optinal
  merge 1:m year code using "`cleandata'/INEP_SAEB_proficiency.dta", keep(master match) nogen
  * It's expected that some counties won't have proficiency info ( masked due to privacy concerns when ntest is too small)
  replace idgrade   = 0      if  missing(idgrade)
  replace subject   = "N.A." if  missing(subject)
  replace threshold = "N.A." if  missing(threshold)
  replace private   = 9      if  missing(private)

  * Merge enrollment for grades 5 & 9 PUBLIC only
  merge m:1 year county_school private idgrade using "`cleandata'/INEP_School_Census_enrollment_by_grade.dta", keep(master match) nogen

  * Enrollment and proficiency give SAEB participation
  gen     testpart = 100 * ntest / enrolled_grade
  replace testpart = 100    if !missing(testpart) & testpart > 100


  *-----------------------------------------------------------------------------
  * Calculates learning poverty, which is adjusted non-proficiency
  *-----------------------------------------------------------------------------
  gen learning_poverty = (nonprof * net_enrollment) + (100 - net_enrollment)

  *-----------------------------------------------------------------------------
  * Final touches
  *-----------------------------------------------------------------------------
  * Beautify this file
  label var year             "Year SAEB"
  label var idgrade          "Grade of assessed students (5 | 9)"
  label var testpart         "Share of enrolled students with assessment score (masked are missing) (%)"
  label var net_enrollment   "Share of kids 10-14 enrolled in schoo (grades 1-12, private or public)"
  label var learning_poverty "Share of learning poor (%)"
  format enrolled*  %9.0fc
  format testpart behind* net_enrollment learning_poverty* %5.1f

  local  vars2keep "year geography code statecode private idgrade threshold subject learning_poverty nonprof gap gap_squared net_enrollment score ntest testpart enrolled_grade population_1014 private_1014 behind_ideal_grade_1014 behind_ideal_grade countyname uf"
  keep  `vars2keep'
  order `vars2keep'

  * Compress, check, save
  compress
  isid year code private idgrade threshold subject
  save "`cleandata'/brazilfull.dta", replace

  * A quick check in number of observations
  tab year if geography == "county" & private == 9 & subject == "read" & idgrade == 5 & threshold == "med"
  noi disp as text "{phang}`=round(`r(N)'/`r(r)')' observations per year at the county level (given subject, idgrade, threshold, private){p_end}"

  noi disp as res "Created Learning Poverty dataset (brazilfull)"


}
