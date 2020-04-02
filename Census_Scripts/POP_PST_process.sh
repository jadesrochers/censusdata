## Good idea to first clear the mongodb database since this will 
# do formatting and all data adding, which may be incompatible with 
# data added in a different way
## use census_population_data
## db.population_estimates.deleteMany({})
## db.population_totals.deleteMany({})

# Change to the data processing dir for census, download 
# the relevant census data files
cd ../

curl -O https://www2.census.gov/library/publications/2011/compendia/usa-counties/zip/POP.zip
curl -O  https://www2.census.gov/library/publications/2011/compendia/usa-counties/zip/PST.zip

# remove existing files
rm Census_POP_2011/*
rm Census_PST_2011/*
rm Census_INC_2011/*

# unzip the downloads
unzip POP.zip -d Census_POP_2011
unzip PST.zip -d Census_PST_2011
unzip INC.zip -d Census_INC_2011

# Convert the xls files to csv
ssconvert -S Census_POP_2011/POP01.xls Census_POP_2011/POP01.csv
ssconvert -S Census_PST_2011/PST01.xls Census_PST_2011/PST01.csv
ssconvert -S Census_INC_2011/INC01.xls Census_INC_2011/INC01.csv
ssconvert -S Census_INC_2011/INC02.xls Census_INC_2011/INC02.csv
ssconvert -S Census_INC_2011/INC03.xls Census_INC_2011/INC03.csv

## Edit the headers and GEO_ID/Area_name for PIN files
sed -r -i.back -f Census_Scripts/POP_headeredit_sed.txt Census_POP_2011/POP01.csv.[0-9]
sed -r -i.oldgeoids -f Census_Scripts/POP_geoidedit_sed.txt Census_POP_2011/POP01.csv.[0-9]

## Edit the headers and GEO_ID/Area_name for PEN files 
sed -r -i.back -f Census_Scripts/PST_headeredit_sed.txt Census_PST_2011/PST01.csv.[0-9]
sed -r -i.oldgeoids -f Census_Scripts/PST_geoidedit_sed.txt Census_PST_2011/PST01.csv.[0-9]


# Get all the correct locations inserted using the two census source
node csv_todb.js -p 27017 --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_totals' --vars 'GEO_ID,Area_name' 'Census_POP_2011/POP01.csv.0'
node csv_todb.js -p 27017 --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_estimates' --vars 'GEO_ID,Area_name' 'Census_PST_2011/PST01.csv.0'
node csv_todb.js -p 27017 --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_estimates' --vars 'GEO_ID,Area_name' 'Census_BEA_PIN_2011/PIN01.csv.0'



#### Handle income bracket and summary data.
rm Census_INC_2011/*

curl -O  https://www2.census.gov/library/publications/2011/compendia/usa-counties/zip/INC.zip

# unzip, convert xls to csv
unzip INC.zip -d Census_INC_2011

ssconvert -S Census_INC_2011/INC01.xls Census_INC_2011/INC01.csv
ssconvert -S Census_INC_2011/INC02.xls Census_INC_2011/INC02.csv
ssconvert -S Census_INC_2011/INC03.xls Census_INC_2011/INC03.csv


## Edit the headers and GEO_ID/Area_name for INC files
sed -r -i.back -f Census_Scripts/INC_headeredit_sed.txt Census_INC_2011/INC0[123].csv.[0-9]
sed -r -i.oldgeoids -f Census_Scripts/INC_geoidedit_sed.txt Census_INC_2011/INC0[123].csv.[0-9]

# Insert locations for the income range and summary data
## Sometimes have to run these x2 for some reason to get stragglers
node csv_todb.js -p 27017 --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_brackets' --vars 'GEO_ID,Area_name' 'Census_INC_2011/INC01.csv.0'
node csv_todb.js -p 27017 --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_summary' --vars 'GEO_ID,Area_name' 'Census_INC_2011/INC01.csv.0'

# First the income summary data
node csv_todb.js -p 27017 --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_summary' --vars 'Areaname,GEO_ID,Median_household_income_1979,Median_household_income_1989,Median_household_income_1999,Median_household_income_2009,Mean_household_income_2009' 'Census_INC_2011/INC01.csv.0'
node csv_todb.js -p 27017 --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_summary' --vars 'Areaname,GEO_ID,Median_family_income_1969,Median_family_income_1979,Median_family_income_1989,Median_family_income_1999,Median_family_income_2009,Mean_family_income_2009' 'Census_INC_2011/INC02.csv.0'
node csv_todb.js -p 27017 --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_summary' --vars         'Areaname,GEO_ID,Per_capita_income_1969,Per_capita_income_1979,Per_capita_income_1989,Per_capita_income_1999,Per_capita_income_2009'   'Census_INC_2011/INC02.csv.9'

# And now the bracket data
node csv_todb.js -p 27017 --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_brackets' --vars     'GEO_ID,Areaname,Households_with_incomelessthan_10k_1979,Households_with_incomelessthan_10k_1989,Households_with_incomelessthan_10k_1999,Households_with_incomelessthan_10k_2009'  'Census_INC_2011/INC01.csv.0'

node csv_todb.js -p 27017 --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_brackets' --vars   'Areaname,GEO_ID,Households_with_income_10to15k_1979,Households_with_income_10to15k_1989,Households_with_income_10to15k_1999,Households_with_income_10to15k_2009,Households_with_income_15to20k_1979,Households_with_income_15to20k_1989,Households_with_income_15to20k_1999,Households_with_income_15to20k_2009,Households_with_income_20to25k_1979,Households_with_income_20to25k_1989' 'Census_INC_2011/INC01.csv.1'

node csv_todb.js -p 27017 --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_brackets' --vars     'Areaname,GEO_ID,Households_with_income_20to25k_1999,Households_with_income_20to25k_2009,Households_with_income_25to30k_1979,Households_with_income_25to30k_1989,Households_with_income_25to30k_1999,Households_with_income_25to30k_2009,Households_with_income_30to35k_1979,Households_with_income_30to35k_1989,Households_with_income_30to35k_1999,Households_with_income_30to35k_2009'  'Census_INC_2011/INC01.csv.2'

node csv_todb.js -p 27017 --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_brackets' --vars     'Areaname,GEO_ID,Households_with_income_35to40k_1979,Households_with_income_35to40k_1989,Households_with_income_35to40k_1999,Households_with_income_35to40k_2009,Households_with_income_40to50k_1979,Households_with_income_40to50k_1989,Households_with_income_40to50k_1999,Households_with_income_40to45k_1989,Households_with_income_40to45k_1999,Households_with_income_40to45k_2009' 'Census_INC_2011/INC01.csv.3'

node csv_todb.js -p 27017 --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_brackets' --vars      'Areaname,GEO_ID,Households_with_income_45to50k_1989,Households_with_income_45to50k_1999,Households_with_income_45to50k_2009,Households_with_income_50to75k_1979,Households_with_income_50to75k_1989,Households_with_income_50to75k_1999,Households_with_income_50to60k_1989,Households_with_income_50to60k_1999,Households_with_income_50to60k_2009,Households_with_income_60to75k_1989' 'Census_INC_2011/INC01.csv.4'

node csv_todb.js -p 27017 --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_brackets' --vars       'Areaname,GEO_ID,Households_with_income_60to75k_1999,Households_with_income_60to75k_2009,Households_with_incomegreaterthan_75k_1979,Households_with_incomegreaterthan_75k_1989,Households_with_incomegreaterthan_75k_1999,Households_with_income_75to100k_1989,Households_with_income_75to100k_1999,Households_with_income_75to100k_2009,Households_with_income_100to125k_1989,Households_with_income_100to125k_1999'  'Census_INC_2011/INC01.csv.5'

node csv_todb.js --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_brackets' --vars      'Areaname,GEO_ID,Households_with_income_100to125k_2009,Households_with_income_125to150k_1989,Households_with_income_125to150k_1999,Households_with_income_125to150k_2009,Households_with_incomegreaterthan_150k_1989,Households_with_incomegreaterthan_150k_1999,Households_with_income_150to200k_1999,Households_with_income_150to200k_2009,Households_with_incomegreaterthan_200k_1999,Households_with_incomegreaterthan_200k_2009'  'Census_INC_2011/INC01.csv.6'

#### End of income bracket and summary data section


## Insert the population totals data from POP data set.
# this has the actual census data for a number of decades
node csv_todb.js --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_totals' --vars 'GEO_ID,Resident_population_complete_count_1930,Resident_population_complete_count_1940,Resident_population_complete_count_1950,Resident_population_complete_count_1960,Resident_population_complete_count_1970,Resident_population_complete_count_1980,Resident_population_complete_count_1990,Resident_population_complete_count_2000,Resident_population_complete_count_2010,Resident_population_revised_1970'  'Census_POP_2011/POP01.csv.0'
node csv_todb.js --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_totals' --vars 'GEO_ID,Resident_population_revised_1980,Resident_population_revised_1990'  'Census_POP_2011/POP01.csv.1'

## Insert population data estimates from PST data set.
# also, add data from the BEA that has more up to date estimates
node csv_todb.js --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_estimates' --vars 'GEO_ID,Resident_total_population_estimate_1971,Resident_total_population_estimate_1972,Resident_total_population_estimate_1973,Resident_total_population_estimate_1974,Resident_total_population_estimate_1975,Resident_total_population_estimate_1976,Resident_total_population_estimate_1977,Resident_total_population_estimate_1978,Resident_total_population_estimate_1979,Resident_total_population_estimate_1981'  'Census_PST_2011/PST01.csv.0'

node csv_todb.js --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_estimates' --vars 'GEO_ID,Resident_total_population_estimate_1982,Resident_total_population_estimate_1983,Resident_total_population_estimate_1984,Resident_total_population_estimate_1985,Resident_total_population_estimate_1986,Resident_total_population_estimate_1987,Resident_total_population_estimate_1988,Resident_total_population_estimate_1989,Resident_total_population_estimate_1990'  'Census_PST_2011/PST01.csv.1'

node csv_todb.js --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_estimates' --vars 'GEO_ID,Resident_total_population_estimate_1991,Resident_total_population_estimate_1992,Resident_total_population_estimate_1993,Resident_total_population_estimate_1994,Resident_total_population_estimate_1995,Resident_total_population_estimate_1996,Resident_total_population_estimate_1997,Resident_total_population_estimate_1998,Resident_total_population_estimate_1999'  'Census_PST_2011/PST01.csv.2'

node csv_todb.js --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_estimates' --vars 'GEO_ID,Resident_total_population_estimate_2000,Resident_total_population_estimate_2001,Resident_total_population_estimate_2002,Resident_total_population_estimate_2003,Resident_total_population_estimate_2004,Resident_total_population_estimate_2005,Resident_total_population_estimate_2006,Resident_total_population_estimate_2007,Resident_total_population_estimate_2008,Resident_total_population_estimate_2009'  'Census_PST_2011/PST01.csv.3'

node csv_todb.js --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_estimates' --vars 'GEO_ID,Area_name,Resident_total_population_estimate_1969,Resident_total_population_estimate_1970,Resident_total_population_estimate_1980,Resident_total_population_estimate_2010,Resident_total_population_estimate_2011,Resident_total_population_estimate_2012,Resident_total_population_estimate_2013,Resident_total_population_estimate_2014,Resident_total_population_estimate_2015,Resident_total_population_estimate_2016,Resident_total_population_estimate_2017' 'BEA_CAINC1_2017/CAINC1_All_Population_1969_2017.csv'

