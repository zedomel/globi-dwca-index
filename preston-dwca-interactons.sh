#!/bin/bash
#
#

# Get last graph version
QUERY_HASH=`preston history --remote https://deeplinker.bio\
| grep 'hasVersion'\
| grep -oE "hash://sha256/[a-f0-9]{64}"`
echo $QUERY_HASH

# get the provenance log
preston cat $QUERY_HASH --remote https://deeplinker.bio\
| grep 'application/dwca'\
| cut -d ' ' -f1,3\
| sort | uniq > dwca.txt

preston cat $QUERY_HASH --remote https://deeplinker.bio\
| grep 'http://purl.org/pav/hasVersion'\
| cut -d ' ' -f1,3\
| sort | uniq > versions.txt

# create a list of unique dwca versions, identified by their sha256 hashes
join <(sort versions.txt) <(sort dwca.txt)\
| grep -o -E "hash://sha256/[a-f0-9]{64}"\
| sort | uniq > dwca-versions.txt

while read -r dwcaHash;
do
        echo $dwcaHash
        preston cat "$dwcaHash" --remote https://deeplinker.bio > dwca.zip

        jq -n --arg format dwca --arg citation "$dwcaHash" '{"format":"dwca","citation":$citation,"url":"dwca.zip"}' > globi.json

        # Search for interactions
        elton interactions >> interactions.tsv 2> /dev/null

        # Save review summary
        elton review --type summary >> reviews.txt 2> /dev/null

        # do cleanup here if needed
        rm -rf datasets globi.json dwca.zip
done < dwca-versions.txt

