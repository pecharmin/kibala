#!/bin/bash
# kibala-import-bacula-pool.sh
# Dump pool definitions from Bacula database and import into ElasticSearch for kibala visualization

# Load configuration
source $(dirname $0)/kibala.conf

# Generate and insert documents for elasticsearch of kibala
mysql	--silent --raw \
	-h$BACULA_DB_HOST \
	-u$BACULA_DB_USERNAME \
	$BACULA_DB_SCHEMA >/tmp/kibala-spool <<EOF
select concat(
	'{ "index": { "_index": "$ES_INDEX", "_type": "Pool", "_id": ', p.PoolId, ' } }\n',
	'{ "@timestamp": "', 		date_format(now(), '%Y-%m-%dT%H:%i:%s'), '"',
	', "PoolId": ',			p.PoolId,
	', "PoolName": "',		p.Name, '"',
	', "PoolType": "',		p.PoolType, '"',
	', "VolRetention": ',		p.VolRetention,
	', "VolUseDuration": ',		p.VolUseDuration,
	', "AutoPrune": ',		p.AutoPrune,
	', "Recycle": ',		p.Recycle,
	', "Enabled": ',		p.Enabled,
	', "ClientName": [ ',		ifnull( ( select group_concat(	DISTINCT concat('"', c.Name, '"')
									order by c.Name separator ', ')
						  from Job j
						  left join Client c on j.ClientId = c.ClientId
						  where j.PoolId = p.PoolId
						),
						''
					), ' ]',
	', "JobName": [ ',		ifnull( ( select group_concat( 	DISTINCT concat('"', j.Name, '"')
									order by j.Name separator ', ')
						  from Job j
						  where j.PoolId = p.PoolId
						),
						''
					), ' ]',
	' }'
) output
from 	Pool p
EOF

curl -s -XPOST $ES_URL/_bulk --data-binary @/tmp/kibala-spool && rm /tmp/kibala-spool

echo
