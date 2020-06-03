*! Get data on CCT (PBF) by county from API
* This program will purposefully not be incorporated in the run.do.
* Instead, the outcome csv will be saved in the repo rawdata
* to ensure it remains available and with static info if API changes
* DG, Apr 10 2020

global mypath "C:/Users/WB552057/Desktop/"

clear
save "${mypath}/PBF_county.dta", replace emptyok

* Source:
*   Ministerio do Desenvolvimento Social
*   http://www.dados.gov.br/dataset/bolsa-familia-misocial
local url_left  "http://aplicacoes.mds.gov.br/sagi/servicos/misocial?q=*&fq=anomes_s:"
local url_right"*&fq=tipo_s:mes_mu&wt=csv&fl=ibge:codigo_ibge,anomes:anomes_s,qtd_familias_beneficiarias_bolsa_familia,valor_repassado_bolsa_familia&rows=10000000&sort=anomes_s%20asc,%20codigo_ibge%20asc"

* Calls API for each file and append to final dataset
forvalues year=2004(1)2019 {
	tempfile year_csv
  copy `"`url_left'`year'`url_right'"' `"`year_csv'"', replace
  import delimited `"`year_csv'"', clear
  append using "${mypath}/PBF_county.dta"
  save "${mypath}/PBF_county.dta", replace
}

* Processes data
gen int ano = int(anomes/100)
gen int mes = anomes - ano*100
drop anomes
collapse (mean) n_families_pbf = qtd_familias_beneficiarias_bolsa ///
         (sum)  value_pbf = valor_repassado_bolsa_familia, by(ano ibge)
         
isid ibge ano
save "${mypath}/PBF_county.dta", replace

export delimited "${mypath}/PBF_county.csv", replace