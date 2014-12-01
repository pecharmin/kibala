#!/bin/bash
# kibala-indexer.sh 
# Runs all tools to insert/update bacula data in elasticsearch

# Abort on error
set -e

$(dirname $0)/kibala-import-bacula-client.sh
$(dirname $0)/kibala-import-bacula-job.sh
$(dirname $0)/kibala-import-bacula-pool.sh
$(dirname $0)/kibala-import-bacula-media.sh
$(dirname $0)/kibala-import-bacula-jobhisto.sh
