﻿drop schema if exists "PH_datamodel" cascade;
create schema "PH_datamodel";

--------------------------------
-- 1: Create datamodel tables --
--------------------------------
/*
DROP TABLE "ph_source"."Indicators_3_hazards_new";
CREATE TABLE "ph_source"."Indicators_3_hazards_new" (
	NAME_Mun text,PCODE_Mun text,PCODE_Prov text,cs_sum numeric,cy_sum numeric,dr_sum numeric,eq7_sum numeric,fl_sum numeric,ls_sum numeric,ts_sum numeric
);
COPY "ph_source"."Indicators_3_hazards_new" FROM 'C:\Users\JannisV\Rode Kruis\CP data\Philippines Prototype data\Indicator data\hazard_new.csv' DELIMITER ',' HEADER CSV;
--select * from "ph_source"."Indicators_3_hazards_new"

DROP TABLE "ph_source"."Indicators_3_walltype";
CREATE TABLE "ph_source"."Indicators_3_walltype" (
	Muncode text, "Concrete/Brick/Wall" numeric,Wood numeric,"Half Concrete Hald Wood" numeric,"Galvanized Iron/Aluminum" numeric,"Bamboo/Sawali/Cogon/Nipa" numeric,Asbestos numeric,Glass numeric,"Makeshift/salvaged/improvised" numeric,Others	numeric,"No Wall" numeric,"Not reported" numeric
);
COPY "ph_source"."Indicators_3_walltype" FROM 'C:\Users\JannisV\Rode Kruis\CP data\Philippines Prototype data\Indicator data\Wall-Type_by-Municipality-Households.csv' DELIMITER ';' HEADER CSV;
--select * from "ph_source"."Indicators_3_walltype"

--OCHA predisaster indicators
--This uses new municipalities >> Fix it to the old system for now
UPDATE "ph_source"."Indicators_3_OCHA_predisaster"
SET "Mun_City Code" = regexp_replace(regexp_replace("Mun_City Code",'PH1845','PH0645'),'PH1846','PH0746')
;
*/

-------------------------------
-- 1.1: Boundary data tables --
-------------------------------

drop table if exists "PH_datamodel"."Geo_level4";
SELECT cast('PH' || case when ___pcode_1 < 100000000 then '0' else '' end || cast(___pcode_1 as text) as varchar) as pcode_level2
	, cast('PH' || case when ___pcode_2 < 100000000 then '0' else '' end || cast(___pcode_2 as text) as varchar) as pcode_level3
	, ___name_subm as name_submunicipality
	, cast('PH' || case when ___pcode_sub < 100000000 then '0' else '' end || cast(___pcode_sub as text) as varchar) as pcode_submunicipality
	, name_bar as name_level4
	, cast('PH' || case when ___barangay_ < 100000000 then '0' else '' end || cast(___barangay_ as text) as varchar) as pcode_level4
	, alt_pcodes
	, area / 1000000 as land_area
	, geom --t1.geom
INTO "PH_datamodel"."Geo_level4"
FROM "geo_source"."Geo_PH_level4"
--JOIN "geo_source"."Geo_PH_level4_mapshaper" t1 on t0.gid = t1.gid
;



/*
drop table if exists "PH_datamodel"."Geo_level3";
SELECT regexp_replace(regexp_replace(mun_code,'PH1845','PH0645'),'PH1846','PH0746') as pcode_level3
       ,mun_name as name_level3
       ,regexp_replace(regexp_replace(pro_code,'PH1845','PH0645'),'PH1846','PH0746') as pcode_level2
       ,t1.geom
INTO "PH_datamodel"."Geo_level3"
FROM "ph_source".phl_adm3_psa_pn_2016june t0
JOIN "ph_source".phl_adm3_psa_pn_2016june_mapshaper t1 on t0.gid = t1.gid
;*/


