## Good idea to first clear the mongodb database since this will 
# do formatting and all data adding, which may be incompatible with 
# data added in a different way
## use bea_income_data
## db.personal_income.deleteMany({})

cd ../
curl -O https://www2.census.gov/library/publications/2011/compendia/usa-counties/zip/PEN.zip
curl -O https://www2.census.gov/library/publications/2011/compendia/usa-counties/zip/PIN.zip
curl -O https://apps.bea.gov/regional/histdata/releases/1118lapi/lapi1118-2.zip 
curl -O https://apps.bea.gov/regional/histdata/releases/1118lapi/lapi1118-3.zip 

# unzip the downloads
unzip PEN.zip -d Census_BEA_PEN_2011
unzip PIN.zip -d Census_BEA_PIN_2011
unzip lapi1118-2.zip -d BEA_CAINC1_2017
unzip lapi1118-3.zip -d BEA_CAINC4_2017

# Use sed to seaparate out the variables in the historical BEA data
sed -r -n '1{p;}; /[Pp]ersonal income \([Tt]housands/{p;}' BEA_CAINC1_2017/CAINC1__ALL_STATES_1969_2017.csv > BEA_CAINC1_2017/CAINC1_All_Personal_Income_1969_2017.csv
sed -r -n '1{p;}; /[Pp]er capita personal income/{p;}' BEA_CAINC1_2017/CAINC1__ALL_STATES_1969_2017.csv > BEA_CAINC1_2017/CAINC1_All_Percapita_Income_1969_2017.csv 
sed -r -n '1{p;}; /[Pp]opulation \(person/{p;}' BEA_CAINC1_2017/CAINC1__ALL_STATES_1969_2017.csv > BEA_CAINC1_2017/CAINC1_All_Population_1969_2017.csv

# Convert the xls files to csv
ssconvert -S Census_BEA_PEN_2011/PEN01.xls Census_BEA_PEN_2011/PEN01.csv
ssconvert -S Census_BEA_PIN_2011/PIN01.xls Census_BEA_PIN_2011/PIN01.csv

## Edit the headers and GEO_ID/Area_name for PIN files
sed -r -i.back -f Census_BEA_scripts/PIN_headeredit_sed.txt Census_BEA_PIN_2011/PIN01.csv.[0-9]
sed -r -i.oldgeoids -f Census_BEA_scripts/PIN_geoidedit_sed.txt Census_BEA_PIN_2011/PIN01.csv.[0-9]

## Edit the headers and GEO_ID/Area_name for PEN files 
sed -r -i.back -f Census_BEA_scripts/PEN_headeredit_sed.txt Census_BEA_PEN_2011/PEN01.csv.[0-9]
sed -r -i.oldgeoids -f Census_BEA_scripts/PEN_geoidedit_sed.txt Census_BEA_PEN_2011/PEN01.csv.[0-9]

## Edit headers and GEO_ID/Area_name for files direct from BEA
sed -r -i.back -f Census_BEA_scripts/BEA_population_headeredit_sed.txt BEA_CAINC1_2017/CAINC1_All_Population_1969_2017.csv
sed -r -i.back -f Census_BEA_scripts/BEA_percapita_headeredit_sed.txt BEA_CAINC1_2017/CAINC1_All_Percapita_Income_1969_2017.csv
sed -r -i.back -f Census_BEA_scripts/BEA_personal_income_headeredit_sed.txt BEA_CAINC1_2017/CAINC1_All_Personal_Income_1969_2017.csv
## Apply to the files with all data from country
sed -r -i.origgeoid -f Census_BEA_scripts/BEA_geoidedit_sed.txt BEA_CAINC1_2017/CAINC1_All_*csv

# Get all the correct locations inserted using the two census source
node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'GEO_ID,Area_name' 'Census_BEA_PEN_2011/PEN01.csv.0'
node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'GEO_ID,Area_name' 'Census_BEA_PIN_2011/PIN01.csv.0'
# The non census data may have different locations, so use that too
node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'GEO_ID,Area_name' 'BEA_CAINC1_2017/CAINC1_All_Personal_Income_1969_2017.csv'

# Then run all the data inserts based on GEO_ID, not Area_name, since the 
# GEO_ID is most likely to be unique
# Program used to be POP_PST_todb.js, now csv_todb.js if you need to 
# search for a previous usage

