*==============================================================================*
* TASK 014  Collapse population 1014 at the county level (IBGE)
* Author:   Diana Goldemberg
*==============================================================================*
quietly {

  *-----------------------------------------------------------------------------
  * Execution parameters
  *-----------------------------------------------------------------------------
  * Time-saving option is taken from master run by default (where it's set to zero)
  * If 1, will always download the zip files, even if already exists in clone
  * and unzips again, overwritting any contents
  local overwrite_files = $overwrite_files // DO NOT COMMIT ANY CHANGES TO THIS LINE

  * Years for which the loop will run
  local someyears "2011 2013 2015 2017"
  *
  * Paths for file manipulation in this program
  local population_zip   "${clone}/02_rawdata/IBGE_Population/Downloads"
  local population_raw   "${clone}/02_rawdata/IBGE_Population"
  local population_clean "${clone}/03_cleandata"
  *-----------------------------------------------------------------------------

  noi disp as txt _newline "Processing IBGE Population by county..."

  *-----------------------------------------------------------------------------
  * Total population by county (IBGE ESTIMATIVAS DE POPULACAO)
  * Source: https://www.ibge.gov.br/estatisticas/sociais/populacao/9103-estimativas-de-populacao.html
  * The zip files from 011 have an additional spreadsheet to files available at the IBGE website,
  * one that was manually created and called "import_ready"
  *-----------------------------------------------------------------------------

  * Prepare local of file to create
  local target_file "IBGE_population_total.dta"

  * Confirm if the file in this step already exist
  cap confirm file "`population_raw'/`target_file'"

  * Continue if either file does not exist or overwrite files is set to one
  if (_rc == 601) | (`overwrite_files') {

    noi disp as txt "{phang}Total population by county (IBGE Estimativas Populacionais){p_end}"

    * Create empty files to append all years
    touch "`population_raw'/`target_file'", replace

    foreach yi of local someyears {
      * Worksheet which was manually prepared in Excel to be Stata ready
      import excel "`population_zip'/IBGE_`yi'_UF_Municipio.xls", sheet("import_ready") firstrow clear
      * County names change slightly across years, so we drop it
      drop name
      * File for appended years
      append using "`population_raw'/`target_file'", nolabel
      save         "`population_raw'/`target_file'", replace
    }

    * Now we recover the most recent county name (2017) and merge to appended years
    import excel "`population_zip'/IBGE_2017_UF_Municipio.xls", sheet("import_ready") firstrow clear
    keep   name code
    rename name countyname
    merge 1:m code using "`population_raw'/`target_file'", nogen

    * Beautify the resulting file
    format population %12.0fc
    label var population "Population (all ages)"
    order year geography code statecode uf countyname population
    sort  year geography code

    * Compress, check, save
    compress
    isid year code
    save "`population_raw'/`target_file'", replace
  }

  else {
    noi disp as txt "{phang}Step skipped: `target_file' already in clone.{p_end}"
  }


  *-----------------------------------------------------------------------------
  * Share of population aged 10-14 years, only at STATE level
  * (IBGE PROJECOES POPULACIONAIS) **** PLACEHOLDER, FIND THE EXACT ORIGINAL LINK
  *-----------------------------------------------------------------------------

  * Prepare local of file to create
  local target_file "IBGE_population_1014.dta"

  * Confirm if the file in this step already exist
  cap confirm file "`population_raw'/`target_file'"

  * Continue if either file does not exist or overwrite files is set to one
  if (_rc == 601) | (`overwrite_files') {

    noi disp as txt "{phang}Population 10-14 by state (IBGE Projecoes Populacionais){p_end}"

    * Worksheet which was manually prepared in Excel to be Stata ready
    import excel "`population_zip'/IBGE_Population_UF_by_Age.xls", sheet("import_ready") cellrange(A3:J31)  firstrow clear

    * The excel had total population and population at the age group
    * so we calculate the share in 10-14 years of age, by State
    forvalues yi = 2011(2)2017 {
      gen float share_1014`yi' = pop_1014`yi' / pop_total`yi'
    }
    drop pop_total* pop_1014*

    * Prepare to merge with our other file
    reshape long share_1014, i(statecode uf) j(year)

    * Beautify the resulting file
    format    share_1014 %5.3g
    label var share_1014 "Share of population aged 10-14 years old (IBGE Projecoes Populacionais)"

    * Compress, check, save
    compress
    isid year statecode
    save "`population_raw'/`target_file'", replace
  }

  else {
    noi disp as txt "{phang}Step skipped: `target_file' already in clone.{p_end}"
  }


  *-----------------------------------------------------------------------------
  * Combine both population files (total by county / age group by state)
  *-----------------------------------------------------------------------------
  use "`population_raw'/IBGE_population_total.dta", clear
  merge m:1 statecode year using "`population_raw'/IBGE_population_1014.dta", nogen

  * Extrapolate for all counties the same share of youth as its corresponding state
  gen population_1014 = population * share_1014

  * Beautify the resulting file
  format population_1014 %12.0fc
  label var population_1014 "Population aged 10-14 (IBGE Estimativas e Projecoes Populacionais)"
  label var geography  "Level of aggregation (county | state | country)"
  label var statecode  "State code (IBGE 2 digits)"
  label var uf         "State code (IBGE 2 letters)"
  label var code       "County code (IBGE 7 digits)"
  label var countyname "County name (as of 2017)"
  label var year       "Year of Population Estimates"

  * Compress, check, save
  compress
  isid year code
  save "`population_clean'/IBGE_population.dta", replace


  noi disp as res _newline "Done processing population."


  * Tentativelly erase files no longer needed to save space
  cap erase "`population_zip'/IBGE_Population_UF_by_Age.xls"
  forvalues yi = 2011(2)2017 {
    cap erase "`population_zip'/IBGE_`yi'_UF_Municipio.xls"
  }

}
