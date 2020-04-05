*==============================================================================*
* TASK 012  Filter and collapse enrollment at the county level
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
  * Regions in Brazil (enrollment raw data files are split by region)
  local regions   "CO NORDESTE NORTE SUDESTE SUL"
  *
  * Paths for file manipulation in this program
  local enrollment_zip   "${clone}/02_rawdata/INEP_School_Census/Downloads"
  local enrollment_raw   "${clone}/02_rawdata/INEP_School_Census"
  local enrollment_clean "${clone}/03_cleandata"
  *-----------------------------------------------------------------------------


  *-----------------------------------------------------------------------------
  * Filter and collapses yearly School Census datasets (ZIP->RAW)
  *-----------------------------------------------------------------------------
  noi disp as txt _newline "Processing School Census enrollment datasets for each year (started at $S_TIME)..."

  * Loop through all designated years
  foreach yi of local someyears {

    * Confirm if the filtered and collapsed file already exist
    cap confirm file "`enrollment_raw'/INEP_School_Census_`yi'_by_age.dta"
    local no_age_file_exist   = (_rc == 601)
    cap confirm file "`enrollment_raw'/INEP_School_Census_`yi'_by_grade.dta"
    local no_grade_file_exist = (_rc == 601)

    * Continue if either file does not exist or overwrite files is set to one
    if (`no_age_file_exist') | (`no_grade_file_exist') | (`overwrite_files') {

      noi disp as txt "{phang}Collapsing enrollment from `yi'{p_end}"

      * Create empty files to append all regions (collapsed by age and by grade)
      touch "`enrollment_raw'/INEP_School_Census_`yi'_by_age.dta", replace
      touch "`enrollment_raw'/INEP_School_Census_`yi'_by_grade.dta", replace

      * Loop through all designated regions
      foreach region of local regions {

        noi disp as txt "{phang2}at the region `region'{p_end}"

        * Opens the raw, harmonized microdata from INEP School Census where:
        * - 1 observation = 1 student (no observation was ever deleted)
        * - variables names were harmonized (many variables were dropped)
        use "`enrollment_zip'/INEP_School_Census_`yi'_`region'_learner.dta", clear

        * Filters needed to replicate enrollment in INEP Anuario Estatistico
        keep if (idgrade >= 1 & idgrade <= 12) // Harmonized idgrade variable, based on idgrade_o (tp_etapa_ensino)
        keep if (in_regular == 1)              // Original variable: dummy for Ensino Regular (not EJA)
        keep if (in_especial_exclusiva != 1)   // Original variable: dummy for Ensino Regular (not Educao Especial Exclusiva)
        keep if	(tp_tipo_turma < 4)            // Original variable: factorial class, with 4 = complementary activity

        * Too many students have missing values for county of residence,
        * thus, extrapolate based on county of school
        replace county_house = county_school  if  missing(county_house)

        * Explicitly drops idclass, then drop duplicates to avoid double counting
        * a student when it is enrolled in more than one idclass
        drop idclass in_regular in_especial_exclusiva tp_tipo_turma
        duplicates drop

        * Only variables we care about
        keep year idlearner idgrade idschool private county_school county_house age behind_ideal_grade

        preserve

          * Generate collapsed enrollment for ages 10-14, by county of residence
          * this will be used to consolidate the enrollment per county
          keep if age >= 10 & age <= 14
          collapse (count) enrolled_1014 = idlearner (mean) private_1014 = private behind_ideal_grade_1014 = behind_ideal_grade, by(year county_house)
          * Append this region to a single file for the year
          append using "`enrollment_raw'/INEP_School_Census_`yi'_by_age.dta", nolabel
          save "`enrollment_raw'/INEP_School_Census_`yi'_by_age.dta", replace

        restore

        * Generate collapsed enrollment by grade (5 and 9 only), by county of school
        * this will be used as weights when combining proficiencies of counties
        keep if idgrade == 5 | idgrade == 9

        * Expand to have private =0 (public), =1 (private) and =9 (all)
        expand 2, gen(expanded)
        replace private = 9 if expanded

        collapse (count) enrolled_grade = idlearner (mean) behind_ideal_grade, by(year county_school private idgrade)
        * Append this region to a single file for the year
        append using "`enrollment_raw'/INEP_School_Census_`yi'_by_grade.dta", nolabel
        save "`enrollment_raw'/INEP_School_Census_`yi'_by_grade.dta", replace

      }
    }

    else {
      noi disp as txt "{phang}Step skipped: enrollment from INEP School Census `yi' already in clone.{p_end}"
    }

  }



  *-----------------------------------------------------------------------------
  * Append years and copy final file to cleandata (RAW->CLEAN)
  *-----------------------------------------------------------------------------
  noi disp as txt _newline "Appending multiple School Census enrollment datasets..."


  ***********************************
  ******  AGE 1014 Aggregation ******
  ***********************************
  noi disp as txt "{phang}Enrollment for ages 10-14{p_end}"

  * Prepare local of file to create
  local target_file "INEP_School_Census_enrollment_by_age.dta"

  * Create empty files to append all years (collapsed by age 1014)
  touch "`enrollment_clean'/`target_file'", replace

  foreach yi of local someyears {
    * File with # enrolled kids ages 10-14, regardless of grade (1-12), by HOUSE county
    use "`enrollment_raw'/INEP_School_Census_`yi'_by_age.dta", clear
    * File for appended years
    append using "`enrollment_clean'/`target_file'", nolabel
    save         "`enrollment_clean'/`target_file'", replace
  }

  * Because the collapse happened at the county_house for each region,
  * it happens that some kids enrolled in SUL have residence in SUDESTE
  * so we need to collapse again
  collapse (rawsum) enrolled_1014 (mean) private_1014 behind_ideal_grade_1014 [aw = enrolled_1014], by(year county_house)

  * Up to this point, the file has only county-level observations
  gen geography = "county"
  gen statecode = floor(county_house/100000)
  save "`enrollment_clean'/`target_file'", replace

  * Collpase by state
  collapse (rawsum) enrolled_1014 (mean) private_1014 behind_ideal_grade_1014 [aw=enrolled_1014], by(year statecode)
  gen geography = "state"
  append using "`enrollment_clean'/`target_file'", nolabel
  save         "`enrollment_clean'/`target_file'", replace

  * Collapse for the whole couuntry
  collapse (rawsum)  enrolled_1014 (mean) private_1014 behind_ideal_grade_1014 [aw=enrolled_1014] if geography == "county", by(year)
  gen geography = "country"
  append using "`enrollment_clean'/`target_file'", nolabel
  save         "`enrollment_clean'/`target_file'", replace

  * Fills up code at state and country level
  replace statecode = 0 if geography == "country"
  replace county_house = statecode if geography != "county"

  * Beautify this file
  replace   private_1014 = private_1014 * 100
  label var private_1014 "Share of kids aged 10-14 who are enrolled in private grades 1-12 (%)"
  replace   behind_ideal_grade_1014 = behind_ideal_grade_1014 * 100
  label var behind_ideal_grade_1014 "Share of kids aged 10-14 who are two or more years behind ideal grade (%)"
  label var enrolled_1014 "Number of enrolled students aged 10-14 (grades 1-12; private or public)"
  format enrolled* %10.0fc
  format behind_i* %5.1f

  compress
  isid year county_house
  save "`enrollment_clean'/`target_file'", replace



  ****************************************
  ******  GRADE 5 and 9 Aggregation ******
  ****************************************
  noi disp as txt "{phang}Enrollment for grades 5 and 9{p_end}"

  * Prepare local of file to create
  local target_file "INEP_School_Census_enrollment_by_grade.dta"

  * Create empty files to append all years (collapsed by grade 5 or 9)
  touch "`enrollment_clean'/`target_file'", replace

  foreach yi of local someyears {
    * File with # enrolled kids in grade 5 and 9, regardless of age, by SCHOOL county
    use "`enrollment_raw'/INEP_School_Census_`yi'_by_grade.dta", clear
    * File for appended years
    append using "`enrollment_clean'/`target_file'", nolabel
    save         "`enrollment_clean'/`target_file'", replace
  }

  * Up to this point, the file has only county-level observations
  gen geography = "county"
  gen statecode = floor(county_school/100000)
  save "`enrollment_clean'/`target_file'", replace

  * Collpase by state
  collapse (rawsum) enrolled_grade (mean) behind_ideal_grade [aw=enrolled_grade], by(year private idgrade statecode)
  gen geography = "state"
  append using "`enrollment_clean'/`target_file'", nolabel
  save         "`enrollment_clean'/`target_file'", replace

  * Collapse for the whole couuntry
  collapse (rawsum) enrolled_grade (mean) behind_ideal_grade [aw=enrolled_grade] if geography == "county", by(year private idgrade)
  gen geography = "country"
  append using "`enrollment_clean'/`target_file'", nolabel
  save         "`enrollment_clean'/`target_file'", replace

  * Fills up code at state and country level
  replace statecode = 0 if geography == "country"
  replace county_school = statecode if geography != "county"

  * Beautify this file
  replace   behind_ideal_grade = behind_ideal_grade * 100
  label var behind_ideal_grade "Share of kids in this grade who are two or more years behind ideal grade (%)"
  label var enrolled_grade "Number of enrolled students in this grade (regardless of age)"
  label var geography  "Level of aggregation (county | state | country)"
  label var private    "Public or private or both school types (0 | 1 | 9)"
  label var statecode  "State code (IBGE 2 digits)"
  order year geography county_school private idgrade enrolled_grade behind_ideal_grade
  format enrolled* %10.0fc
  format behind_i* %5.1f

  compress
  isid year county_school private idgrade
  save "`enrollment_clean'/`target_file'", replace


  noi disp as res _newline "Done processing enrollment (finished at $S_TIME)."


  * Tentativelly erase file already imported (no longer needed) to save space
  foreach yi of local someyears {
    foreach region of local regions {
      cap erase "`enrollment_zip'/INEP_School_Census_`yi'_`region'_learner.dta"
    }
  }

}
