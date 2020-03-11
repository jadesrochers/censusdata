## Good idea to first clear the mongodb database since this will 
# do formatting and all data adding, which may be incompatible with 
# data added in a different way
## use census_income_data
## db.income_brackets.deleteMany({})
## db.income_summary.deleteMany({})

# Change to the data processing dir for census, download 
# the relevant census data files
cd ../ 
curl -O https://www2.census.gov/library/publications/2011/compendia/usa-counties/zip/INC.zip

# unzip the downloads
unzip INC.zip -d Census_INC_2011

# Convert the xls files to csv
ssconvert -S Census_INC_2011/INC01.xls Census_INC_2011/INC01.csv
ssconvert -S Census_INC_2011/INC02.xls Census_INC_2011/INC02.csv
ssconvert -S Census_INC_2011/INC03.xls Census_INC_2011/INC03.csv

## Edit the headers and GEO_ID/Area_name for PIN files
sed -r -i.back -f Census_Scripts/INC_headeredit_sed.txt Census_INC_2011/INC0[0-3].csv.[0-9]
sed -r -i.oldgeoids -f Census_Scripts/INC_geoidedit_sed.txt Census_INC_2011/INC0[0-3].csv.[0-9]

# Get all the correct locations inserted using the two census source
node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_brackets' --vars 'GEO_ID,Area_name' 'Census_INC_2011/INC01.csv.0'
node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_summary' --vars 'GEO_ID,Area_name' 'Census_INC_2011/INC01.csv.0'

## Income bracket data additions
node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_brackets' --vars 'GEO_ID,Households_with_income_<10k_1979,Households_with_income_<10k_1989,Households_with_income_<10k_1999,Households_with_income_<10k_2009'  'Census_INC_2011/INC01.csv.0'

node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_brackets' --vars 'GEO_ID,Households_with_income_10-15k_1979,Households_with_income_10-15k_1989,Households_with_income_10-15k_1999,Households_with_income_10-15k_2009,Households_with_income_15-20k_1979,Households_with_income_15-20k_1989,Households_with_income_15-20k_1999,Households_with_income_15-20k_2009,Households_with_income_20-25k_1979,Households_with_income_20-25k_1989' 'Census_INC_2011/INC01.csv.1'

node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_brackets' --vars 'GEO_ID,Households_with_income_20-25k_1999,Households_with_income_20-25k_2009,Households_with_income_25-30k_1979,Households_with_income_25-30k_1989,Households_with_income_25-30k_1999,Households_with_income_25-30k_2009,Households_with_income_30-35k_1979,Households_with_income_30-35k_1989,Households_with_income_30-35k_1999,Households_with_income_30-35k_2009'  'Census_INC_2011/INC01.csv.2'

node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_brackets' --vars 'GEO_ID,Households_with_income_35-40k_1979,Households_with_income_35-40k_1989,Households_with_income_35-40k_1999,Households_with_income_35-40k_2009,Households_with_income_40-50k_1979,Households_with_income_40-50k_1989,Households_with_income_40-50k_1999,Households_with_income_40-45k_1989,Households_with_income_40-45k_1999,Households_with_income_40-45k_2009' 'Census_INC_2011/INC01.csv.3'

node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_brackets' --vars 'GEO_ID,Households_with_income_45-50k_1989,Households_with_income_45-50k_1999,Households_with_income_45-50k_2009,Households_with_income_50-75k_1979,Households_with_income_50-75k_1989,Households_with_income_50-75k_1999,Households_with_income_50-60k_1989,Households_with_income_50-60k_1999,Households_with_income_50-60k_2009,Households_with_income_60-75k_1989'  'Census_INC_2011/INC01.csv.4'

node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_brackets' --vars 'GEO_ID,Households_with_income_60-75k_1999,Households_with_income_60-75k_2009,Households_with_income_75k+_1979,Households_with_income_75k+_1989,Households_with_income_75k+_1999,Households_with_income_75-100k_1989,Households_with_income_75-100k_1999,Households_with_income_75-100k_2009,Households_with_income_100-125k_1989,Households_with_income_100-125k_1999'  'Census_INC_2011/INC01.csv.5'

node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_brackets' --vars 'GEO_ID,Households_with_income_100-125k_2009,Households_with_income_125-150k_1989,Households_with_income_125-150k_1999,Households_with_income_125-150k_2009,Households_with_income_150k+_1989,Households_with_income_150k+_1999,Households_with_income_150-200k_1999,Households_with_income_150-200k_2009,Households_with_income_200k+_1999,Households_with_income_200k+_2009'  'Census_INC_2011/INC01.csv.6'


## Income summary collection data
node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_summary' --vars 'GEO_ID,Median_household_income_1979,Median_household_income_1989,Median_household_income_1999,Median_household_income_2009,Mean_household_income_2009' 'Census_INC_2011/INC01.csv.0'

node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_summary' --vars 'GEO_ID,Median_family_income_1969,Median_family_income_1979,Median_family_income_1989,Median_family_income_1999,Median_family_income_2009,Mean_family_income_2009' 'Census_INC_2011/INC02.csv.0'

node csv_todb.js --keyvars "GEO_ID" --db 'census_income_data' --collection 'income_summary' --vars 'GEO_ID,Per_capita_income_1969,Per_capita_income_1979,Per_capita_income_1989,Per_capita_income_1999,Per_capita_income_2009'   'Census_INC_2011/INC02.csv.9'


