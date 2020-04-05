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

  preserve
    keep if geography == "county"
    save  "`outputs'/LP_Brazil_by_county.dta", replace
    export delimited "`outputs'/LP_Brazil_by_county.csv", replace
  restore

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



  ***** MAPTILE ****   **** move to a better place ****
  foreach command in maptile spmap {
    cap which `command'
    if _rc == 111  ssc install `command'
  }
  maptile_install using "${clone}/02_rawdata/Maptile_Template/brazil_counties.zip", replace

  cd "${clone}"

  use "`outputs'/LP_Brazil_by_county.dta", clear
  clonevar county_code = code
  keep if year == 2017

  maptile learning_poverty, geography(brazil_counties) stateoutline(medium) ///
         fcolor(BuRd) cutvalues(20 40 60 80) legdecimals(1) ///
         twopt(legend(subtitle("Learning Poverty")))

}
