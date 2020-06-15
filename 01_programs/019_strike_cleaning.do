*==============================================================================*
* TASK 019  Clean DIEESE strike data and prepare for merge with brazilfull.dta
* Author:   Guillermo Tovar
*==============================================================================*

  quietly {
      
	  
	  
  *-----------------------------------------------------------------------------
    * Execution parameters
  
  *-----------------------------------------------------------------------------
  *
  * Paths for file manipulation in this program
  local strike_raw   "${clone}/02_rawdata/Dieese_Strikes"
  local strike_clean "${clone}/03_cleandata"
  *-----------------------------------------------------------------------------

  noi disp as txt _newline "Processing DIEESE strike data by county..."

  *-----------------------------------------------------------------------------
  * Prepare codekey from fullbrazil.dta
  *-----------------------------------------------------------------------------  
  use "`strike_clean'\brazilfull.dta", clear
  keep code countyname uf geography

  *Some names from cities repeat between states, create unique identifier for merge
  gen geo_location= countyname + "/" + uf

  *Prepare statewide identifier for merging
  replace geo_location=uf if geography=="state"
  collapse (first)code geography, by (geo_location)
  tempfile codecountylist
  save "`codecountylist'"
  
  *-----------------------------------------------------------------------------
  * Prepare DIEESE strikes dataset for merge 
  *----------------------------------------------------------------------------- 

 *Use DIEESE strike data and prepare for merge
  import delimited  "`strike_raw'\Dieese_education_strikes_1990_2019.csv", encoding(UTF-8) clear
  rename localizacao_geografica geo_location
  recast str113 geo_location, force //In the future calculate max string and replace (maybe larger than 113 for new data?)

  *correction for cities that didn't merge because of spelling
  replace geo_location="Amambai/MS" if geo_location=="Amambaí/MS"
  replace geo_location="Belém do São Francisco/PE" if geo_location=="Belém de São Francisco/PE"
  replace geo_location="Graccho Cardoso/SE" if geo_location=="Gracho Cardoso/SE"
  replace geo_location="Itapajé/CE" if geo_location=="Itapagé/CE"
  replace geo_location="Eldorado do Carajás/PA" if geo_location=="Eldorado dos Carajás/PA"
  *Doubt about Presidente Juscelino, is it from MG or MA? Definitely not RN as in strike data?
  replace geo_location="Presidente Juscelino/MG" if geo_location=="Presidente Juscelino/RN"
  
  *-----------------------------------------------------------------------------
  * Merge DIEESE strike dataset with codekey for counties and states. 
  *----------------------------------------------------------------------------- 

  merge m:1 geo_location using "`codecountylist'"
  drop if _merge==2
  replace geography="Nationwide" if geo_location=="NACIONAL"

  *-----------------------------------------------------------------------------
  * Additional cleaning: dummy variables, label variables and renames
  *-----------------------------------------------------------------------------
  
  *Additional cleaning: type of protest, turn into dummies

  gen type_propositive=0
  gen type_defensive=0
  gen type_protest=0
  replace type_propositive=1 if carater1=="propositiva"
  replace type_defensive=1 if carater2=="defensiva"
  replace type_protest=1 if carater3=="protesto"
  drop carater*

  *Additional cleaning: alvo_esfera is non-exclusive, turn into dummies.

  gen power_municipal=0
  gen power_state=0
  gen power_federal=0
  replace power_municipal=1 if alvo_esfera=="poder executivo/municipal"
  replace power_state=1 if alvo_esfera=="poder executivo/estadual"
  replace power_federal=1 if alvo_esfera=="poder executivo/federal"
  replace power_state=1 if alvo_esfera=="poder executivo/estadual, poder executivo/municipal"
  replace power_municipal=1 if alvo_esfera=="poder executivo/estadual, poder executivo/municipal"
  replace power_municipal=1 if alvo_esfera=="poder executivo/federal, poder executivo/estadual, poder executivo/municipal"
  replace power_federal=1 if alvo_esfera=="poder executivo/federal, poder executivo/estadual, poder executivo/municipal"
  replace power_state=1 if alvo_esfera=="poder executivo/federal, poder executivo/estadual, poder executivo/municipal"
  replace power_federal=1 if alvo_esfera=="poder executivo/federal, poder executivo/estadual"
  replace power_municipal=1 if alvo_esfera=="poder executivo/federal, poder executivo/estadual"
  drop alvo_esfera

  *Additional cleaning: categoria_profissional is non-exclusive, turn into dummies.
  gen professional_aux_state=0
  replace  professional_aux_state=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual"
  replace  professional_aux_state=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual "
  replace professional_aux_state=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Professores Rede Estadual"
  replace professional_aux_state=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Municipal"
  replace professional_aux_state=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Municipal, Professores Rede Estadual, Professores Rede Municipal"
  replace professional_aux_state=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Federal, Auxiliares de Administração Escolar Rede Municipal, Professores Rede Estadual, Professores Rede Federal, Professores Rede Municipal"

  gen professional_aux_state_sup=0
  replace  professional_aux_state_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual Ensino Superior"
  replace professional_aux_state_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual Ensino Superior, Auxiliares de Administração Escolar Rede Estadual Ensino Técnico-Profissional, Professores Rede Estadual Ensino Superior, Professores Rede Estadual Ensino Técnico-Profissional"
  replace professional_aux_state_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual Ensino Superior, Professores Rede Estadual Ensino Superior"
  replace professional_aux_state_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual Ensino Superior, Professores Rede Estadual Ensino Superior"


  gen professional_aux_state_TP=0
  replace  professional_aux_state_TP=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual Ensino Técnico-Profissional"
  replace professional_aux_state_TP=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual Ensino Superior, Auxiliares de Administração Escolar Rede Estadual Ensino Técnico-Profissional, Professores Rede Estadual Ensino Superior, Professores Rede Estadual Ensino Técnico-Profissional"

  gen professional_aux_federal=0
  replace  professional_aux_federal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Federal"
  replace professional_aux_federal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Federal, Professores Rede Federal"
  replace professional_aux_federal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Federal, Auxiliares de Administração Escolar Rede Municipal, Professores Rede Estadual, Professores Rede Federal, Professores Rede Municipal"

  gen professional_aux_federal_sup=0
  replace  professional_aux_federal_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Federal Ensino Superior"
  replace professional_aux_federal_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Federal Ensino Superior, Professores Rede Federal Ensino Superior"
  replace professional_aux_federal_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Federal Ensino Superior, Auxiliares de Administração Escolar Rede Federal Ensino Técnico-Profissional"

  gen professional_aux_federal_TP=0
  replace professional_aux_federal_TP=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Federal Ensino Técnico-Profissional"
  replace professional_aux_federal_TP=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Federal Ensino Técnico-Profissional, Professores Rede Federal Ensino Técnico-Profissional"
  replace professional_aux_federal_TP=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede 	Federal Ensino Superior, Auxiliares de Administração Escolar Rede Federal Ensino Técnico-Profissional"

  gen professional_aux_municipal=0
  replace  professional_aux_municipal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Municipal"
  replace  professional_aux_municipal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Municipal "
  replace professional_aux_municipal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Municipal, Professores Rede Municipal"
  replace professional_aux_municipal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Municipal"
  replace professional_aux_municipal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Municipal, Professores Rede Estadual, Professores Rede Municipal"
  replace professional_aux_municipal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Federal, Auxiliares de Administração Escolar Rede Municipal, Professores Rede Estadual, Professores Rede Federal, Professores Rede Municipal"

  gen professional_prof_state=0
  replace  professional_prof_state=1 if categoria_profissional=="Professores Rede Estadual"
  replace professional_prof_state=1 if categoria_profissional=="Professores Rede Estadual, Professores Rede Municipal"
  replace professional_prof_state=1 if categoria_profissional=="Professores Rede Estadual, Professores Rede Federal, Professores Rede Municipal"
  replace professional_prof_state=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Professores Rede Estadual"
  replace professional_prof_state=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Municipal, Professores Rede Estadual, Professores Rede Municipal"
  replace professional_prof_state=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Federal, Auxiliares de Administração Escolar Rede Municipal, Professores Rede Estadual, Professores Rede Federal, Professores Rede Municipal"

  gen professional_prof_state_sup=0
  replace  professional_prof_state_sup=1 if categoria_profissional=="Professores Rede Estadual Ensino Superior"
  replace professional_prof_state_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual Ensino Superior, Auxiliares de Administração Escolar Rede Estadual Ensino Técnico-Profissional, Professores Rede Estadual Ensino Superior, Professores Rede Estadual Ensino Técnico-Profissional"
  replace professional_prof_state_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual Ensino Superior, Professores Rede Estadual Ensino Superior"
  replace professional_prof_state_sup=1 if categoria_profissional=="Professores Rede Federal Ensino Superior, Professores Rede Federal Ensino Técnico-Profissional"
  replace professional_prof_state_sup=1 if categoria_profissional=="Professores Rede Estadual Ensino Superior, Professores Rede Federal Ensino Superior"
  replace professional_prof_state_sup=1 if categoria_profissional=="Professores Rede Estadual Ensino Superior, Professores Rede Estadual Ensino Técnico-Profissional"
  replace professional_prof_state_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual Ensino Superior, Professores Rede Estadual Ensino Superior"

  gen professional_prof_state_TP=0
  replace  professional_prof_state_TP=1 if categoria_profissional=="Professores Rede Estadual Ensino Técnico-Profissional"
  replace professional_prof_state_TP=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual Ensino Superior, Auxiliares de Administração Escolar Rede Estadual Ensino Técnico-Profissional, Professores Rede Estadual Ensino Superior, Professores Rede Estadual Ensino Técnico-Profissional"
  replace professional_prof_state_TP=1 if categoria_profissional=="Professores Rede Estadual Ensino Superior, Professores Rede Estadual Ensino Técnico-Profissional"

  gen professional_prof_municipal=0
  replace  professional_prof_municipal=1 if categoria_profissional=="Professores Rede Municipal"
  replace  professional_prof_municipal=1 if categoria_profissional=="Professores Rede Municipal "
  replace professional_prof_municipal=1 if categoria_profissional=="Professores Rede Estadual, Professores Rede Municipal"
  replace professional_prof_municipal=1 if categoria_profissional=="Professores Rede Estadual, Professores Rede Federal, Professores Rede Municipal"
  replace professional_prof_municipal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Municipal, Professores Rede Estadual, Professores Rede Municipal"
  replace professional_prof_municipal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Federal, Auxiliares de Administração Escolar Rede Municipal, Professores Rede Estadual, Professores Rede Federal, Professores Rede Municipal"

  gen professional_prof_municipal_sup=0
  replace professional_prof_municipal_sup=1 if categoria_profissional=="Professores Rede Municipal Ensino Superior"
  replace professional_prof_municipal_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Municipal, Professores Rede Municipal"

  gen professional_prof_federal=0
  replace  professional_prof_federal=1 if categoria_profissional=="Professores Rede Federal"
  replace  professional_prof_federal=1 if categoria_profissional=="Professores Rede Federal "
  replace professional_prof_federal=1 if categoria_profissional=="Professores Rede Estadual, Professores Rede Federal, Professores Rede Municipal"
  replace professional_prof_federal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Federal, Professores Rede Federal"
  replace professional_prof_federal=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Estadual, Auxiliares de Administração Escolar Rede Federal, Auxiliares de Administração Escolar Rede Municipal, Professores Rede Estadual, Professores Rede Federal, Professores Rede Municipal"

  gen professional_prof_federal_sup=0
  replace  professional_prof_federal_sup=1 if categoria_profissional=="Professores Rede Estadual Ensino Superior"
  replace professional_prof_federal_sup=1 if categoria_profissional=="Professores Rede Federal Ensino Superior, Professores Rede Federal Ensino Técnico-Profissional"
  replace professional_prof_federal_sup=1 if categoria_profissional=="Professores Rede Federal Ensino Superior, Professores Rede Federal Ensino Técnico-Profissional"
  replace professional_prof_federal_sup=1 if categoria_profissional=="Professores Rede Estadual Ensino Superior, Professores Rede Federal Ensino Superior"
  replace professional_prof_federal_sup=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Federal Ensino Superior, Professores Rede Federal Ensino Superior"

  gen professional_prof_federal_TP=0
  replace  professional_prof_federal_TP=1 if categoria_profissional=="Professores Rede Federal Ensino Técnico-Profissional"
  replace professional_prof_federal_TP=1 if categoria_profissional=="Professores Rede Federal Ensino Superior, Professores Rede Federal Ensino Técnico-Profissional"
  replace professional_prof_federal_TP=1 if categoria_profissional=="Auxiliares de Administração Escolar Rede Federal Ensino Técnico-Profissional, Professores Rede Federal Ensino Técnico-Profissional"

  gen professional_general_state=0
  replace  professional_general_state=1 if categoria_profissional=="Rede Pública Estadual de ENSINO"
  gen professional_general_federal=0
  replace  professional_general_federal=1 if categoria_profissional=="Rede Pública Federal de ENSINO"

  *Alternative no. 2, instead of specific categories, breakdown in subcategories 
  gen professor=0
  gen auxiliar=0
  gen categoria_municipal=0
  gen categoria_federal=0
  gen categoria_state=0
  gen categoria_superior=0
  gen categoria_TP=0

  #delimit ;
  replace auxiliar=1 if professional_aux_federal==1 |
  professional_aux_federal_TP==1 |
  professional_aux_federal_sup==1 |
  professional_aux_municipal==1 |
  professional_aux_state==1 |
  professional_aux_state_TP==1 |
  professional_aux_state_sup==1 
  ;

  replace professor=1 if professional_prof_federal==1 |
  professional_prof_federal_TP==1 |
  professional_prof_federal_sup==1 |
  professional_prof_municipal==1 |
  professional_prof_municipal_sup==1 |
  professional_prof_state==1 |
  professional_prof_state_TP==1 |
  professional_prof_state_sup==1
  
  ;
  replace categoria_municipal=1 if professional_aux_municipal==1 |
  professional_prof_municipal==1 |
  professional_prof_municipal_sup==1 
  
  ;
  replace categoria_federal=1 if professional_aux_federal==1 |
  professional_aux_federal_TP==1 |
  professional_aux_federal_sup==1 
  
  ;
  replace categoria_state=1 if  professional_aux_state==1 |
  professional_aux_state_TP==1 |
  professional_aux_state_sup==1 |
   professional_prof_state==1 |
  professional_prof_state_TP==1 |
  professional_prof_state_sup==1
  
  ;
  replace categoria_superior=1 if professional_aux_federal_sup==1 |
  professional_aux_state_sup==1 |
  professional_prof_municipal_sup==1 |
  professional_prof_state_sup==1
  
  ;
  replace categoria_TP=1 if  professional_aux_federal_TP==1 |
  professional_aux_state_TP==1 |
  professional_prof_federal_TP==1 |
  professional_prof_state_TP==1 
  
  ;
  #delimit cr 
  
  
  
  *format start_date, start_year, end_date, end_year. In the future correct for leap years.
  gen start_date=date(inicio, "MDY")
  format start_date  %td
  gen start_year=year(start_date)
  gen end_date=start_date + dias - 1
  format end_date  %td
  gen end_year=year(end_date)
  gen different_year=0
  replace different_year=1 if end_year-start_year>0
  drop inicio

  *rename variables in Portuguese into English
  rename dias days
  rename numero strike_code
  rename categoria_profissional professional_group
  rename empregador_trabalhadores employer
  rename _merge merge_issues
  replace merge_issues=0 if merge_issues==3


  *label variables
  label var strike_code "unique identifier for strike event"
  label var professional_group "Type of professional group participating on a strike"
  label var geo_location "Name for location of strike event. Can be county (full name as of 2017), state (2 letters) or country"
  label var employer "Employer of strikers"
  label var abrangencia "Type of employer"
  label var days "Number of days for the duration of the strike"
  label var code "County/State code (IBGE 7 digits)/(IBGE 2 digits)"
  label var geography "Level of aggregation (county | state | country)"
  label var merge_issues "1 if not merged yet, 0 if else"
  label var type_propositive "Type of strike: 1 if propositive, 0 if else"
  label var type_defensive "Type of strike: 1 if defensive, 0 if else"
  label var type_protest "Type of strike: 1 if protest, 0 if else"
  label var power_municipal "Original alvo_esfera: 1 if poder_municipal, 0 if else"
  label var power_state "Original alvo_esfera: 1 if poder_estadual, 0 if else"
  label var power_federal "Original alvo_esfera: 1 if poder_federal, 0 if else"
  label var professional_aux_state "From categoria_profissional: 1 if Auxiliares de Administração Escolar Rede Estadao"
  label var professional_aux_state_sup "From categoria_profissional: 1 if Auxiliares de Administração Escolar Rede Estadao Superior"
  label var professional_aux_state_TP "From categoria_profissional: 1 if Auxiliares de Administração Escolar Rede Estadual Ensino Técnico-Profissional"
  label var professional_aux_federal "From categoria_profissional: 1 if Auxiliares de Administração Escolar Rede Federal"
  label var professional_aux_federal_sup "From categoria_profissional: 1 if Auxiliares de Administração Escolar Rede Federal Ensino Superior"
  label var professional_aux_federal_TP "From categoria_profissional: 1 if Auxiliares de Administração Escolar Rede Federal Ensino Técnico-Profissional"
  label var professional_aux_municipal "From categoria_profissional: 1 if Auxiliares de Administração Escolar Rede Municipal"
  label var professional_prof_state "From categoria_profissional: 1 if Professores de Administração Escolar Rede Estadao"
  label var professional_prof_state_sup "From categoria_profissional: 1 if Professores de Administração Escolar Rede Estadual Ensino Superior"
  label var professional_prof_state_TP  "From categoria_profissional: 1 if Professores de Administração Escolar Rede Estadual Ensino Técnico-Profissional" 
  label var professional_prof_municipal "From categoria_profissional: 1 if Professores de Administração Escolar Rede Municipal"
  label var professional_prof_municipal_sup "From categoria_profissional: 1 if Professores de Administração Escolar Rede Municipal Ensino Superior"
  label var professional_prof_federal "From categoria_profissional: 1 if Professores de Administração Escolar Rede Federal"
  label var professional_prof_federal_sup "From categoria_profissional: 1 if Professores de Administração Escolar Rede Federal Ensino Superior"
  label var professional_prof_federal_TP "From categoria_profissional: 1 if Professores de Administração Escolar Rede Federal Ensino Técnico-Profissional"
  label var professional_general_state "From categoria_profissional: 1 if Rede Pública Estadual de ENSINO"
  label var professional_general_federal "From categoria_profissional: 1 if Rede Pública Federal de ENSINO"
  label var start_date "Starting date of the strike"
  label var start_year "Starting year of the strike"
  label var end_date "Ending date of the strike, own calculations startdate+days"
  label var end_year "Ending year of the strike, own calculations startdate+days"
  label var different_year "1 end_year is different than start_year"
  label var professor "1 if any professional_prof ==1, 0 if else"
  label var auxiliar "1 if any professional_aux ==1, 0 if else"
  label var categoria_municipal "1 if any professional_municipal ==1, 0 if else"
  label var categoria_federal "1 if any professional_federal ==1, 0 if else"
  label var categoria_state "1 if any professional_state ==1, 0 if else"
  label var categoria_superior "1 if any professional_sup ==1, 0 if else"
  label var categoria_TP "1 if any professional_TP ==1, 0 if else"
 
  *explore number of strikes per geo_location per year 
  preserve
  gen strike=1
  collapse (sum) strike days, by(start_year geo_location)
  restore
 
  preserve
  keep if merge_issues ==1
  split geo_location, p(", ")
  drop if geo_location=="NACIONAL"
  drop geo_location
  reshape long geo_location, i(geo_location? strike_code)
  sort strike_code _j
  drop if geo_location==""
  drop geo_location1 geo_location2 geo_location3 geo_location4 geo_location5 geo_location6
  rename _j multiple_location_strike
  drop code geography
  merge m:1 geo_location using "`codecountylist'"
  drop if _merge==2
  tempfile append_multiple_strike
  save "`append_multiple_strike'"
  restore
  
  append using "`append_multiple_strike'"
  replace multiple_location_strike=0 if multiple_location_strike==.
  
  save "`strike_clean'\DIEESE_strikes.dta", replace 
  
  *-----------------------------------------------------------------------------
  * In the future, next section modifys data to fit specification and merge with fullbrazil.dta Options: 1. Collapse number of strikes by year and county 2. Collapse number of days by year and county; additional specs: include type of strike and type of participants 
  *-----------------------------------------------------------------------------

  
  
  /*
*2b. Some locations in the strike DIEESE data are multi states and multicity. DECISION POINT: How to treat?

NACIONAL
AM, PA
BA, PB, PR
Uberaba/MG, Uberlândia/MG
Cuiabá/MT, Várzea Grande/MT
Nova Mutum/MT, Porto Velho/RO
Ribeirão Preto/SP, Serrana/SP
Reserva do Cabaçal/MT, Sinop/MT
Barretos/SP, Franca/SP, Ribeirão Preto/SP
Avaré/SP, Cerqueira César/SP, Itapetininga/SP
Barcarena/PA, Castanhal/PA, Conceição do Araguaia/PA, Jacundá/PA, Tucuruí/PA
Estrela do Norte/SP, Presidente Prudente/SP, Regente Feijó/SP, Rosana/SP, Sandovalina/SP
Brasnorte/MT, Jaciara/MT, Nova Olímpia/MT, Ribeirão Cascalheira/MT, Santo Antônio do Leverger/MT, Vila Rica/MT
clean categoria_profissional, change carater 1, 2, 3 to binary with labe

*/

}