drop table if exists "PH_datamodel"."Geo_level3";
SELECT t0.name_mun as name_level3
	, cast('PH' || case when t0.pcode_mun = '99701000' then '099701000' else t0.pcode_mun end as varchar) as pcode_level3
	, t0.pcode_prov as pcode_level2
	, t1.geom
INTO "PH_datamodel"."Geo_level3"
FROM "geo_source"."Geo_PH_level3" t0
JOIN "geo_source"."Geo_PH_level3_mapshaper_smaller" t1 on t0.gid = t1.gid
--order by 2 desc
;

/*
drop table if exists "PH_datamodel"."Geo_level2";
SELECT regexp_replace(regexp_replace(pro_code,'PH1845','PH0645'),'PH1846','PH0746') as pcode_level2
	,pro_name as name_level2
	,reg_code as pcode_level1
	,t1.geom
INTO "PH_datamodel"."Geo_level2"
FROM "ph_source".phl_adm2_psa_pn_2016june t0
JOIN "ph_source".phl_adm2_psa_pn_2016june_mapshaper t1 on t0.gid = t1.gid
;*/

drop table if exists "PH_datamodel"."Geo_level2";
SELECT cast('PH' || t0.pcode_prov as varchar) as pcode_level2
	, regexp_replace(t0.name_prov,'District','District (Manila)') as name_level2
	, t0.pcode_reg as pcode_level1
	, t1.geom
INTO "PH_datamodel"."Geo_level2"
FROM "geo_source"."Geo_PH_level2" t0
JOIN "geo_source"."Geo_PH_level2_mapshaper" t1 on t0.gid = t1.gid
;

--test whether all pcodes join well: CHECK --> 41912 rows
/*
select * from (
select t1.pcode_level2
	, t1.name_level2
	, t2.pcode_level3
	, t2.name_level3
	, t3.pcode_level4
	, t3.name_level4
from "PH_datamodel"."Geo_level2" t1
full outer join "PH_datamodel"."Geo_level3" t2 		on t1.pcode_level2 = t2.pcode_level2
full outer join "PH_datamodel"."Geo_level4" t3		on t2.pcode_level3 = t3.pcode_level3
group by 1,2,3,4,5,6) aa
where pcode_level2 is null or pcode_level4 is null
order by 1,3,5
;
*/


------------------------------------------
-- 1.2: Transform Indicator data tables --
------------------------------------------

------------------
-- Level 4 data --
------------------

drop table if exists "PH_datamodel"."Indicators_4_population";
select cast('PH' || case when length(pcode_barangay) = 8 then '0' else '' end || pcode_barangay as varchar) as pcode_level4
	, population
into "PH_datamodel"."Indicators_4_population"
from "ph_source"."Indicators_4_population"
where pcode_barangay not in ('New','#N/A')
;

drop table if exists "PH_datamodel"."Indicators_4_traveltime";
select cast('PH' || case when pcode_barangay < 100000000 then '0' else '' end || pcode_barangay as varchar) as pcode_level4
	,traveltime
into "PH_datamodel"."Indicators_4_traveltime"
from "ph_source"."Indicators_4_traveltime_gdp"
;

drop table if exists "PH_datamodel"."Indicators_4_gdp";
select cast('PH' || case when pcode_barangay < 100000000 then '0' else '' end || pcode_barangay as varchar) as pcode_level4
	,gdp*1000 as gdp
into "PH_datamodel"."Indicators_4_gdp"
from "ph_source"."Indicators_4_traveltime_gdp"
;

drop table if exists "PH_datamodel"."Indicators_4_rural_urban";
select 'PH' || case when code < 100000000 then '0' else '' end || code as pcode_level4
	,rural_urban
into "PH_datamodel"."Indicators_4_rural_urban"
from "ph_source"."Indicators_4_rural_urban"
union all 
select 'PH' || case when code < 100000000 then '0' else '' end || code as pcode_level4
	,rural_urban
