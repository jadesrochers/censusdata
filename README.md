## Census Data Pipeline
This library pull data direct from census and related sources regarding income/population data. The data is transformed using some shell/sed commands, and then streamed into MongoDB databases.
### How to use it
While all of the downloading, processing, and inserting into the database is done automatically, it does not create a database. You need a MongoDB instance running on localhost:27017. Also, the password/username for that db must be specified in mongouser.txt and mongopass.txt files in the top level of the project.  
If you have that set up correctly, then the data populating can be called using these scripts:
```bash
./Census_Scripts/INC_process.sh 
./Census_Scripts/POP_PST_process.sh
./Census_BEA_scripts/BEA_Process.sh
```
#### Changing the variables or database layout
Editing the .sh scripts would allow downloading data sets other than the ones I have selected. 
```bash
## This determines what raw data is being downloaded
curl -O https://www2.census.gov/library/publications/2011/compendia/usa-counties/zip/POP.zip
curl -O  https://www2.census.gov/library/publications/2011/compendia/usa-counties/zip/PST.zip
```
The sed files show my variable name translations. The Raw data uses variable codes from the census bureau, which I change to the full names so that I know what I am working with using these sed scripts.  
```bash
## To change the file editing, look to the headeredit_sed and geoidedit_sed files.
sed -r -i.back -f Census_Scripts/POP_headeredit_sed.txt Census_POP_2011/POP01.csv.[0-9]
sed -r -i.oldgeoids -f Census_Scripts/POP_geoidedit_sed.txt Census_POP_2011/POP01.csv.[0-9]
```
Then, the .sh scripts call the ./csv_todb.js script with the variables to be put in the database and which collection to put them in, which could also be edited.
```bash
## This could be edited or called directly if you wanted to put different data
## into the db than I am doing by default.
node csv_todb.js --keyvars "GEO_ID,Areaname" --db 'census_income_data' --collection 'income_summary' --vars 'Areaname,GEO_ID,Median_household_income_1979,Median_household_income_1989,Median_household_income_1999,Median_household_income_2009,Mean_household_income_2009' 'Census_INC_2011/INC01.csv.0'
```

### This grabs only a small amount of data overall
The US Census bureau has many, many more data sets than these. These same scripts should work for many of them, but would require meaningful modification becase I have not configured it to get all possible datasets, just a few I was looking at.
