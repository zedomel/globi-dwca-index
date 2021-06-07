#!/bin/bash
#
# Retrieves and updates interaction translation tables
#


function get_mapping {
  curl -L "https://docs.google.com/spreadsheets/u/0/d/1AxCSJYA5dGSDZKDR-GLRglL-xQQP_Se54J2vpjHGgkQ/export?format=csv"
}


echo "provided_interaction_type_label,provided_interaction_type_id,mapped_to_interaction_type_label,mapped_to_interaction_type_id"\
  > interaction_types_mappings.csv

get_mapping\
 | grep -v ignore\
 | grep "purl"\
 | cut -d ',' -f1-4\
 >>  interaction_types_mappings.csv

echo "interaction_type_ignored"\
 > interaction_types_ignored.csv

get_mapping\
 | grep ignore\
 | cut -d ',' -f1\
 >> interaction_types_ignored.csv