from "ph_source"."Indicators_4_rural_urban_city"
;


------------------
-- Level 3 data --
------------------

drop table if exists "PH_datamodel"."Indicators_3_poverty";
select 'PH' || case when psgc_muni < 100000000 then '0' else '' end || psgc_muni as pcode_level3
	,sum(case when pov_muni_measure = 'Incidence' then cast(replace(estimate,',','.') as numeric) end) / 100 as poverty_incidence
into "PH_datamodel"."Indicators_3_poverty"
from "ph_source"."Indicators_3_poverty"
where pov_muni_year = 2012 and estimate <> '-'
group by 1
order by 1
;

drop table if exists "PH_datamodel"."Indicators_3_hazards";
select 'PH' || case when pcode_mun = '99701000' then '099701000' else pcode_mun end as pcode_level3
	,cs_sum + cy_sum as cyclone_phys_exp 	/* Combine into one variable */
	,dr_sum as drought_phys_exp
	,eq7_sum as earthquake7_phys_exp
	,fl_sum as flood_phys_exp
--	,ls_sum as landslide_phys_exp 		/* Leave out for now (not in INFORM) */
	,ts_sum as tsunami_phys_exp
into "PH_datamodel"."Indicators_3_hazards"
from "ph_source"."Indicators_3_hazards_new"
--order by 1 desc
;

drop table if exists "PH_datamodel"."Indicators_3_hospitals";
select  'PH' || case when length(pcode_municipality) = 8 then '0' else '' end || pcode_municipality as pcode_level3
	, count(distinct facility) as nr_facilities
	, sum(dentist) as dentist			
	, sum(doctor) as doctor
	, sum(medical_technologist) as medical_technologist
	, sum(midwife) as midwife
	, sum(nurse) as nurse
	, sum(nutritionist_dietician) as nutritionist_dietician
	, sum(occupational_therapist) as occupational_therapist
	, sum(pharmacist) as pharmacist
	, sum(physical_therapist) as physical_therapist
	, sum(radiology_technologist) as radiology_technologist
	, sum(x_ray_technologist) as x_ray_technologist
	, sum(total) as nr_doctors
into "PH_datamodel"."Indicators_3_hospitals"
from "ph_source"."Indicators_3_hospitals" 
where facility <> 'TOTAL' or pcode_municipality in (select pcode_municipality from "ph_source"."Indicators_3_hospitals" group by pcode_municipality having count(*)=2)
group by 1
;

--hospital information from OCHA
drop table if exists "PH_datamodel"."Indicators_3_hospitals_OCHA";
select "Mun_City Code" as pcode_level3
	, "Barangay Health Station" as barangay_health_station
	, "Government Hospital" as gov_hospital
	, "Private Hospital" as private_hospital
	, "Rural Health Unit" as rural_health_unit
	, "Barangay Health Station" + "Government Hospital" + "Private Hospital" + "Rural Health Unit" as nr_health_facilities
INTO "PH_datamodel"."Indicators_3_hospitals_OCHA"
FROM "ph_source"."Indicators_3_OCHA_predisaster"
;



drop table if exists "PH_datamodel"."Indicators_3_Haiyan_3W";
select 'PH' || case when length(municipality_code) = 8 then '0' else '' end || municipality_code as pcode_level3
	,count(distinct organisation) as nr_organisations
	,count(distinct sector_cluster) as nr_sector_clusters
	,max(case when sector_cluster = 'CCCM' then 1 else 0 end) as CCCM_yn
	,max(case when sector_cluster = 'Early Recovery & Livelihoods' then 1 else 0 end) as early_recov_yn
	,max(case when sector_cluster = 'Education' then 1 else 0 end) as educ_yn
	,max(case when sector_cluster = 'Food Security and Agriculture' then 1 else 0 end) as food_yn
	,max(case when sector_cluster = 'Health' then 1 else 0 end) as health_yn
	,max(case when sector_cluster = 'Nutrition' then 1 else 0 end) as nutrition_yn
	,max(case when sector_cluster = 'Protection' then 1 else 0 end) as protection_yn
	,max(case when sector_cluster = 'Shelter' then 1 else 0 end) as shelter_yn
	,max(case when sector_cluster = 'WASH' then 1 else 0 end) as WASH_yn
	,sum(count) as nr_activities
