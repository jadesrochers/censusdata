#!/bin/bash

# You can get multiple series, but it seems only 20 years of data at once, which is kinda shitty
# given that there are only 12 obs in a year for most of these - not exactly API breaking to do the full period of record

# Getting data from the api. This gets json data.
# curl -X POST -o testdata.json -L 'https://api.bls.gov/publicAPI/v2/timeseries/data/?registrationkey=525f29f0b0514e04aee57cd2458939ad&startyear=1950&endyear=1969' -H 'Content-Type: application/json' -d '{"seriesid":["LNU02300000"], "startyear":"1950", "endyear":"1969", "registrationkey":"525f29f0b0514e04aee57cd2458939ad" }'

# same request but get xlsx data.
## NOTE: Their example is wrong with this endpoint, use /data.xlsx/ and not /data/.xlsx
seriesid='LNU02300000'
# curl -X POST -o testdata.xlsx -L 'https://api.bls.gov/publicAPI/v2/timeseries/data.xlsx/?registrationkey=525f29f0b0514e04aee57cd2458939ad&startyear=1950&endyear=1969' -H 'Content-Type: application/json' -d '{"seriesid":["LNU02300000"], "startyear":"1950", "endyear":"1969", "registrationkey":"525f29f0b0514e04aee57cd2458939ad" }'
# xlsx2csv -a testdata.xlsx > testdata.csv
# sed -n -r '/^[12][0-9]{3}/,${p}' < testdata.csv | tac

echo '' > "${seriesid}.csv"

startyears=(1950 1970 1990 2010)
endyears=(1969 1989 2009 2022)

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


## Get the series defined above. Upgrade this to pass as an argument to improve.
# get_series_data 
