#!/bin/sh
#
#

#QUERY_HASH=$1
QUERY_HASH=c253a5311a20c2fc082bf9bac87a1ec5eb6e4e51ff936e7be20c29c8e77dee55
DWCA_URL_FILE=dwca_urls.txt
DATASET_DIR=./datasets

preston ls --remote https://deeplinker.bio/$QUERY_HASH --log tsv --no-cache | grep 'application/dwca' | cut -f1 > $DWCA_URL_FILE

elton init --data-url="http://example.com" --data-citation="Preston DwC-A Interactions" dwcainteractions2021
jq '. + {format: "dwca"}' globi.json > tmp.$$.json && mv tmp.$$.json globi.json

while read -r newUrl;
do
        echo "$newUrl"
        #OUTPUT_FILE=$DATASET_DIR/`hexdump -e '/1 "%02x"' -n16 < /dev/urandom`.zip
        #newCitation=$(wget -q $line -O $OUTPUT_FILE && unzip -qq -p $OUTPUT_FILE | grep -oPm1 "(?<=<title>)[^<]+")
        jq '. + {url: $newUrl, citation: $newCitation}' --arg newUrl "$newUrl" --arg newCitation "$newUrl" globi.json > tmp.$$.json && mv tmp.$$.json globi.json

        # Remove local cache
        rm -r datasets

        # Search for interactions
        elton interactions >> interactions.tsv

        # Save review summary
        echo ">$newUrl" >> reviews.txt | elton review --type summary >> reviews.txt

        break
done < $DWCA_URL_FILE