into "PH_datamodel"."Indicators_3_Haiyan_3W"
from "ph_source"."Indicators_3_Haiyan_3W"
group by 1
;

--good governance index
drop table if exists "PH_datamodel"."Indicators_3_governance";
SELECT 'PH' || case when length(mun_code) = 8 then '0' else '' end || mun_code as pcode_level3
	, max(case when indicator = 'GOOD GOVERNANCE INDEX' then cast(value_2008 as numeric) end) as good_governance_index
	, max(case when indicator = 'Income Index' then value_2008 end) as income_index
	, max(case when indicator = 'Expenditure Index' then value_2008 end) as expenditure_index
	, max(case when indicator = 'Total Per Capita Income Index' then value_2008 end) as per_cap_inc_index
	, max(case when indicator = 'Total Per Capita Income from Local Sources Index' then value_2008 end) as per_cap_inc_local_sources_index
	, max(case when indicator = 'Per Capita Expenditure on Education, Culture Sports/Manpower Development Index' then value_2008 end) as exp_educ_index
	, max(case when indicator = 'Per Capita Expenditure on Health, Nutrition and Population Control Index' then value_2008 end) as exp_health_index
	, max(case when indicator = 'Per Capita Expenditure on Economic Services Index' then value_2008 end) as exp_econ_index
INTO "PH_datamodel"."Indicators_3_governance"
FROM "ph_source"."Indicators_3_governance"
WHERE value_2008 not in ('became a city','no population data')
group by 1
--order by 2 desc
;

--government characteristics of municipalities and cities
drop table if exists "PH_datamodel"."Indicators_3_mun_characteristics";
SELECT 'PH' || case when pcode < 100000000 then '0' else '' end || pcode as pcode_level3
	,case when income_class = '-' then null else cast(substr(income_class,1,1) as int) end as income_class
	,cast(land_area_2007_ha as numeric) / 100 as land_area_2007
	,cast(voters_2010 as numeric) as voters_2010
	,'Municipality' as mun_city
INTO "PH_datamodel"."Indicators_3_mun_characteristics"
FROM "ph_source"."Indicators_3_income_class"
union all
SELECT 'PH' || case when pcode < 100000000 then '0' else '' end || pcode as pcode_level3
	,case when income_class = '-' then null when income_class = 'Special' then 1 else cast(substr(income_class,1,1) as int) end as income_class
	,cast(land_area_2007_ha as numeric) / 100 as land_area_2007
	,cast(voters_2010 as numeric) as voters_2010
	,'City' as mun_city
FROM "ph_source"."Indicators_3_income_class_city"
;

--walltype
drop table if exists "PH_datamodel"."Indicators_3_walltype";
with total as (
select Muncode
	,"Concrete/Brick/Wall" + wood+ "Half Concrete Hald Wood"+ "Galvanized Iron/Aluminum"+ "Bamboo/Sawali/Cogon/Nipa"
		+ asbestos+ glass+ "Makeshift/salvaged/improvised"+ others+ "No Wall"+ "Not reported" as total
FROM "ph_source"."Indicators_3_walltype"
)
SELECT t0.Muncode as pcode_level3
	, round("Concrete/Brick/Wall" / total,3) as concrete_or_brick
	, round( wood / total,3)  as wood
	, round( "Half Concrete Hald Wood" / total,3)  as concrete_and_wood
	, round( "Galvanized Iron/Aluminum" / total,3)  as iron_aluminium
	, round( "Bamboo/Sawali/Cogon/Nipa" / total,3)  as bamboo_sawali_cogon_nipa
	, round( asbestos / total,3)  as asbestos
	, round( glass / total,3)  as glass
	, round( "Makeshift/salvaged/improvised" / total,3)  as makeshift
	, round( others / total,3)  as other
	, round( "No Wall" / total,3)  as no_wall
	, round( "Not reported" / total,3)  as not_reported
