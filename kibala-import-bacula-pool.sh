#!/bin/bash
# kibala-import-bacula-jobhisto.sh
# Dump job history from Bacula database and import into ElasticSearch for kibala visualization

# Load configuration
source $(dirname $0)/kibala.conf

# Generate and insert documents for elasticsearch of kibala
mysql	--silent --raw \
	-h$BACULA_DB_HOST \
	-u$BACULA_DB_USERNAME \
	$BACULA_DB_SCHEMA >/tmp/kibala-spool <<EOF
select concat(
	'{ "index": { "_index": "$ES_INDEX", "_type": "Pool", "_id": ', p.PoolId, ' } }\n',
	'{ "PoolId": ',			p.PoolId,
	', "PoolName": "',		p.Name, '"',
	', "PoolType": "',		p.PoolType, '"',
	', "PoolVolRetention": ',	p.VolRetention,
	', "PoolVolUseDuration": ',	p.VolUseDuration,
	', "PoolAutoPrune": ',		p.AutoPrune,
	', "PoolRecycle": ',		p.Recycle,
	', "PoolEnabled": ',		p.Enabled,
	' }'
) output
from 	Pool p
EOF

curl -s -XPOST $ES_URL/_bulk --data-binary @/tmp/kibala-spool && rm /tmp/kibala-spool

echo
