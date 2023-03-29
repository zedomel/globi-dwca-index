#!/bin/bash
#
# Retrieves and updates interaction translation tables
#

function get_mapping {
  curl -L "https://docs.google.com/spreadsheets/u/0/d/1gNVEiN5GJxrei6QwgqC_sbvKzaJrktm_Pv1Psqx2GtI/export?format=csv" | tee unsupported_interaction_types.csv
}


echo "provided_interaction_type_label,provided_interaction_type_id,mapped_to_interaction_type_label,mapped_to_interaction_type_id"\
  > interaction_types_mapping.csv

get_mapping\
 | grep -v ignore\
 | grep "purl"\
 | cut -d ',' -f1-4\
 | awk -F, '{print tolower($1)","$2","$3","$4}'\
 | sort -k 1 -t,\
 | uniq\
 >>  interaction_types_mapping.csv

echo "interaction_type_ignored"\
 > interaction_types_ignored.csv

get_mapping\
 | grep ignore\
 | cut -d ',' -f1\
 | sort\
 | uniq\
 >> interaction_types_ignored.csv