INTO "PH_datamodel"."Indicators_3_walltype"
FROM "ph_source"."Indicators_3_walltype" t0
LEFT JOIN total on t0.Muncode = total.Muncode
;



--Pantawid (4P) program for poor people. (Is actually by family, which is not per se the same as household.)
drop table if exists "PH_datamodel"."Indicators_3_Pantawid";
select "Mun_City Code" as pcode_level3
	,case when "Both Sexes" = 0 then null else cast("Pantawid Beneficiary" as float) / cast("Both Sexes" as float) end as Pantawid_perc
INTO "PH_datamodel"."Indicators_3_Pantawid"
FROM "ph_source"."Indicators_3_OCHA_predisaster"
order by 1
;



--rooftype
drop table if exists "PH_datamodel"."Indicators_3_rooftype";
with total as (
select "Mun_City Code" as pcode_level3 
	,"R Galvanized Iron/Aluminum" + "R Tile Concrete" + "R Half galvanized/half concrete" + 
       "R Wood" + "R Cogon/Nipa/Anahaw" + case when trim("R Asbestos") = '' then 0 else cast(trim("R Asbestos") as numeric) end + "R Makeshift/improvised/salvaged" + 
       "R Other" + "R Not reported" as total
FROM "ph_source"."Indicators_3_OCHA_predisaster"
)
SELECT t0."Mun_City Code" as pcode_level3
	, round( cast("R Galvanized Iron/Aluminum" / total as numeric),3) as galv_iron_aluminium
	, round( cast("R Tile Concrete" / total as numeric),3)  as tile_concrete
	, round( cast("R Half galvanized/half concrete" / total as numeric),3)  as galv_and_concrete
	, round( cast("R Wood" / total as numeric),3)  as wood
	, round( cast("R Cogon/Nipa/Anahaw" / total as numeric),3)  as cogon_nipa_anahaw
	, round( cast(case when trim("R Asbestos") = '' then 0 else cast(trim("R Asbestos") as numeric) end / total as numeric),3)  as asbestos
	, round( cast("R Makeshift/improvised/salvaged" / total as numeric),3)  as makeshift
	, round( cast("R Other" / total as numeric),3)  as other
	, round( cast("R Not reported" / total as numeric),3)  as not_reported
INTO "PH_datamodel"."Indicators_3_rooftype"
FROM "ph_source"."Indicators_3_OCHA_predisaster" t0
LEFT JOIN total on t0."Mun_City Code" = total.pcode_level3
;