# Personal Income (sum of all income)
# node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'Personal_Income_1969,Personal_Income_1970,Personal_Income_1971,Personal_Income_1972,Personal_Income_1973,Personal_Income_1974,Personal_Income_1975,Personal_Income_1976,Personal_Income_1977,Personal_Income_1978'  'BEA_Personal_Income_PIN_SIC/PIN01_csv/PIN01.csv.0'
# node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars  'Personal_Income_1979,Personal_Income_1980,Personal_Income_1981,Personal_Income_1982,Personal_Income_1983,Personal_Income_1984,Personal_Income_1985,Personal_Income_1986,Personal_Income_1987,Personal_Income_1988'   'BEA_Personal_Income_PIN_SIC/PIN01_csv/PIN01.csv.1'
# node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'Personal_Income_1989,Personal_Income_1990,Personal_Income_1991,Personal_Income_1992,Personal_Income_1993,Personal_Income_1994,Personal_Income_1995,Personal_Income_1996,Personal_Income_1997,Personal_Income_1998'  'BEA_Personal_Income_PIN_SIC/PIN01_csv/PIN01.csv.2'
# Personal income from the newer PEN set
# node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'Personal_Income_2001,Personal_Income_2002,Personal_Income_2003,Personal_Income_2004,Personal_Income_2005,Personal_Income_2006,Personal_Income_2007,Personal_Income_Per_Capita_2001,Personal_Income_Per_Capita_2002,Personal_Income_Per_Capita_2003'   'BEA_Personal_Income_PEN_NAICS/PEN01_csv/PEN01.csv.0'


# Personal Income per capita (Avg income per individual), also includes 
# personal income total for 1999/2000 in the first file, they overlapped.  
# node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'Personal_Income_1999,Personal_Income_2000,Personal_Income_Per_Capita_1969,Personal_Income_Per_Capita_1970,Personal_Income_Per_Capita_1971,Personal_Income_Per_Capita_1972,Personal_Income_Per_Capita_1973,Personal_Income_Per_Capita_1974,Personal_Income_Per_Capita_1975,Personal_Income_Per_Capita_1976'   'BEA_Personal_Income_PIN_SIC/PIN01_csv/PIN01.csv.3'
# node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'Personal_Income_Per_Capita_1977,Personal_Income_Per_Capita_1978,Personal_Income_Per_Capita_1979,Personal_Income_Per_Capita_1980,Personal_Income_Per_Capita_1981,Personal_Income_Per_Capita_1982,Personal_Income_Per_Capita_1983,Personal_Income_Per_Capita_1984,Personal_Income_Per_Capita_1985,Personal_Income_Per_Capita_1986'   'BEA_Personal_Income_PIN_SIC/PIN01_csv/PIN01.csv.4'
# node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'Personal_Income_Per_Capita_1987,Personal_Income_Per_Capita_1988,Personal_Income_Per_Capita_1989,Personal_Income_Per_Capita_1990,Personal_Income_Per_Capita_1991,Personal_Income_Per_Capita_1992,Personal_Income_Per_Capita_1993,Personal_Income_Per_Capita_1994,Personal_Income_Per_Capita_1995,Personal_Income_Per_Capita_1996' 'BEA_Personal_Income_PIN_SIC/PIN01_csv/PIN01.csv.5'
# node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars  'Personal_Income_Per_Capita_1997,Personal_Income_Per_Capita_1998,Personal_Income_Per_Capita_1999,Personal_Income_Per_Capita_2000'  'BEA_Personal_Income_PIN_SIC/PIN01_csv/PIN01.csv.6'
# Income per capita from the newer PEN data set
# node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'Personal_Income_Per_Capita_2004,Personal_Income_Per_Capita_2005,Personal_Income_Per_Capita_2006,Personal_Income_Per_Capita_2007'  'BEA_Personal_Income_PEN_NAICS/PEN01_csv/PEN01.csv.1'


