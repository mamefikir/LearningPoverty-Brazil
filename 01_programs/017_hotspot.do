*==============================================================================*
* TASK 017  HotSpot analysis
* Author:   Mina Ekramnia
*==============================================================================*

/* Hotspot function creates identifies statistically significant spatial clusters
of high values (hot spots) and low values (cold spots). It creates a new Output
Feature Class with a z-score, p-value, and confidence level bin (Gi_Bin) for each
feature in the Input Feature Class. HotSpot_weight.do calculates each hotspot based
on the population weight of each municipality and return geS_learn_P variable as
output for the p-value. Analysis done with inverse distance weight matrix */

*-----------------------------------------------------------------------------

* Load hotspot ado
do "${clone}/01_programs/Hotspot_ado/hotspot.ado

* Importing centroids txt (hosted in Repo - was calculated in ArcGIS based on shapefile downloaded from IBGE)
import delimited "${clone}/02_rawdata/IBGE_Shapefile/IBGE_counties_centroids.txt", encoding("utf-8") clear
rename cd_geocmu code
save "${clone}/02_rawdata/IBGE_Shapefile/IBGE_counties_centroids.dta", replace


* Open consolidated and ready to use dataset by county with 2013 and 2017
import delimited   "${clone}/04_outputs/LP_Brazil_by_county.csv", clear
keep if year == 2017

* Merge centroid information
merge m:1 code using "${clone}/02_rawdata/IBGE_Shapefile/IBGE_counties_centroids.dta", keep(match) nogen

* we create learnp variable here to calculate the weighted learning_poverty based on the population
*sum learning_poverty [aw=population_1014]
gen learnp = (learning_poverty) * population_1014/100
*It can be learning_p sometimes

putmata popw = population_1014, replace

hotspot learning_poverty learnp, xcoord(x_cent) ycoord(y_cent) radius(500) nei(1)


save "${clone}/04_outputs/Hotspot_weight_2013.dta", replace

export delimited  "${clone}/04_outputs/Hotspot_weight_2013.csv", replace

********************************
***** Map Hotspot *****
********************************
*Run 018_map_hotspot.R script