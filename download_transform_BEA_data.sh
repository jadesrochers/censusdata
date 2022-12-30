#!/bin/bash

Dataset=CAINC1
Region=NY
Years=All
Format=JSON
UserToken=74B6144A-CFBF-48F9-9A6E-F50213F7FA39

# Get available linecodes for a dataset
# This may (or may not) be specific to the Regional dataset
get_linecodes() {
    tablename="$1"
    local filename="tmp_BEA_linecodes.json"
    curl -X GET -o "$filename" -L "http://apps.bea.gov/api/data?UserID=${UserToken}&method=GetParameterValues&datasetname=Regional&ParameterName=LineCode&ResultFormat=${Format}" 
    linecodes=$(jq < tmp_BEA_linecodes.json | grep -C 1 -i "$tablename" | grep -i key | sed 's/"//g' | sed -r 's/[^0-9]*([0-9]+).*/\1/' | uniq)
    rm "$filename"
    printf '%s\n' "$linecodes"
}

get_data_and_metadata() {
    set -x
    tablename="$1"
    linecode="$2"
    local dl_filename="tmp_BEA_datameta_${tablename}_${linecode}.json"
    local csv_filename="dl_BEA_${tablename}_fulltable.csv"
    curl -X GET -o "${dl_filename}" -L "http://apps.bea.gov/api/data?UserID=74B6144A-CFBF-48F9-9A6E-F50213F7FA39&method=GetData&datasetname=Regional&GeoFips=${Region}&TableName=${tablename}&LineCode=${linecode}&Year=${Years}&ResultFormat=${Format}"
    jq -r '["GeoFips", "GeoName", "TimePeriod", .BEAAPI.Results.Data[0].Code], (.BEAAPI.Results.Data | sort_by(.GeoFips,.TimePeriod)[] | [.GeoFips, .GeoName, .TimePeriod, .DataValue]) | @csv' < "$dl_filename" > "$csv_filename"
    rm "$dl_filename"
    printf '%s' "$csv_filename"
    set +x
}

append_more_data() {
    tablename="$1"
    linecode="$2"
    base_csv="$3"
    local dl_filename="tmp_BEA_data_${tablename}_${linecode}.json"
    local csv_filename="dl_BEA_${tablename}_datatable.csv"
    local new_filename="dl_BEA_${tablename}_fulltable_${linecode}.csv"
    curl -X GET -o "${dl_filename}" -L "http://apps.bea.gov/api/data?UserID=${UserToken}&method=GetData&datasetname=Regional&GeoFips=${Region}&TableName=${tablename}&LineCode=${linecode}&Year=${Years}&ResultFormat=${Format}"
    jq -r '[.BEAAPI.Results.Data[0].Code], (.BEAAPI.Results.Data | sort_by(.GeoFips,.TimePeriod)[] | [.DataValue]) | @csv' < "$dl_filename" > "$csv_filename"
    paste -d ',' "$base_csv" "$csv_filename" > "$new_filename"
    rm "$dl_filename" "$csv_filename" "$base_csv"
    printf "%s" "$new_filename" 
}


# xlsx2csv -a testdata.xlsx > testdata.csv
# sed -n -r '/^[12][0-9]{3}/,${p}' < testdata.csv | tac

echo '' > "${seriesid}.csv"

years=ALL

get_series_data() {
    # for i in {0..${#startyears[@]}}; do
    blocks=${#startyears[@]}
    for (( i=0; i<blocks; i++ )); do
        printf 'Getting years: %s %s\ndata series: %s\n' "${startyears[i]}" "${endyears[i]}" "${seriesid}"
        curl -X POST -o dldata.xlsx -L "https://api.bls.gov/publicAPI/v2/timeseries/data.xlsx/?registrationkey=525f29f0b0514e04aee57cd2458939ad&startyear=${startyears[i]}&endyear=${endyears[i]}" -H 'Content-Type: application/json' -d "{\"seriesid\":[\"${seriesid}\"], \"startyear\":\"${startyears[$i]}\", \"endyear\":\"${endyears[$i]}\", \"registrationkey\":\"525f29f0b0514e04aee57cd2458939ad\" }"
        xlsx2csv -a dldata.xlsx > dldata.csv
        sed -n -r '/^[12][0-9]{3}/,${p}' < dldata.csv | tac >> "${seriesid}.csv"
	sleep 1;
    done
}

# Get the major top level data sets
curl -X GET -o dl_bea_datasetlist.json -L "http://apps.bea.gov/api/data?UserID=74B6144A-CFBF-48F9-9A6E-F50213F7FA39&method=getDataList&ResultFormat=JSON"
# Get the parameters that can be passed to one of those top level sets
curl -X GET -o dl_bea_dataset_parameters.json -L "http://apps.bea.gov/api/data?UserID=74B6144A-CFBF-48F9-9A6E-F50213F7FA39&method=getParameterList&datasetname=Regional&ResultFormat=JSON"

## Getting the specific arguments allowable to a parameter for a set; 
# because there are several arguments to any given set, be aware that
# arguments to one parameter may be valid only in combination with other args
curl -X GET -o dl_bea_dataset_Regional_LineCodes.json -L "http://apps.bea.gov/api/data?UserID=74B6144A-CFBF-48F9-9A6E-F50213F7FA39&method=GetParameterValues&datasetname=Regional&ParameterName=LineCode&ResultFormat=JSON"
# Get the specific tables available:
curl -X GET -o dl_bea_dataset_Regional_TableNames.json -L "http://apps.bea.gov/api/data?UserID=74B6144A-CFBF-48F9-9A6E-F50213F7FA39&method=GetParameterValues&datasetname=Regional&ParameterName=TableName&ResultFormat=JSON"

# Get nice pretty print of the result
jq -C < dl_bea_dataset_parameter_args.json


## Now get the data (only one field at a time, disappointing):
curl -X GET -o dl_bea_dataset_CAINC1.json -L "http://apps.bea.gov/api/data?UserID=74B6144A-CFBF-48F9-9A6E-F50213F7FA39&method=GetData&datasetname=Regional&GeoFips=NY&TableName=CAINC1&LineCode=1,2,3&Year=All&ResultFormat=JSON"
## Get a different field - checkout out what is feasible to get
curl -X GET -o dl_bea_dataset_CAINC1_92.json -L "http://apps.bea.gov/api/data?UserID=74B6144A-CFBF-48F9-9A6E-F50213F7FA39&method=GetData&datasetname=Regional&GeoFips=NY&TableName=CAINC1&LineCode=92&Year=All&ResultFormat=JSON"

## And transform JSON > csv so I can pull it into python
# Explained: This command makes a header row.
# Then, it gets the data in the Data array and sorts it, returning an array.
# Finally, it extracts data from that array and makes the rows.
jq -r '["GeoFips", "GeoName", "TimePeriod", .BEAAPI.Results.Data[0].Code], (.BEAAPI.Results.Data | sort_by(.GeoFips,.TimePeriod)[] | [.GeoFips, .GeoName, .TimePeriod, .DataValue]) | @csv' < dl_bea_dataset_CAINC1_pretty.json  > CAINC1_NY_LineCode1.csv


LineCodes=($(get_linecodes "$Dataset"))
n=0
for linecode in ${LineCodes[@]}: do
    local basefilename
    if n -eq 0; then
        basefilename=$(get_data_and_metadata "$Dataset" "$linecode")
    else
        append_more_data "$Dataset" "$linecode" "$basefilename"
        n=((n+1))
done