# Newest data available only direct from BEA, not through census
node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars 'GEO_ID,Personal_Income_Per_Capita_1969,Personal_Income_Per_Capita_1970,Personal_Income_Per_Capita_1971,Personal_Income_Per_Capita_1972,Personal_Income_Per_Capita_1973,Personal_Income_Per_Capita_1974,Personal_Income_Per_Capita_1975,Personal_Income_Per_Capita_1976,Personal_Income_Per_Capita_1977,Personal_Income_Per_Capita_1978,Personal_Income_Per_Capita_1979,Personal_Income_Per_Capita_1980,Personal_Income_Per_Capita_1981,Personal_Income_Per_Capita_1982,Personal_Income_Per_Capita_1983,Personal_Income_Per_Capita_1984,Personal_Income_Per_Capita_1985,Personal_Income_Per_Capita_1986,Personal_Income_Per_Capita_1987,Personal_Income_Per_Capita_1988,Personal_Income_Per_Capita_1989,Personal_Income_Per_Capita_1990,Personal_Income_Per_Capita_1991,Personal_Income_Per_Capita_1992,Personal_Income_Per_Capita_1993,Personal_Income_Per_Capita_1994,Personal_Income_Per_Capita_1995,Personal_Income_Per_Capita_1996,Personal_Income_Per_Capita_1997,Personal_Income_Per_Capita_1998,Personal_Income_Per_Capita_1999,Personal_Income_Per_Capita_2000,Personal_Income_Per_Capita_2001,Personal_Income_Per_Capita_2002,Personal_Income_Per_Capita_2003,Personal_Income_Per_Capita_2004,Personal_Income_Per_Capita_2005,Personal_Income_Per_Capita_2006,Personal_Income_Per_Capita_2007,Personal_Income_Per_Capita_2008,Personal_Income_Per_Capita_2009,Personal_Income_Per_Capita_2010,Personal_Income_Per_Capita_2011,Personal_Income_Per_Capita_2012,Personal_Income_Per_Capita_2013,Personal_Income_Per_Capita_2014,Personal_Income_Per_Capita_2015,Personal_Income_Per_Capita_2016,Personal_Income_Per_Capita_2017' 'BEA_CAINC1_2017/CAINC1_All_Percapita_Income_1969_2017.csv'

node csv_todb.js --keyvars "GEO_ID" --db 'bea_income_data' --collection 'personal_income' --vars  'GEO_ID,Personal_Income_1969,Personal_Income_1970,Personal_Income_1971,Personal_Income_1972,Personal_Income_1973,Personal_Income_1974,Personal_Income_1975,Personal_Income_1976,Personal_Income_1977,Personal_Income_1978,Personal_Income_1979,Personal_Income_1980,Personal_Income_1981,Personal_Income_1982,Personal_Income_1983,Personal_Income_1984,Personal_Income_1985,Personal_Income_1986,Personal_Income_1987,Personal_Income_1988,Personal_Income_1989,Personal_Income_1990,Personal_Income_1991,Personal_Income_1992,Personal_Income_1993,Personal_Income_1994,Personal_Income_1995,Personal_Income_1996,Personal_Income_1997,Personal_Income_1998,Personal_Income_1999,Personal_Income_2000,Personal_Income_2001,Personal_Income_2002,Personal_Income_2003,Personal_Income_2004,Personal_Income_2005,Personal_Income_2006,Personal_Income_2007,Personal_Income_2008,Personal_Income_2009,Personal_Income_2010,Personal_Income_2011,Personal_Income_2012,Personal_Income_2013,Personal_Income_2014,Personal_Income_2015,Personal_Income_2016,Personal_Income_2017' 'BEA_CAINC1_2017/CAINC1_All_Personal_Income_1969_2017.csv'

# Population estimates for census; because they were easier to get 
# through BEA than through the census, which did not have them for many 
# counties in the community survey
# I do this all in the Census POP_PST_process.sh script, but use some
# BEA data to fill gaps.
# node csv_todb.js --keyvars "GEO_ID" --db 'census_population_data' --collection 'population_estimates' --vars 'GEO_ID,Resident_total_population_estimate_2010,Resident_total_population_estimate_2011,Resident_total_population_estimate_2012,Resident_total_population_estimate_2013,Resident_total_population_estimate_2014,Resident_total_population_estimate_2015,Resident_total_population_estimate_2016,Resident_total_population_estimate_2017'  'bea_cainc4/CAINC_All_Population_1969_2017.csv' 'BEA_CAINC1_2017/CAINC1_All_Population_1969_2017.csv'
