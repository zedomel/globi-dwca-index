#!/bin/bash
#
#

CACHE_DIR=${1:-"./"}
echo "Output to ${CACHE_DIR}"

# Get last graph version
QUERY_HASH=`preston history --data-dir $CACHE_DIR/biodata --remote https://deeplinker.bio\
| grep 'hasVersion'\
| grep -oE "hash://sha256/[a-f0-9]{64}"`
echo $QUERY_HASH

# get the provenance log
preston cat $QUERY_HASH --data-dir $CACHE_DIR/biodata --remote https://deeplinker.bio\
| grep 'application/dwca'\
| cut -d ' ' -f1,3\
| sort | uniq > $CACHE_DIR/dwca.txt

preston cat $QUERY_HASH --data-dir $CACHE_DIR/biodata --remote https://deeplinker.bio\
| grep 'http://purl.org/pav/hasVersion'\
| cut -d ' ' -f1,3\
| sort | uniq > $CACHE_DIR/versions.txt

# create a list of unique dwca versions, identified by their sha256 hashes
join <(sort $CACHE_DIR/versions.txt) <(sort $CACHE_DIR/dwca.txt)\
| grep -o -E "hash://sha256/[a-f0-9]{64}"\
| sort | uniq > $CACHE_DIR/dwca-versions.txt

touch $CACHE_DIR/dwca-current.txt
diff --line-format=%L $CACHE_DIR/dwca-versions.txt $CACHE_DIR/dwca-current.txt > $CACHE_DIR/dwca-new-versions.txt

while read -r dwcaHash;
do
        echo $dwcaHash >> $CACHE_DIR/dwca-current.txt
        preston cat "$dwcaHash" --data-dir $CACHE_DIR/biodata --remote https://deeplinker.bio > dwca.zip

        jq -n --arg format dwca --arg citation "$dwcaHash" '{"format":"dwca","citation":$citation,"url":"dwca.zip"}' > globi.json

        # Search for interactions
        elton interactions >> $CACHE_DIR/interactions.tsv 2> /dev/null

        # Save review summary
        elton review --type summary >> $CACHE_DIR/reviews.txt 2> /dev/null

        # do cleanup here if needed
        rm -rf datasets globi.json dwca.zip
done < $CACHE_DIR/dwca-new-versions.txt

