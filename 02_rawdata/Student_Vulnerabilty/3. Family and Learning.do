********************************************************************************
***
***                Paper: Index of Vulnerability to Corona
***                      Author(s): Ildo Lautharte 
***  
********************************************************************************

clear 
import delimited "D:\Microdados - SAEB\microdados_saeb_2017\DADOS\TS_ALUNO_5EF.csv", delimiter(",") 
rename *, lower

*** ============================================================================

tostring id_municipio, replace
      gen Region = substr(id_municipio,1,1)
label var Region "INEP Regional Id"
      gen City = substr(id_municipio,1,6)
label var City "INEP City Id"
destring City Region id_municipio, replace

*** ============================================================================
***              Dropping students that did not answer the exam

drop if in_preenchimento_prova ==0
drop if in_preenchimento_questionario ==0
drop id_regiao in_situacao_censo in_proficiencia erro_padrao_lp erro_padrao_lp_saeb erro_padrao_mt erro_padrao_mt_saeb
drop id_turno in_preenchimento_prova id_caderno id_bloco_1 tx_resp_bloco_1_lp tx_resp_bloco_2_lp tx_resp_bloco_1_mt tx_resp_bloco_2_mt estrato_aneb in_preenchimento_questionario

*** ============================================================================
*** Generating Variables

      gen Serie4 = (id_serie ==5)
label var Serie4 "Alunos, 4 Série"

      gen Serie8 = (id_serie ==9)
label var Serie8 "Alunos, 8 Série"

rename proficiencia_lp_saeb Scores_Portuguese
label var Scores_Portuguese "Notas Portugues"

rename proficiencia_lp Scores_Portuguese_std
label var Scores_Portuguese_std "Notas Portugues Padronizadas"

rename proficiencia_mt_saeb Scores_Mathematics
label var Scores_Mathematics "Notas matemática"

rename proficiencia_mt Scores_Mathematics_std
label var Scores_Mathematics_std "Notas matemática Padronizadas"

      gen Ano = id_prova_brasil
label var Ano "Ano do Saeb"

drop id_prova_brasil id_area in_presenca_prova id_bloco_2 in_prova_brasil
compress

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

* Unidade da Federação
* 11 Rondônia
* 12 Acre
* 13 Amazonas
* 14 Roraima
* 15 Pará
* 16 Amapá
* 17 Tocantins
* 21 Maranhão
* 22 Piauí
* 23 Ceará
* 24 Rio Grande do Norte
* 25 Paraíba
* 26 Pernambuco
* 27 Alagoas
* 28 Sergipe
* 29 Bahia
* 31 Minas Gerais
* 32 Espírito Santo
* 33 Rio de Janeiro
* 35 São Paulo
* 41 Paraná
* 42 Santa Catarina
* 43 Rio Grande do Sul
* 50 Mato Grosso do Sul
* 51 Mato Grosso
* 52 Goiás
* 53 Distrito Federal
*** ============================================================================
***                          Type of School

      gen Private_School = 1 if id_dependencia_adm ==4
  replace Private_School = 0 if id_dependencia_adm ==2
  replace Private_School = 0 if id_dependencia_adm ==3
  replace Private_School = 0 if id_dependencia_adm ==1
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
* 1 - Federal
* 2 - Estadual
* 3 - Municipal
* 4 - Privada
*** Sexo: 

      gen Boys = 1 if tx_resp_q001 =="A"
  replace Boys = 0 if tx_resp_q001 =="B"
label var Boys "Boys, Alunos"
 
      gen Girls = 1 if tx_resp_q001 =="B"
  replace Girls = 0 if tx_resp_q001 =="A"
label var Girls "Girls, Alunos"

*  Sexo?
*  A Masculino
*  B Feminino
*** ============================================================================
*** Race

      gen White_Students = 1 if tx_resp_q002 =="A" 
  replace White_Students = 0 if tx_resp_q002 =="B" 
  replace White_Students = 0 if tx_resp_q002 =="C" 
  replace White_Students = 0 if tx_resp_q002 =="D" 
  replace White_Students = 0 if tx_resp_q002 =="E" 
  replace White_Students = . if tx_resp_q002 =="F" 