/*
SELECT index, "Region", "Province", "Mun_City Code", "Inter-Level", 
       "Municipal_City", "Group", "Age Group", "Both Sexes", "Female", 
       "Male", "Barangay Health Station", "Government Hospital", "Private Hospital", 
       "Rural Health Unit", "Number of Barangay", "Number of Households", 
       "Housing Tenure: Owned/being amortized", "Housing Tenure: Rented", 
       "Housing Tenure: Rent-free with consent of owner", "Housing Tenure: Rent-free without consent of owner", 
       "Housing Tenure: Not Applicable", "Faucet", "Tubed/Pipe", "Well", 
       "Natural", "Bottled Water/Peddler", "Water Sealed", "Closed pit", 
       "Open Pit", "none", "Number of Highschools", "Number of Elementary Schools", 
       "Kinder Male", "Grade 1 Male", "Grade 2 Male", "Grade 3 Male", 
       "Grade 4 Male", "Grade 5 Male", "Grade 6 Male", "ELEM SPED NG Male", 
       "Grade 7 Male", "Grade 8 Male", "Grade 9 Male", "Grade 10 Male", 
       "Grade 11 Male", "Grade 12 Male", "HS SPED NG Male", "No. Evac. Center", 
       "R Galvanized Iron/Aluminum", "R Tile Concrete", "R Half galvanized/half concrete", 
       "R Wood", "R Cogon/Nipa/Anahaw", "R Asbestos", "R Makeshift/improvised/salvaged", 
       "R Other", "R Not reported", "W Concrete/Brick/Wall", "W Wood", 
       "W Half Concrete Hald Wood", "W Galvanized Iron/Aluminum", "W Bamboo/Sawali/Cogon/Nipa", 
       "W Asbestos", "W Glass", "W Makeshift/salvaged/improvised", "W Others", 
       "W No Wall", "W Not reported", "Point X", "Point Y", "Pantawid Beneficiary"
FROM "ph_source"."Indicators_3_OCHA_predisaster"
*/



------------------
-- Level 2 data --
------------------


drop table if exists "PH_datamodel"."Indicators_2_HDI";
select 'PH' || case when coalesce(t2.pcode2,province_code) < 100000000 then '0' else '' end || coalesce(t2.pcode2,province_code) as pcode_level2
	,cast(replace(hdi_2012,',','.') as numeric)		as hdi
	,cast(replace(life_exp_index,',','.') as numeric) 	as life_exp_index
	,cast(replace(educ_index,',','.') as numeric) 		as educ_index
	,cast(replace(income_index,',','.') as numeric) 	as income_index
	,cast(replace(life_expectancy,',','.') as numeric) 	as life_expectancy
	,cast(replace(years_schooling,',','.') as numeric) 	as years_schooling
	,cast(replace(expected_years_schooling,',','.') as numeric) as expected_years_schooling
	,per_capita_income
into "PH_datamodel"."Indicators_2_HDI"
from "ph_source"."Indicators_2_HDI" t1
left join "ph_source"."Aux_Manila_districts" t2
	on cast(province_code as int) = t2.pcode1
;

-----------------------------------------------
-- 1.3: Create one Indicator table per level--
-----------------------------------------------

-- DO THREE THINGS IN THIS STEP 
-- 1. Join all indicators of the same level together in one table per level
-- 2. Calculated derived metrics such as population_density
-- 2. Only keep variables that will continue to the dashboard
-- 3. Aggregate such that the level3-table also contains level4-aggregates, etc.

--Combine all level 4 data in one table
drop table if exists "PH_datamodel"."Indicators_4_TOTAL";
select t0.pcode_level4 as pcode
	,t0.pcode_level3 as pcode_parent
	,t1.population
	,round(t0.land_area,1) as land_area
	,round(t1.population / t0.land_area,1) as pop_density
	--,round(case when t1.population = 0 then null else t2.gdp / t1.population end,1) as gdp_per_capita
	,round(t3.traveltime,1) as traveltime
	--,case when t4.rural_urban = 'Urban' then 1 else 0 end as barangay_urban
	--ADD HERE WHICH NEW VARIABLES TO INCLUDE FROM NEW TABLE
into "PH_datamodel"."Indicators_4_TOTAL"
from "PH_datamodel"."Geo_level4" t0
left join "PH_datamodel"."Indicators_4_population" 	t1	on t0.pcode_level4 = t1.pcode_level4
left join "PH_datamodel"."Indicators_4_gdp" 		t2	on t0.pcode_level4 = t2.pcode_level4
left join "PH_datamodel"."Indicators_4_traveltime" 	t3	on t0.pcode_level4 = t3.pcode_level4
left join "PH_datamodel"."Indicators_4_rural_urban" 	t4	on t0.pcode_level4 = t4.pcode_level4
--ADD TABLE WITH NEW VARIABLES HERE (IT SHOULD BE LEVEL3 ALREADY) 
;

