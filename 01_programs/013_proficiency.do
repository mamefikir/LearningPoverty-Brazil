*==============================================================================*
* TASK 013  Calculate proficiency and gaps at the county level
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

  * Paths for file manipulation in this program
  local proficiency_zip   "${clone}/02_rawdata/INEP_SAEB/Downloads"
  local proficiency_raw   "${clone}/02_rawdata/INEP_SAEB"
  local proficiency_clean "${clone}/03_cleandata"
  *-----------------------------------------------------------------------------

  * Thresholds CSV is hosted (editable) in the Repo
  * Original thresholds LP5(150|200|250); LP9(200|275|325); MT5(175|225|275); MT9(225|300|350)
  * Original source: https://academia.qedu.org.br/prova-brasil/aprendizado-adequado/
  import delimited "${clone}/00_documentation/SAEB_thresholds.csv", varnames(1) encoding("utf-8") clear
  label var threshold_low "Low threshold"
  label var threshold_med "Medium threshold"
  label var threshold_adv "Advanced threshold"
  save "`proficiency_raw'/SAEB_thresholds.dta", replace

  *-----------------------------------------------------------------------------
  * Bring thresholds, calculate gaps and collapse yearly Prova Brasil (ZIP->RAW)
  *-----------------------------------------------------------------------------
  noi disp as txt _newline "Processing Prova Brasil proficiency datasets for each year (started at $S_TIME)..."

  * Loop through all designated years
  foreach yi of local someyears {

    * Confirm if the collapsed file already exist
    cap confirm file "`proficiency_raw'/SAEB_collapsed_`yi'.dta"

    * Continue if either file does not exist or overwrite files is set to one
    if (_rc == 601) | (`overwrite_files') {

      noi disp as txt "{phang}Collapsing proficiency from `yi'{p_end}"

      * Open the raw, harmonized microdata from INEP SAEB/PB where:
      * - 1 observation = 1 student (no observation was ever deleted)
      * - variables names were harmonized (many variables were dropped)
      use "`proficiency_zip'/SAEB_ALUNO_`yi'.dta"

      * The proficiency file is wide in subject, pass to long in subject
      reshape long score_ learner_weight_, i(year idlearner) j(subject) string
      rename  (score_ learner_weight_) (score learner_weight)

      * Brings in thresholds from the csv, already imported
      merge m:1 idgrade subject using "`proficiency_raw'/SAEB_thresholds.dta", nogen

      * Measures of learning poverty: headcount (P0), gap (P1), gapsquared(P2)
      foreach threshold in low med adv {
        foreach measure in p0 p1 p2 {
          * Empty variable as a placeholder
          gen `measure'_`threshold' = .
          label var `measure'_`threshold' "Poverty measure `measure' using `threshold' threshold"
        }
        * Actual calculation of each learning poverty measure
        replace p0_`threshold' = 0 if score >= threshold_`threshold' & !missing(score)
        replace p0_`threshold' = 1 if score <  threshold_`threshold' & !missing(score)
        replace p1_`threshold' = 0                                                       if p0_`threshold' == 0
        replace p1_`threshold' = (threshold_`threshold' - score) / threshold_`threshold' if p0_`threshold' == 1
        replace p2_`threshold' = 0                                                       if p0_`threshold' == 0
        replace p2_`threshold' = p1_`threshold' * p1_`threshold'                         if p0_`threshold' == 1
      }

      * Reshape long in thresholds (currently wide)
      reshape long p0_ p1_ p2_, i(year idlearner subject) j(threshold) string
      rename (p0_ p1_ p2_) (nonprof  gap  gap_squared)

      * To replicate the aggregated data released by INEP, should filter this
      gen byte include_student = (in_situacao_censo==1)
      replace  include_student = 1 if missing(in_situacao_censo)

      * Expand to have private =0 (public), =1 (private) and =9 (all)
      expand 2, gen(expanded)
      replace private = 9 if expanded

      * Collapse this dataset 3 times, one for each aggregation level
      foreach geography in county state country {
        preserve

          noi disp as txt "{phang2}at the `geography' level{p_end}"

          * Auxiliary variable for the collapse of country
          gen idcountry = 0

          collapse (mean) score nonprof  gap  gap_squared                 ///
                 (semean) se_score = score  se_nonprof     = nonprof      ///
                          se_gap   = gap    se_gap_squared = gap_squared  ///
                  (count) ntest = score  if  include_student [aw = learner_weight], ///
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
      order year geography code private idgrade subject threshold *score *nonprof *gap *gap_squared *ntest

      * Compress, check, save
      compress
      isid year geography code private idgrade subject threshold
      save "`proficiency_raw'/SAEB_collapsed_`yi'.dta", replace
    }

    else {
      noi disp as txt "{phang}Step skipped: collapsed proficiency from INEP SAEB `yi' already in clone.{p_end}"
    }

  }



  *-----------------------------------------------------------------------------
  * Append years and copy final file to cleandata (RAW->CLEAN)
  *-----------------------------------------------------------------------------
  noi disp as txt _newline "Appending multiple proficiency from INEP SAEB datasets..."

  * Prepare local with the file this step will create
  local target_file "INEP_SAEB_proficiency.dta"

  * Create empty files to append all years (collapsed by age 1014)
  touch "`proficiency_clean'/`target_file'", replace

  foreach yi of local someyears {
    * File with enrollment in the year already collapsed
    use "`proficiency_raw'/SAEB_collapsed_`yi'.dta", clear
    * File for appended years
    append using "`proficiency_clean'/`target_file'", nolabel
    save         "`proficiency_clean'/`target_file'", replace
  }

  * Beautify this file
  replace subject = "read" if subject == "lp"
  replace subject = "math" if subject == "mt"
  label var year       "INEP SAEB Assessment Year"
  label var code       "County code (IBGE 7 digits)"
  label var geography  "Level of aggregation (county | state | country)"
  label var private    "Public or private or both school types (0 | 1 | 9)"
  label var subject    "Subject (read | math)"
  label var threshold  "Threshold used (low | med | adv)"
  label var ntest      "Number of students assessed"
  label var score      "Mean score"
  label var se_score   "S.E. mean score"
  label var nonprof    "Share of students below minimum proficiency (P0)"
  label var se_nonprof "S.E. below minimum proficiency (P0)"
  label var gap        "Average proficiency gap (P1)"
  label var se_gap     "S.E. proficiency gap (P1)"
  label var gap_squared     "Average proficiency gap squared (P2)"
  label var se_gap_squared  "S.E. proficiency gap squared (P2)"
  format ntest %9.0fc
  format *score %5.1f
  format *nonprof*  *gap  *gap_squared  %5.3f
  order year geography code private idgrade subject threshold *score *nonprof *gap *gap_squared *ntest

  * Compress, check, save
  compress
  isid year geography code private idgrade subject threshold
  save "`proficiency_clean'/`target_file'", replace


  noi disp as res _newline "Done processing proficiency (finished at $S_TIME)."


  * Tentativelly erase files no longer needed to save space
  foreach yi of local someyears {
    if `yi'!= 2017 cap erase "`proficiency_zip'/SAEB_ALUNO_`yi'.dta"
  }
  foreach geography in county state country {
    cap erase "`proficiency_raw'/SAEB_collapsed_`geography'.dta"
  }

}