label var White_Students "White Students, Self-report"

      gen NonWhite_Students = 0 if tx_resp_q002 =="A" 
  replace NonWhite_Students = 1 if tx_resp_q002 =="B" 
  replace NonWhite_Students = 1 if tx_resp_q002 =="C" 
  replace NonWhite_Students = 1 if tx_resp_q002 =="D" 
  replace NonWhite_Students = 1 if tx_resp_q002 =="E" 
  replace NonWhite_Students = . if tx_resp_q002 =="F" 
label var NonWhite_Students "NonWhite Students, Self-report"

* Como você se considera? 
* A Branco(a)
* B Pardo(a)/Mulato(a)
* C Preto(a)
* D Amarelo (a)
* E Indígena
* F Não Quero Declarar
*** ============================================================================
*** Age

      gen Student_Age = 8  if tx_resp_q004 == "A"
  replace Student_Age = 9  if tx_resp_q004 == "B"
  replace Student_Age = 10 if tx_resp_q004 == "C"
  replace Student_Age = 11 if tx_resp_q004 == "D"
  replace Student_Age = 12 if tx_resp_q004 == "E"
  replace Student_Age = 13 if tx_resp_q004 == "F"
  replace Student_Age = 14 if tx_resp_q004 == "G"
  replace Student_Age = 15 if tx_resp_q004 == "H"
label var Student_Age "Student Age, Year"

* Qual a sua idade? 
* A 8 anos ou menos
* B 9 anos
* C 10 anos
* D 11 anos
* E 12 anos
* F 13 anos
* G 14 anos
* H 15 anos ou mais
*** ============================================================================
*** Household Size

      gen Household_Size = 1  if tx_resp_q016 == "A"
  replace Household_Size = 3  if tx_resp_q016 == "B"
  replace Household_Size = 4  if tx_resp_q016 == "C"
  replace Household_Size = 5  if tx_resp_q016 == "D"
  replace Household_Size = 6  if tx_resp_q016 == "E"
  replace Household_Size = 7  if tx_resp_q016 == "F"
label var Household_Size "Household Size, number of people"

*** Quantas pessoas moram com você? 
* A Moro sozinho(a)
* B Moro com mais 2 pessoas
* C Moro com mais 3 pessoas
* D Moro com mais 4 
* E Moro com mais 5
* F Moro com mais 6 pessoas ou mais
*** ============================================================================
***
***                       Vulnerability Index
***
*** ============================================================================
***                   Component: Family
*** ============================================================================
*** Work

     gen  Work_Student = 1 if tx_resp_q042 == "A"
  replace Work_Student = 0 if tx_resp_q042 == "B"
label var Work_Student "if the student works"

*** Você Trabalha fora de casa? 
* A Sim
* B Não
*** ============================================================================
*** Mothers Education

      gen Mother_LessHigherEduc = 0 if tx_resp_q019 =="E"
  replace Mother_LessHigherEduc = 0 if tx_resp_q019 =="F"
  replace Mother_LessHigherEduc = 1 if tx_resp_q019 !="F" & tx_resp_q019 !="E"
  replace Mother_LessHigherEduc = . if tx_resp_q019 =="" | tx_resp_q019  ==""
label var Mother_LessHigherEduc "Mother less than higher Educ"

* Ate que serie sua mãe estudou? 
* A Nunca estudou
* B Não Completou a 4 'seire
* C Completou a 4ª serie, mas não completou a 8ª serie (antigo ginasio)
* D Completou a 8ª serie, mas não completou o Ensino Medio (antigo 2º grau)
* E Completou o Ensino Medio, mas Não completou a Faculdade
* F Completou a Faculdade
* G Não sei
*** ============================================================================
***               Mother Reads (Family Engagement)

      gen Mother_DoNotRead = 0 if tx_resp_q021 == "A"
  replace Mother_DoNotRead = 1 if tx_resp_q021 == "B"
label var Mother_DoNotRead "Mother do not Reads"

* Você vê sua mãe lendo? 
* A Sim
* B Não
*** ============================================================================
*** Parent_Talk

      gen Parents_TalkSchool = 0 if tx_resp_q031 == "A"
  replace Parents_TalkSchool = 1 if tx_resp_q031 == "B"
label var Parents_TalkSchool "Parents Talk About School"

* Seus pais ou responsáveis conversam sobre o que acontece na escola?
* A Sim
* B Não
*** ============================================================================
*** Parent help with homework

      gen Parents_HelpHomeWork = 0 if tx_resp_q028 == "A"
  replace Parents_HelpHomeWork = 1 if tx_resp_q028 == "B"
