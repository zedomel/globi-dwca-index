#!/bin/bash
#
#

CURRENT_DIR=`pwd`
CACHE_DIR=
REMOTE=

print_usage() {
        printf "Usage: %s: [-r] -c <data-dir>\n" $0
}

while getopts c:r flag; do
        case ${flag} in
                c) CACHE_DIR="$OPTARG" ;;
                r) REMOTE="--remote https://deeplinker.bio" ;;
                ?) print_usage
                   exit 1 ;;
        esac
done

if [ -z "$CACHE_DIR" ]; then
        print_usage
        exit 1
fi

echo "Output to ${CACHE_DIR}"
if [ -n "$REMOTE" ]; then
        echo "Remote : ${REMOTE}"
fi

# Get last graph version
QUERY_HASH=`preston history -l tsv --data-dir $CACHE_DIR/biodata $REMOTE\
| tr '\t' '\n'\
| grep sha\
| tail -n2\
| head -n1`
echo $QUERY_HASH

# get the provenance log
preston cat $QUERY_HASH --data-dir $CACHE_DIR/biodata $REMOTE\
| grep 'application/dwca'\
| cut -d ' ' -f1,3\
| sort | uniq > $CACHE_DIR/dwca.txt

preston cat $QUERY_HASH --data-dir $CACHE_DIR/biodata $REMOTE\
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
	command="export JAVA_OPTS=$JAVA_OPTS && \
                mkdir -p $work_dir && \
                cp $CURRENT_DIR/conf/interaction_types_*.csv $work_dir && \
                echo $dwcaHash >> $CACHE_DIR/dwca-current.txt && \
                cd $work_dir && \
                preston cat \"$dwcaHash\" --data-dir $CACHE_DIR/biodata $REMOTE > dwca.zip && \
                jq -n --arg format dwca --arg citation \"$dwcaHash via $QUERY_HASH\" '{\"format\":\"dwca\",\"citation\":\"$citation\",\"url\":\"dwca.zip\"}' > globi.json && \
                elton interactions --skip-header > $work_dir/interactions.tsv 2> /dev/null ; \
                elton review --skip-header > $work_dir/reviews.txt 2> /dev/null ; \
                rm -f $work_dir/dwca.zip $work_dir/interaction_types_*.csv $work_dir/globi.json"
        echo $command >> $CACHE_DIR/commands.txt
done < $CACHE_DIR/dwca-new-versions.txt

N_CORES=`nproc`
# Execute tasks in parallel
cat $CACHE_DIR/commands.txt | while read i; do printf "%q\n" "$i"; done | xargs --max-procs=$N_CORES -I CMD bash -c CMD
find $CACHE_DIR -mindepth 2 -name "interactions.tsv" | xargs cat > $CACHE_DIR/interactions.tsv
find $CACHE_DIR -mindepth 2 -name "reviews.txt" | xargs cat > $CACHE_DIR/reviews.txt