--Combine all level 3 data in one table
drop table if exists "PH_datamodel"."Indicators_3_TOTAL";
select t0.pcode_level3 as pcode
	,t0.pcode_level2 as pcode_parent
	,population,round(land_area,1) as land_area,round(pop_density,1) as pop_density,/*round(gdp_per_capita,1) as gdp_per_capita,*/round(traveltime,1) as traveltime
	,round(t1.poverty_incidence,3) as poverty_incidence
	,round(t2.flood_phys_exp / population,3) as flood_phys_exp
		,round(cyclone_phys_exp / population,3) as cyclone_phys_exp
		,round(earthquake7_phys_exp / population,3) as earthquake7_phys_exp
		,round(tsunami_phys_exp / population,3) as tsunami_phys_exp
		,round(drought_phys_exp / population,3) as drought_phys_exp
--	,t3.nr_facilities, nr_doctors
	,round(t5.good_governance_index,1) as good_governance_index
	,round(t6.income_class,1) as income_class
	,round(t7.concrete_or_brick+concrete_and_wood,3) as perc_wall_partly_concrete
	,round(t8.tile_concrete+galv_and_concrete+galv_iron_aluminium,3) as perc_roof_concrete_alu_iron
	,round(cast(t9.pantawid_perc as numeric),3) as pantawid_perc
	,t10.nr_health_facilities
	,case when level4.population/10000 = 0 then null else cast(t10.nr_health_facilities as float)/ (cast(level4.population as float) / 10000) end as health_density
	--ADD HERE WHICH NEW VARIABLES TO INCLUDE FROM NEW TABLE
into "PH_datamodel"."Indicators_3_TOTAL"
from "PH_datamodel"."Geo_level3" 				t0
left join (
	select pcode_parent
		,sum(population) as population
		,sum(land_area) as land_area
		,sum(pop_density * land_area) / sum(land_area) as pop_density
		--,sum(gdp_per_capita * population) / sum(population) as gdp_per_capita
		,sum(traveltime*population) / sum(population) as traveltime
	from "PH_datamodel"."Indicators_4_TOTAL"
	group by 1) 						level4	on t0.pcode_level3 = level4.pcode_parent
left join "PH_datamodel"."Indicators_3_poverty" 		t1	on t0.pcode_level3 = t1.pcode_level3
left join "PH_datamodel"."Indicators_3_hazards" 		t2	on t0.pcode_level3 = t2.pcode_level3
--left join "PH_datamodel"."Indicators_3_hospitals" 		t3	on t0.pcode_level3 = t3.pcode_level3
--left join "PH_datamodel"."Indicators_3_Haiyan_3W" 		t4	on t0.pcode_level3 = t4.pcode_level3
left join "PH_datamodel"."Indicators_3_governance" 		t5	on t0.pcode_level3 = t5.pcode_level3
left join "PH_datamodel"."Indicators_3_mun_characteristics" 	t6	on t0.pcode_level3 = t6.pcode_level3
left join "PH_datamodel"."Indicators_3_walltype" 		t7	on t0.pcode_level3 = t7.pcode_level3
left join "PH_datamodel"."Indicators_3_rooftype" 		t8	on t0.pcode_level3 = t8.pcode_level3
left join "PH_datamodel"."Indicators_3_Pantawid" 		t9	on t0.pcode_level3 = t9.pcode_level3
left join "PH_datamodel"."Indicators_3_hospitals_OCHA" 		t10	on t0.pcode_level3 = t10.pcode_level3
--ADD TABLE WITH NEW VARIABLES HERE (IT SHOULD BE LEVEL3 ALREADY) 
;

