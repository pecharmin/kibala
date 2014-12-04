#!/bin/bash
# kibala-delete-index.sh
# Cleanup existing elasticsearch index

# Set custom date to index
ES_INDEX_DATE=${ES_INDEX_DATE:-$1}

# Load configuration
source $(dirname $0)/kibala.conf

echo "Deleting index '$ES_INDEX'..."

curl -XDELETE $ES_URL/$ES_INDEX

echo
