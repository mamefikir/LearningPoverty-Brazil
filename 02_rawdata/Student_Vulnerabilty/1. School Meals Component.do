********************************************************************************
***  
***                          School Meals
***               Author(s): Ildo Lautharte 
***  
********************************************************************************

*** ============================================================================
***                    Cleaning the data from Directors SAEB 2017
*** ============================================================================

clear
import delimited "C:\Users\wb499746\WBG\Andre Loureiro - Ceara - ICMS vs PAIC\1. Raw Data\B. Diretores\SAEB 2017\TS_DIRETOR.csv"

*** ============================================================================
*** Cleaning the sample

drop if in_preenchimento_questionario ==0
drop in_preenchimento_questionario 

*** Type of School

      gen Private_School = 1 if id_dependencia_adm ==4
  replace Private_School = 0 if id_dependencia_adm ==1
  replace Private_School = 0 if id_dependencia_adm ==2
  replace Private_School = 0 if id_dependencia_adm ==3
label var Private_School "Private School"

      gen Municipal_School = 1 if id_dependencia_adm ==3
  replace Municipal_School = 0 if id_dependencia_adm ==4
  replace Municipal_School = 0 if id_dependencia_adm ==2
  replace Municipal_School = 0 if id_dependencia_adm ==1
label var Municipal_School "Municipal School"

      gen State_School = 1 if id_dependencia_adm ==2
  replace State_School = 0 if id_dependencia_adm ==4
  replace State_School = 0 if id_dependencia_adm ==3
  replace State_School = 0 if id_dependencia_adm ==1
label var State_School "State School"

* Dependencia Administrativa
*  1 - Federal
*  2 - Estadual
*  3 - Municipal
*  4 - Privada
***==============================================================================

*** School Location

      gen Rural_School = 1 if id_localizacao ==2
  replace Rural_School = 0 if id_localizacao ==1
label var Rural_School "Rural School"

      gen Urban_School = 1 if id_localizacao ==1
  replace Urban_School = 0 if id_localizacao ==2
label var Urban_School "Urban School" 

* Localização
* 1 - Urbana
* 2 - Rural
*** ============================================================================
***
***          Creating the Labels and variables
***
*** ============================================================================

rename *, lower

***=============================================================================
*** Sexo
label var tx_resp_q001 "Qual é o seu sexo? "

      gen Male = 1 if tx_resp_q001 == "A"
  replace Male = 0 if tx_resp_q001 == "B"
label var Male "If Male Teacher"

* Sexo
* A Masculino
* B Feminino
*** ============================================================================
***                            School Meal Component
*** TX_RESP_Q062  
*** Em relação à merenda escolar, como você avalia os seguintes aspectos: 
*** Recursos financeiros.	
* (A) Inexistente.	
* (B) Ruim.	
* (C) Razoável.	
* (D) Bom.	
* (E) Ótimo.

      gen Meals_Resources = 0 if tx_resp_q062 == "A"
  replace Meals_Resources = 0 if tx_resp_q062 == "B"
  replace Meals_Resources = 0 if tx_resp_q062 == "C"
  replace Meals_Resources = 1 if tx_resp_q062 == "D"
  replace Meals_Resources = 1 if tx_resp_q062 == "E"
label var Meals_Resources "School Meals: Resources are not enough"

*** ============================================================================
*** TX_RESP_Q063	
*** Em relação à merenda escolar, como você avalia os seguintes aspectos: 
*** Quantidade de alimentos.	

      gen Meals_Quantity = 0 if tx_resp_q063 == "A"
  replace Meals_Quantity = 0 if tx_resp_q063 == "B"
  replace Meals_Quantity = 0 if tx_resp_q063 == "C"
  replace Meals_Quantity = 1 if tx_resp_q063 == "D"
  replace Meals_Quantity = 1 if tx_resp_q063 == "E"
label var Meals_Quantity "School Meals: Quantity is not enough"

* (A) Inexistente.	
* (B) Ruim.	
* (C) Razoável.	
* (D) Bom.	
* (E) Ótimo.
*** ============================================================================
*** TX_RESP_Q064	
*** Em relação à merenda escolar, como você avalia os seguintes aspectos: 
*** Qualidade de alimentos.

      gen Meals_Quality = 0 if tx_resp_q064 == "A"
  replace Meals_Quality = 0 if tx_resp_q064 == "B"
  replace Meals_Quality = 0 if tx_resp_q064 == "C"
  replace Meals_Quality = 1 if tx_resp_q064 == "D"
  replace Meals_Quality = 1 if tx_resp_q064 == "E"
label var Meals_Quality "School Meals: Quality is not good"

* (A) Inexistente.	
* (B) Ruim.	
* (C) Razoável.	
* (D) Bom.	
* (E) Ótimo.
*** ============================================================================

gen School_Meals = Meals_Quality + Meals_Quantity + Meals_Resources

*** ============================================================================
***                  School Meals Component
*** ============================================================================
*** Regression weights

*** Number of students per school

merge m:1 id_escola using "C:\Users\wb499746\WBG\Andre Loureiro - Ceara - ICMS vs PAIC\11. Weights\Weights 2017.dta", force
drop if _merge ==2
drop _merge 

replace municipal_school = Municipal_School
drop if Private_School ==1

*** ============================================================================

collapse (mean) School_Meals id_uf [weight = SchoolSize], by(id_municipio)

egen Max = max(School_Meals)
egen Min = min(School_Meals)

replace School_Meals = (School_Meals - Min)/(Max - Min)
drop Max Min

compress
destring *, replace

save "C:\Users\wb499746\OneDrive - WBG\Desktop\Education COVID 19\COVID 19 Response report\SAEB 2017 - School Meals.dta", replace

*** ========================================================================