drop table if exists "PH_datamodel"."Indicators_2_TOTAL"; 
select t0.pcode_level2 as pcode
	,t1.hdi
	,level3.poverty_incidence,flood_phys_exp,cyclone_phys_exp,earthquake7_phys_exp,tsunami_phys_exp,drought_phys_exp,good_governance_index,income_class
		,perc_wall_partly_concrete,perc_roof_concrete_alu_iron,pantawid_perc
		,nr_health_facilities,health_density
		,population,land_area,pop_density,traveltime
into "PH_datamodel"."Indicators_2_TOTAL"
from "PH_datamodel"."Geo_level2" t0 
left join (
	select pcode_parent
		,sum(population) as population
		,round(sum(land_area),1) as land_area
		,round(sum(pop_density * land_area) / sum(land_area),1) as pop_density
		--,round(sum(gdp_per_capita * population) / sum(population),1) as gdp_per_capita
		,round(sum(traveltime*population) / sum(population),1) as traveltime
		,round(sum(poverty_incidence*population) / sum(population),3) as poverty_incidence
		,round(sum(population*flood_phys_exp) / sum(population),3) as flood_phys_exp
		,round(sum(population*cyclone_phys_exp)  / sum(population),3) as cyclone_phys_exp
		,round(sum(population*earthquake7_phys_exp)  / sum(population),3) as earthquake7_phys_exp
		,round(sum(population*tsunami_phys_exp)  / sum(population),3) as tsunami_phys_exp
		,round(sum(population*drought_phys_exp)  / sum(population),3) as drought_phys_exp
--		,sum(nr_facilities) as nr_facilities
--		,sum(nr_doctors) as nr_doctors
		,round(sum(population*good_governance_index)  / sum(population),1) as good_governance_index
		,round(sum(population*income_class)  / sum(population),1) as income_class
		,round(sum(population*perc_wall_partly_concrete)  / sum(population),3) as perc_wall_partly_concrete
		,round(sum(population*perc_roof_concrete_alu_iron)  / sum(population),3) as perc_roof_concrete_alu_iron
		,round(sum(population*pantawid_perc)  / sum(population),3) as pantawid_perc
		,sum(nr_health_facilities) as nr_health_facilities
		,sum(health_density * population) / sum(population) as health_density
	from "PH_datamodel"."Indicators_3_TOTAL"
	group by 1) 				level3	on t0.pcode_level2 = level3.pcode_parent
left join "PH_datamodel"."Indicators_2_HDI" 	t1	on t0.pcode_level2 = t1.pcode_level2
;


-------------------------------
-- 1.4: Create detail tables --
-------------------------------

drop table if exists "PH_datamodel"."Detail_3_Haiyan_3W";
select 'PH' || case when length(municipality_code) = 8 then '0' else '' end || municipality_code as pcode_level3
	,organisation
	,sector_cluster
	,activity
	,count as nr
into "PH_datamodel"."Detail_3_Haiyan_3W"
from "ph_source"."Indicators_3_Haiyan_3W"
;

drop table if exists "PH_datamodel"."Detail_3_hospitals";
select 'PH' || case when length(pcode_municipality) = 8 then '0' else '' end || pcode_municipality as pcode_level3
	, facility
	, sum(dentist) as dentist			
	, sum(doctor) as doctor
	, sum(medical_technologist) as medical_technologist
	, sum(midwife) as midwife
	, sum(nurse) as nurse
	, sum(nutritionist_dietician) as nutritionist_dietician
	, sum(occupational_therapist) as occupational_therapist
	, sum(pharmacist) as pharmacist
	, sum(physical_therapist) as physical_therapist
	, sum(radiology_technologist) as radiology_technologist
	, sum(x_ray_technologist) as x_ray_technologist
	, sum(total) as total
into "PH_datamodel"."Detail_3_hospitals"
from "ph_source"."Indicators_3_hospitals" 
where facility <> 'TOTAL' or pcode_municipality in (select pcode_municipality from "ph_source"."Indicators_3_hospitals" group by pcode_municipality having count(*)=2)
group by 1,2
--order by 1,2
;
















