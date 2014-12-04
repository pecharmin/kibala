#!/bin/bash
# kibala-indexer.sh 
# Runs all tools to insert/update bacula data in elasticsearch

# Abort on error
set -e

# Set custom date to index
export ES_INDEX_DATE=${ES_INDEX_DATE:-$1}

# Index all nessassary types
$(dirname $0)/kibala-import-bacula-jobhisto.sh
