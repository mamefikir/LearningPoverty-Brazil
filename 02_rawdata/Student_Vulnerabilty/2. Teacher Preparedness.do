********************************************************************************
***  
***                              Teacher
***                         Ildo Lautharte
***  
********************************************************************************
*** ============================================================================
***                  The data from Teachers SAEB 2017
*** ============================================================================

clear
import delimited "C:\Users\wb499746\WBG\Andre Loureiro - Ceara - ICMS vs PAIC\1. Raw Data\C. Professores\SAEB 2017\TS_PROFESSOR.csv", delimiter(",") 

*** ============================================================================
*** Cleaning the sample

label var id_escola "Código da Escola"
label var id_dependencia_adm "Dependência Administrativa(Estadual/Municipal/Particular)"

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
label var id_localizacao "Localização(Urbano/Rural)"

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
***==============================================================================

label var id_uf "Unidade da Federação"
label var id_turma "Código da Turma"
label var id_municipio "Código do Município"
label var id_serie "Código da Série"

rename id_prova_brasil Ano
             label var Ano "Ano de Aplicação do SAEB"

drop if in_preenchimento_questionario ==0
drop in_preenchimento co_professor
compress

*** ============================================================================
***                  Variables        
* TX_RESP_Q031	
* Considerando os temas a seguir, indique por favor sua necessidade de aperfeiçoamento profissional. 
* Uso pedagógico das Tecnologias de Informação e Comunicação.	

    gen Technology_Training = 0 if tx_resp_q031 == "A"
replace Technology_Training = 0 if tx_resp_q031 == "B"
replace Technology_Training = 1 if tx_resp_q031 == "C"
replace Technology_Training = 1 if tx_resp_q031 == "D"

* (A) Não há necessidade.	
* (B) Baixo nível de necessidade.	
* (C) Nível moderado de necessidade.	
* (D) Alto nível de necessidade.


gen State = id_uf

    gen Estados = ""
replace Estados = "Rondônia" if State == 11
replace Estados = "Acre" if State == 12
replace Estados = "Amazonas" if State == 13
replace Estados = "Roraima" if State == 14
replace Estados = "Pará" if State == 15
replace Estados = "Amapá" if State == 16
replace Estados = "Tocantins" if State == 17
replace Estados = "Maranhão" if State == 21
replace Estados = "Piauí" if State == 22
replace Estados = "Ceará" if State == 23
replace Estados = "Rio Grande do Norte" if State == 24
replace Estados = "Paraíba" if State == 25
replace Estados = "Pernambuco" if State == 26
replace Estados = "Alagoas" if State == 27
replace Estados = "Sergipe" if State == 28
replace Estados = "Bahia" if State == 29
replace Estados = "Minas Gerais" if State == 31
replace Estados = "Espírito Santo" if State == 32
replace Estados = "Rio de Janeiro" if State == 33
replace Estados = "São Paulo" if State == 35
replace Estados = "Paraná" if State == 41
replace Estados = "Santa Catarina" if State == 42
replace Estados = "Rio Grande do Sul" if State == 43 
replace Estados = "Mato Grosso do Sul" if State == 50
replace Estados = "Mato Grosso" if State == 51
replace Estados = "Goiás" if State == 52
replace Estados = "Distrito Federal" if State == 53
label var Estados "State Names"

graph hbar Technology_Training, over(Estados, sort(Technology_Training) gap(*.2) label(ang(0) labsize(vsmall))) bar(1, fcolor(ebblue)) intensity(*.8) blabel(bar, position(outside) format(%12.2f) color(black) size(small)) nofill graphregion(color(white)) title("{bf: Great part of Teachers report the need of additional training}" "{bf: on Pedagogical Use of Information Technology, SAEB 2017}",  span pos(11) color(black) size(medium)) plotregion(color(white)) ytitle("Percentage of Teachers") exclude0 ylab(.50(.1).80) leg(ring(0) col(1))

necessidade de aperfeiçoamento profissional. 

* Uso pedagógico das Tecnologias de Informação e Comunicação.
** =============================================================================
* TX_RESP_Q050	
* Gostaríamos de saber quais os recursos que você utiliza para fins pedagógicos, nesta turma: 
*** Internet.	
* Não utilizo porque a escola não tem.	
* Nunca.	
* De vez em quando.	
* Sempre ou quase sempre.	

    gen Internet_Use = 1 if tx_resp_q050 == "A"
