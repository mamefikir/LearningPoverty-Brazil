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

  *-----------------------------------------------------------------------------
  * HOTSPOT AND MAPTILE

  * Load hotspot ado
  do "${clone}/01_programs/Hotspot_ado/hotspot.ado

  * Importing centroids txt (hosted in Repo - was calculated in ArcGIS based on shapefile downloaded from IBGE)
  import delimited "${clone}/02_rawdata/IBGE_Shapefile/IBGE_counties_centroids.csv", encoding("utf-8") clear
  rename cd_geocmu code
  save "${clone}/02_rawdata/IBGE_Shapefile/IBGE_counties_centroids.dta", replace

  * Reopen the dataset we want to create graphs for
  use "`outputs'/LP_Brazil_by_county_wide.dta", clear

  * Merge centroid information
  merge m:1 code using "${clone}/02_rawdata/IBGE_Shapefile/IBGE_counties_centroids.dta", keep(match) nogen

  * Create population-weighted variables for HotSpot analysis
  gen learning_poverty2013_wgt   = learning_poverty2013/100   * population_10142013
  gen learning_poverty2017_wgt   = learning_poverty2017/100   * population_10142017
  gen learning_povertychange_wgt = learning_povertychange/100 * population_10142017

  * Performs hotspot for all the LP variables (3 unweighted and 3 weighted)
  hotspot learning_poverty*, xcoord(x_cent) ycoord(y_cent) radius(500) nei(1)

  * Hotspot creates 2 variables for each of them, with the prefix "goS_" and  "goZ_"

  * For maptile template compatibility
  clonevar county_code = code
  
  * All graphs we want to graph
  
  * Graph 1
  local varname1   "learning_poverty2013"
  local subtitle1  "LP 2013 (%)"
  local cosmetic1  "cutvalues(20 40 60 80) legdecimals(0)"
  local filename1  "WP_LP_reg_2013.png"

  * Graph 2
  local varname2   "learning_poverty2017"
  local subtitle2  "LP 2017 (%)"
  local cosmetic2  "cutvalues(20 40 60 80) legdecimals(0)"
  local filename2  "WP_LP_reg_2017.png"

  * Graph 3
  local varname3   "learning_povertychange"
  local subtitle3  "LP Change (pp)"
  local cosmetic3  "cutvalues(-20 -10 0 10 20) legdecimals(0)"
  local filename3  "WP_LP_reg_change.png"
  
  * Not sure which of the many Hotspot outputs to use - TODO check
  * I'm guessing goS is the standardized of goZ
  
  * Graph 4
  local varname4   "goS_learning_poverty2017"
  local subtitle4  "HotSpot 2017"
  local filename4  "WP_LP_hs_2017_nowgt.png"

  * Graph 5
  local varname5   "goS_learning_poverty2017_wgt"
  local subtitle5  "HotSpot 2017"
  local filename5  "WP_LP_hs_2017_weighted.png"

  * Graph 6
  local varname6   "goS_learning_povertychange"
  local subtitle6  "HotSpot Change"
  local filename6  "WP_LP_hs_change_nowgt.png"

  * Graph 7
  local varname7   "goS_learning_povertychange_wgt"
  local subtitle7  "HotSpot Change"
  local filename7  "WP_LP_hs_change_weighted.png"

  * Map all related Learning Poverty values by county
  forvalues i=1/7 {
    maptile `varname`i'', geography(brazil_counties) stateoutline(medium) ///
          fcolor(BuRd) `cosmetic`i'' ///
          twopt(legend(subtitle(`subtitle`i''))) ///
          savegraph("${clone}/04_outputs/`filename`i''") replace
  }
  *-----------------------------------------------------------------------------





}