label var Parents_HelpHomeWork "Parents Help Home Work"

* Seus pais ou responsáveis ajudam você a fazer a lição de casa?
* A Sim
* B Não
***=============================================================================
*** Parents Talk Skip School

      gen Parents_SkipSchool = 0 if tx_resp_q030 == "A"
  replace Parents_SkipSchool = 1 if tx_resp_q030 == "B"
label var Parents_SkipSchool "Parents say don't skip school"

* Seus pais ou responsáveis falam para você não faltar a escola?
* A Sim
* B Não
*** ============================================================================
*** Parent School Meetings

      gen Parents_NoMeeting = 0 if tx_resp_q026 == "A"
  replace Parents_NoMeeting = 0 if tx_resp_q026 == "B"
  replace Parents_NoMeeting = 1 if tx_resp_q026 == "C"
label var Parents_NoMeeting "Parents go to School Meeting"

* Seus pais ou responsáveis vão a reunião de pais na escola?
* A Sempre ou quase sempre
* B De vez em quando
* C Nunca ou quase nunca
*** ============================================================================
***                   Family

gen Family_Vulnerability = Parents_NoMeeting + Parents_HelpHomeWork + Parents_SkipSchool + Parents_TalkSchool + Mother_DoNotRead + Mother_LessHigherEduc + Work_Student

*** ============================================================================
***                       Learning Component
*** Reprobation

      gen Reprobation = 0 if tx_resp_q045 == "A"
  replace Reprobation = 1 if tx_resp_q045 == "B"
  replace Reprobation = 1 if tx_resp_q045 == "C"
label var Reprobation "Ever repeat school year?"

* TX_RESP_Q045	Questão 45		Você já foi reprovado?	
* Não.	
* Sim, uma vez.	
* Sim, duas vezes ou mais.
*** ============================================================================
***      Drop outs

      gen Dropout = 0 if tx_resp_q046 == "A"
  replace Dropout = 1 if tx_resp_q046 == "B"
  replace Dropout = 1 if tx_resp_q046 == "C"
label var Dropout "Ever dropped out school?"

* TX_RESP_Q046	
* Você já abandonou a escola durante o período de aulas e ficou fora da escola o resto do ano?	
* Não.	
* Sim, uma vez.	
* Sim, duas vezes ou mais.
*** ============================================================================
***         Usually go to the library

      gen NoLibrary = 0 if tx_resp_q051 == "A"
  replace NoLibrary = 1 if tx_resp_q051 == "B"
  replace NoLibrary = 1 if tx_resp_q051 == "C"
label var NoLibrary "Never go to the Library?"

* TX_RESP_Q051	
* Você utiliza a biblioteca ou sala de leitura da sua escola?	
* Sempre ou quase sempre.	
* De vez em quando.
* Nunca ou quase nunca.

*** ============================================================================
*** Do you do homework?

      gen NoHomework = 0 if tx_resp_q049 == "A"
  replace NoHomework = 1 if tx_resp_q049 != "A"
  replace NoHomework = . if tx_resp_q049 == ""
label var NoHomework "Student do not do Maths Homework"

* Você faz a lição de casa de matemática?
* A Sempre ou quase sempre
* B De vez em quando
* C Nunca ou quase nunca
*** ============================================================================
***                         Learning Poverty

 gen Portuguese_Vulnerable = (Scores_Portuguese < 150)
gen Mathematics_Vulnerable = (Scores_Mathematics < 150)

*** ============================================================================
***                      Learning

gen Learning = Portuguese_Vulnerable + Mathematics_Vulnerable + NoHomework + Dropout + Reprobation

*** ============================================================================
drop if Private_School ==1

collapse (mean) Learning Family_Vulnerability id_uf [weight = peso_aluno_mt], by(id_municipio)

egen Max = max(Learning)
egen Min = min(Learning)
replace Learning = (Learning - Min)/(Max - Min)
drop Max Min

egen Max = max(Family_Vulnerability)
egen Min = min(Family_Vulnerability)
replace Family_Vulnerability = (Family_Vulnerability - Min)/(Max - Min)
drop Max Min

compress
destring *, replace
save "C:\Users\wb499746\OneDrive - WBG\Desktop\Education COVID 19\COVID 19 Response report\SAEB 2017 - Learning and Family Components.dta", replace

*** ============================================================================
