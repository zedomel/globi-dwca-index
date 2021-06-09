#!/bin/bash
#
#

CURRENT_DIR=`pwd`
CACHE_DIR=${1:-"./"}
echo "Output to ${CACHE_DIR}"

# Get last graph version
QUERY_HASH=`preston history -l tsv --data-dir $CACHE_DIR/biodata --remote https://deeplinker.bio\
| tr '\t' '\n'\
| grep sha\
| tail -n2\
| head -n1`
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

COMMAND_FILE="commands.txt"
while read -r dwcaHash;
do
        work_dir=$CACHE_DIR/$(basename $dwcaHash)
        echo  "mkdir -p $work_dir && \
        cp $CURRENT_DIR/conf/interaction_types_*.csv $work_dir && \
        echo $dwcaHash >> $CACHE_DIR/dwca-current.txt && \
        cd $work_dir && \
        preston cat \"$dwcaHash\" --data-dir $CACHE_DIR/biodata --remote https://deeplinker.bio > dwca.zip && \
        jq -n --arg format dwca --arg citation \"$dwcaHash via $QUERY_HASH\" '{\"format\":\"dwca\",\"citation\":\$citation,\"url\":\"dwca.zip\"}' > globi.json && \
        elton interactions --skip-header >> $work_dir/interactions.tsv 2> /dev/null && \
        elton review --skip-header >> $work_dir/reviews.txt 2> /dev/null ; \
        flock $CACHE_DIR/interactions.tsv -c \"cat $work_dir/interactions.tsv >> $CACHE_DIR/interactions.tsv\" ; \
        flock $CACHE_DIR/reviews.txt -c \"cat $work_dir/reviews.txt >> $CACHE_DIR/reviews.txt\" ; \
        rm -rf $work_dir" >> $CACHE_DIR/commands.txt
done < $CACHE_DIR/dwca-new-versions.txt

N_CORES=`nproc`
# Execute tasks in parallel
cat $CACHE_DIR/commands.txt | while read i; do printf "%q\n" "$i"; done | xargs --max-procs=$N_CORES -I CMD bash -c CMD
