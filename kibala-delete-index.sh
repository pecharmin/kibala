#!/bin/bash
# kibala-delete-index.sh
# Cleanup existing elasticsearch index

# Load configuration
source $(dirname $0)/kibala.conf

curl -XDELETE $ES_URL/$ES_INDEX

echo