replace Internet_Use = 1 if tx_resp_q050 == "B"
replace Internet_Use = 0 if tx_resp_q050 == "C"
replace Internet_Use = 0 if tx_resp_q050 == "D"

graph hbar Internet_Use, over(Estados, sort(Internet_Use) gap(*.2) label(ang(0) labsize(vsmall))) bar(1, fcolor(cranberry)) intensity(*.6) blabel(bar, position(outside) format(%12.2f) color(black) size(small)) nofill graphregion(color(white)) title("{bf: Teachers reporting not using internet for pedagogical purposes, SAEB 2017}",  span pos(11) color(black) size(medium)) plotregion(color(white)) ytitle("Percentage of Teachers") exclude0 ylab(0(.1).40) leg(ring(0) col(1))


*** ============================================================================
* TX_RESP_Q051	
* Neste ano e nesta escola, como se deu a elaboração do Projeto Pedagógico?	
* Não sei como foi desenvolvido.	Não existe Projeto Pedagógico.	Utilizando-se um modelo pronto, sem discussão com a equipe escolar.	Utilizando-se um modelo pronto, mas com discussão com a equipe escolar.	Utilizando-se um modelo pronto, porém com adaptações, sem discussão com a equipe escolar.

    gen Proj_Pedagogico = 1 if tx_resp_q051 == "A"
replace Proj_Pedagogico = 1 if tx_resp_q051 == "B"
replace Proj_Pedagogico = 0 if tx_resp_q051 == "C"
replace Proj_Pedagogico = 0 if tx_resp_q051 == "D"
replace Proj_Pedagogico = 0 if tx_resp_q051 == "E"
replace Proj_Pedagogico = 0 if tx_resp_q051 == "F"
replace Proj_Pedagogico = 0 if tx_resp_q051 == "G"
replace Proj_Pedagogico = 0 if tx_resp_q051 == "H"

* (A) Não sei como foi desenvolvido.	
* (B) Não existe Projeto Pedagógico.	
* (C) Utilizando-se um modelo pronto, sem discussão com a equipe escolar.	
* (D) Utilizando-se um modelo pronto, mas com discussão com a equipe escolar.	
* (E) Utilizando-se um modelo pronto, porém com adaptações, sem discussão com a equipe escolar.	
* (F) Utilizando-se um modelo pronto, porém com adaptações e com discussão com a equipe escolar.	
* (G) Elaborou-se um modelo próprio, mas não houve discussão com a equipe escolar.	
* (H) Elaborou-se um modelo próprio e houve discussão com a equipe escolar.
*** ============================================================================
*** TX_RESP_Q073	
*** Na sua percepção, os possíveis problemas de aprendizagem dos alunos das série(s) ou ano(s) avaliado(s) ocorrem, nesta escola, devido à/ao(s): 
*** Não cumprimento dos conteúdos curriculares ao longo da trajetória escolar do aluno.	
*** Sim.	Não.

    gen Cumprir_Curriculo = 1 if tx_resp_q073 == "A"
replace Cumprir_Curriculo = 1 if tx_resp_q073 == "B"
replace Cumprir_Curriculo = 0 if tx_resp_q073 == "C"
replace Cumprir_Curriculo = 0 if tx_resp_q073 == "D"

*** ============================================================================
***                   Teacher component

gen Teacher_Component = Cumprir_Curriculo + Proj_Pedagogico + Internet_Use + Technology_Training

*** ============================================================================
***                  School Meals Component
*** ============================================================================
*** Regression weights

*** Number of students in the school

merge m:1 id_escola using "C:\Users\wb499746\WBG\Andre Loureiro - Ceara - ICMS vs PAIC\11. Weights\Weights 2017.dta", force
drop if _merge ==2
drop _merge 

drop if Private_School ==1

*** ============================================================================

collapse (mean) Teacher_Component id_uf [weight = SchoolSize], by(id_municipio)

egen Max = max(Teacher_Component)
egen Min = min(Teacher_Component)

replace Teacher_Component = (Teacher_Component - Min)/(Max - Min)
drop Max Min

compress
destring *, replace

save "C:\Users\wb499746\OneDrive - WBG\Desktop\Education COVID 19\COVID 19 Response report\SAEB 2017 - Teacher.dta", replace

*** ============================================================================
