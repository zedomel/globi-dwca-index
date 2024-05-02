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
                r) REMOTE="--remote https://linker.bio" ;;
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
ELTON_CACHE_DIR="$CACHE_DIR/datasets"

while read -r dwcaHash;
do
        work_dir=$CACHE_DIR/$(basename $dwcaHash)
	namespace=$(basename $dwcaHash)
	command="export JAVA_OPTS=\"-Djava.io.tmpdir=$CURRENT_DIR/tmp\" && \
                mkdir -p $work_dir && \
                cp $CURRENT_DIR/conf/interaction_types_*.csv $work_dir && \
                echo $dwcaHash >> $CACHE_DIR/dwca-current.txt && \
                cd $work_dir && \
                preston cat \"$dwcaHash\" --data-dir $CACHE_DIR/biodata $REMOTE > dwca.zip && \
                jq -n --arg format dwca --arg citation \"$dwcaHash via $QUERY_HASH\" '{\"format\":\"dwca\",\"citation\":\"$citation\",\"url\":\"dwca.zip\"}' > globi.json && \
		elton update -c $ELTON_CACHE_DIR --registry local $namespace ;"
        echo $command >> $CACHE_DIR/commands.txt
done < $CACHE_DIR/dwca-new-versions.txt

N_CORES=`nproc`
# Execute tasks in parallel
cat $CACHE_DIR/commands.txt | while read i; do printf "%q\n" "$i"; done | xargs --max-procs=$N_CORES -I CMD bash -c CMD
