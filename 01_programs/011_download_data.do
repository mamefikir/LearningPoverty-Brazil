*==============================================================================*
* TASK 011  Download needed zips from Diana's Dropbox Public Folder to clone
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

  * For each zip file to download, sets locals (path, file, link, size)
  * all the links point to Diana's Public Dropbox folder, where those zips live.
  * If adding a new link, remember to change the ending from <dl=0> to <dl=1>
  * Information about file size is just a courtesy warning to impatient users

  **************************
  ******  POPULATION  ******
  **************************
  local file_1 "IBGE_Population_Estimates.zip"
  local path_1 "${clone}/02_rawdata/IBGE_Population/Downloads"
  local link_1 "https://www.dropbox.com/s/p63to32xb3kck2y/IBGE_Population_Estimates.zip?dl=1"
  local size_1 "2 Mb"

  ***************************
  ******  PROFICIENCY  ******
  ***************************
  local file_2 "INEP_SAEB.zip"
  local path_2 "${clone}/02_rawdata/INEP_SAEB/Downloads"
  local link_2 "https://www.dropbox.com/s/5sqvjghxsc8ef1t/INEP_SAEB.zip?dl=1"
  local size_2 "219 Mb"

  **************************
  ******  ENROLLMENT  ******
  **************************
  local file_3 "INEP_School_Census_2011_learner.zip"
  local path_3 "${clone}/02_rawdata/INEP_School_Census/Downloads"
  local link_3 "https://www.dropbox.com/s/tzwo6o8ft6zuapd/INEP_School_Census_2011_learner.zip?dl=1"
  local size_3 "425 Mb"

  local file_4 "INEP_School_Census_2013_learner.zip"
  local path_4 "${clone}/02_rawdata/INEP_School_Census/Downloads"
  local link_4 "https://www.dropbox.com/s/elz3rhyor5q86x4/INEP_School_Census_2013_learner.zip?dl=1"
  local size_4 "426 Mb"

  local file_5 "INEP_School_Census_2015_learner.zip"
  local path_5 "${clone}/02_rawdata/INEP_School_Census/Downloads"
  local link_5 "https://www.dropbox.com/s/zxk71flreke9bis/INEP_School_Census_2015_learner.zip?dl=1"
  local size_5 "424 Mb"

  local file_6 "INEP_School_Census_2017_learner.zip"
  local path_6 "${clone}/02_rawdata/INEP_School_Census/Downloads"
  local link_6 "https://www.dropbox.com/s/i3ojg95ndxqgl5g/INEP_School_Census_2017_learner.zip?dl=1"
  local size_6 "415 Mb"
  *-----------------------------------------------------------------------------


  *-----------------------------------------------------------------------------
  * Download all required seed files in clone
  *-----------------------------------------------------------------------------
  noi disp as txt _newline "Downloading rawdata files (started at $S_TIME)..."

  * Loop through all the files that should be downlaoded
  forvalues i = 1(1)6 {

    * Confirm if the zip file was already downloaded
    cap confirm file "`path_`i''/`file_`i''"

    * Continue if the zip file does not exist or overwrite_files is set to one
    if (_rc == 601) | (`overwrite_files') {

      noi disp as txt "{phang}Working on `file_`i'' - this file size is `size_`i''...{p_end}"

      * Copy the file to the clone, either from Network (if wb user) or Dropbox
      if $wb_user  copy "${network}/`file_`i''"  "`path_`i''/`file_`i''", replace
      else         copy "`link_`i''"             "`path_`i''/`file_`i''", replace

    }

    * Skip the file if it already existed and overwrite_files is not one
    else {
      noi disp as txt "{phang}Skipped `file_`i'' (already found in clone){p_end}"
    }
  }

  *-----------------------------------------------------------------------------
  * Unzip all required seed files in clone
  *-----------------------------------------------------------------------------
  noi disp as txt _newline "Unzipping rawdata files (started at $S_TIME)..."

  * Loop through all the files that should be downlaoded
  forvalues i = 1(1)6 {

    noi disp as txt "{phang}Working on `file_`i'' - this file size is `size_`i''...{p_end}"

    * Unzip the contents into clone path
    cd "`path_`i''"
    unzipfile "`file_`i''", replace

  }

  noi disp as res _newline "Done processing all rawdata files (finished at $S_TIME)."

}
