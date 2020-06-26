*==============================================================================*
* TASK 016  Export some data for the technical paper and ppt
* Author:   Diana Goldemberg
*==============================================================================*
quietly {

  *-----------------------------------------------------------------------------
  * Execution parameters
  *-----------------------------------------------------------------------------
  * Paths for file manipulation in this program
  local cleandata   "${clone}/03_cleandata"
  local outputs     "${clone}/04_outputs"
  *-----------------------------------------------------------------------------


  noi disp as txt _newline "Exporting some CSV files..."


  * Open Brazilfull, which is the consolidated and ready to use dataset
  use "`cleandata'/brazilfull.dta", clear
  keep if idgrade   == 5
  keep if threshold == "med"
  keep if subject   == "read"
  * CHANGE HERE FOR PUBLIC ONLY (private ==1  or both private and public, private == 9)
  keep if private   == 9
  keep if inlist(year, 2013, 2017)

  * Variables we want to export
  local  vars_to_export "geography year code statecode uf idgrade threshold subject learning_poverty nonprof gap gap_squared score ntest testpart net_enrollment population_1014"
  order `vars_to_export'
  keep  `vars_to_export'

  * County only
  preserve
    keep if geography == "county"

    * Save county file in long format
    save  "`outputs'/LP_Brazil_by_county.dta", replace
    export delimited "`outputs'/LP_Brazil_by_county.csv", replace

    * Save county file in wide format, with the change between 2013-2017
    reshape wide learning_poverty nonprof gap gap_squared score ntest testpart net_enrollment population_1014, i(geography code statecode uf idgrade threshold subject) j(year)
    foreach var in learning_poverty nonprof gap gap_squared score ntest testpart net_enrollment population_1014 {
      gen `var'change = `var'2017 - `var'2013
    }
    save  "`outputs'/LP_Brazil_by_county_wide.dta", replace

  restore

  * State and Country (all but county)
  keep if geography != "county"
  replace uf = "BRA" if statecode == 0
  export delimited   "`outputs'/LP_Brazil_by_state.csv", replace


  * For the LP paper spreadsheet
  * Adjusting poverty measures for Out-of-School children
  * All OOS children are LP, thus they count as P0 = 1, P1 = 1, P2 = 1
  clonevar raw_p0_ = nonprof
  clonevar raw_p1_ = gap
  clonevar raw_p2_ = gap_squared
  gen adj_p0_ = raw_p0_ * net_enrollment/100 + 1*(1-net_enrollment/100)
  gen adj_p1_ = raw_p1_ * net_enrollment/100 + 1*(1-net_enrollment/100)
  gen adj_p2_ = raw_p2_ * net_enrollment/100 + 1*(1-net_enrollment/100)

  keep statecode uf year net_enrollment *_p?_
  reshape wide *_p?_ net_enrollment, i(statecode uf) j(year)
  order uf statecode adj_p0* adj_p1* adj_p2* net_enrollment* raw_p0* raw_p1* raw_p2*
  export delimited   "`outputs'/LP_Brazil_for_paper.csv", replace

  noi disp as res "Done preparing export data."

  ****

  * Creates the graphs for the Learning Poverty Working Paper
  use "`outputs'/LP_Brazil_by_county_wide.dta", clear

  * For maptile template compatibility
  clonevar county_code = code

  * Learning Poverty 2013 levels
  maptile learning_poverty2013, geography(brazil_counties) stateoutline(medium) ///
         fcolor(BuRd) cutvalues(20 40 60 80) legdecimals(0) ///
         twopt(legend(subtitle("LP 2013 (%)"))) ///
         savegraph("`outputs'/WP_LP_level_2013.png") replace

   * Learning Poverty 2017 levels
   maptile learning_poverty2017, geography(brazil_counties) stateoutline(medium) ///
          fcolor(BuRd) cutvalues(20 40 60 80) legdecimals(0) ///
          twopt(legend(subtitle("LP 2017 (%)"))) ///
          savegraph("`outputs'/WP_LP_level_2017.png") replace

   * Learning Poverty 2013-2017 change
   maptile learning_povertychange, geography(brazil_counties) stateoutline(medium) ///
          fcolor(BuRd) cutvalues(-20 -10 0 10 20) legdecimals(0) ///
          twopt(legend(subtitle("LP Change (pp)"))) ///
          savegraph("`outputs'/WP_LP_change_2013_2017.png") replace

}
