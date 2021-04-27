#!/bin/sh
#
#

#QUERY_HASH=$1
QUERY_HASH=c253a5311a20c2fc082bf9bac87a1ec5eb6e4e51ff936e7be20c29c8e77dee55
DWCA_URL_FILE=dwca_urls.txt
DATASET_DIR=./datasets

preston ls --remote https://deeplinker.bio/$QUERY_HASH --log tsv --no-cache | grep 'application/dwca' | cut -f1 > $DWCA_URL_FILE

# get the provenance log
preston cat hash://sha256/$QUERY_HASH --remote https://deeplinker.bio\
| grep 'application/dwca'\
| cut -d ' ' -f1,3\
| sort | uniq > dwca.txt

preston cat hash://sha256/$QUERY_HASH --remote https://deeplinker.bio\
| grep 'http://purl.org/pav/hasVersion'\
| cut -d ' ' -f1,3\
| sort | uniq > versions.txt

# create a list of unique dwca versions, identified by their sha256 hashes
join <(sort versions.txt) <(sort dwca.txt)\
| grep -o -E "hash://sha256/[a-f0-9]{64}"\
| sort | uniq > dwca-versions.txt

while read -r dwcaHash;
do
        preston cat "$dwcaHash" --remote https://deeplinker.bio > dwca.zip
        
        jq -n --arg format dwca --arg citation "$dwcaHash" '{"format":"dwca","citation":$citation,"url":"dwca.zip"}' > globi.json

        # Search for interactions
        elton interactions >> interactions.tsv

        # Save review summary
        elton review --type summary >> reviews.txt

        # do cleanup here if needed
        rm -r datasets globi.json dwca.zip
done < $DWCA_URL_FILE
