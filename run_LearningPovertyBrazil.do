*==============================================================================*
*! LEARNING POVERTY IN BRAZIL: replicating the WB indicator at subnational level
*! Project information at: https://github.com/dianagold/LearningPovertyBrazil
*! Author:  Diana Goldemberg
*
* About this project:
*   Replicates the World Bank indicator that combines schooling and learning
*   for Brazil at the county and state levels, for 2011, 2013, 2015 and 2017.
*==============================================================================*
quietly {


  *-----------------------------------------------------------------------------
  * General program setup
  *-----------------------------------------------------------------------------
  clear               all
  capture log         close _all
  set more            off
  set varabbrev       off, permanently
  set emptycells      drop
  set maxvar          10000
  version             15

  * Time-saving option is activated by default (that is, set to zero)
  * If 1, will always download the zip files, even if already exists in clone
  * and clean all the seed and raw data from scratch, overwritting any contents
  global overwrite_files = 0  // DO NOT COMMIT ANY CHANGES TO THIS LINE
  * NOTE: individual dofiles will have a local set from this global to ease change
  *-----------------------------------------------------------------------------


  *-----------------------------------------------------------------------------
  * Define user-dependant path for local clone repo
  *-----------------------------------------------------------------------------
  * Change here only if this master run do-file is renamed
  local master_run_do "run_LearningPovertyBrazil.do"

  * One of two options can be used to "know" the clone path for a given user
  * 1. the user had previously saved their GitHub location with -whereis-,
  *    so the clone is a subfolder with this Project Name in that location
  * 2. through a window dialog box where the user manually selects a file

  * Method 1 - Github location stored in -whereis-
  *---------------------------------------------
  capture whereis github
  if _rc == 0 global clone "`r(github)'/LearningPovertyBrazil"

  * Method 2 - clone selected manually
  *---------------------------------------------
  else {
    * Display an explanation plus warning to force the user to look at the dialog box
    noi disp as txt `"{phang}Your GitHub clone local could not be automatically identified by the command {it: whereis}, so you will be prompted to do it manually. To save time, you could install -whereis- with {it: ssc install whereis}, then store your GitHub location, for example {it: whereis github "C:/Users/AdaLovelace/Documents/GitHub"}.{p_end}"'
    noi disp as error _n `"{phang}Please use the dialog box to manually select the file `master_run_do' in your machine.{p_end}"'

    * Dialog box to select file manually
    capture window fopen path_and_master_run_do "Select the master do-file for this project (`master_run_do')" "Do Files (*.do)|*.do|All Files (*.*)|*.*" do

    * If user clicked cancel without selecting a file or chose a file that is not a do, will run into error later
    if _rc == 0 {

      * Pretend user chose what was expected in terms of string lenght to parse
      local user_chosen_do   = substr("$path_and_master_run_do",   - strlen("`master_run_do'"),          strlen("`master_run_do'") )
      local user_chosen_path = substr("$path_and_master_run_do", 1 , strlen("$path_and_master_run_do") - strlen("`master_run_do'") - 1 )

      * Replace backward slash with forward slash to avoid possible troubles
      local user_chosen_path = subinstr("`user_chosen_path'", "\", "/", .)

      * Check if master do-file chosen by the user is master_run_do as expected
      * If yes, attributes the path chosen by user to the clone, if not, exit
      if "`user_chosen_do'" == "`master_run_do'"  global clone "`user_chosen_path'"
      else {
        noi disp as error _newline "{phang}You selected $path_and_master_run_do as the master do file. This does not match what was expected (any path/`master_run_do') thus the code is aborted.{p_end}"
        error 2222
      }
    }
  }

  * Regardless of the method above, check clone
  *---------------------------------------------
  * Confirm that clone is indeed accessible by testing that master run is there
  cap confirm file "${clone}/`master_run_do'"
  if _rc != 0 {
    noi disp as error _n "{phang}Having issues accessing your local clone of the LearningPovertyBrazil repo. Please double check the clone location specified in the master run do-file and try again.{p_end}"
    error 2222
  }
  else {
    noi disp as result _n "{phang}LearningPovertyBrazil project profile sucessfully loaded.{p_end}"
  }
  *-----------------------------------------------------------------------------


  *-----------------------------------------------------------------------------
  * Other user-dependant choices
  *-----------------------------------------------------------------------------
  * In case the username is a WB login, will get raw files from WB network
  * because it will not be possible to download them on-the-fly (IT security)

  * Assumes by default that the user is not in the WB Network
  global wb_user = 0

  * Then checks if the username starts with wb or WB followed by 6 numbers
  local tentativelly_6_digits = real(substr("`c(username)'", 3, 6))
  if inlist(substr("`c(username)'", 1, 2), "wb", "WB", "Wb") & !missing(`tentativelly_6_digits') {

    * If yes, flag that this is a wb user and sets network drive address (same for any WB user)
    global    wb_user = 1
    global    network 	"//wbgfscifs01/GEDEDU/GDB/Projects/BRA_2020_LPV/internet"

    * Double check that network drive is available for this user (ie: has read permission)
    cap cd "${network}"
    if _rc != 0 noi disp as error _newline "{phang}WARNING! You may not be able to get the raw data needed for this project, neither from the WBNetwork nor the Web: please download the zip files manually from Dropbox.{p_end}"
  }
  *-----------------------------------------------------------------------------


  *-----------------------------------------------------------------------------
  * Download and install required user written ado's
  *-----------------------------------------------------------------------------
  * Fill this list will all user-written commands this project requires
  local user_commands touch mdesc spmap maptile drdecomp apoverty alorenz

  * Loop over all the commands to test if they are already installed, if not, then install
  foreach command of local user_commands {
    cap which `command'
    if _rc == 111 ssc install `command'
  }

  * Maptile template of Brazil counties, created for and stored in this repo
  maptile_install using "${clone}/02_rawdata/Maptile_Template/brazil_counties.zip", replace
  *-----------------------------------------------------------------------------


  *-----------------------------------------------------------------------------
  * Runs each required program in this repository
  *-----------------------------------------------------------------------------
  * TASK 011: Copy needed zips from Diana's Dropbox Public Folder or WB Network
  * PLACEHOLDER!!! Once I finish the EduBra repo, this will not be needed.
  * It will be substituted by downloading from INEP and harmomizing on-the-fly
  * (so far, the download from INEP and harmonization is only in Diana's PC)
  noi do "${clone}/01_programs/011_download_data.do"

  * TASK 012: Collapse enrollment to the county/state/country level
  noi do "${clone}/01_programs/012_enrollment.do"

  * TASK 013: Calculate proficiency and gaps at the county/state/country level
  noi do "${clone}/01_programs/013_proficiency.do"

  * TASK 014: Prepare population aged 10-14
  noi do "${clone}/01_programs/014_population.do"

  * TASK 015: Combine population, enrollment, proficiency into Learning Poverty
  noi do "${clone}/01_programs/015_brazilfull.do"

  * TASK 016: Export some data for paper and ppt
  noi do "${clone}/01_programs/016_export_data.do"
  
  * TASK 017: Simulate Covid-19 effects on Learning Poverty
  noi do "${clone}/01_programs/017_covid_simulation.do"
  *-----------------------------------------------------------------------------

}
