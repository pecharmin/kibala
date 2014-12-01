#!/bin/bash
# kibala-import-bacula-client.sh
# Dump clients from Bacula database and import into ElasticSearch for kibala visualization

# Load configuration
source $(dirname $0)/kibala.conf

# Generate and insert documents with job infos into elasticsearch for kibala
mysql	--silent --raw \
	-h$BACULA_DB_HOST \
	-u$BACULA_DB_USERNAME \
	$BACULA_DB_SCHEMA >/tmp/kibala-spool <<EOF
select concat(
	'{ "index": { "_index": "$ES_INDEX", "_type": "Client", "_id": ', c.ClientId, ' } }\n',
	'{ "@timestamp": "', 		date_format(now(), '%Y-%m-%dT%H:%i:%s'), '"',
	', "ClientId": ',		c.ClientId,
	', "ClientName": "',		c.Name, '"',
	', "ClientUname": "',		c.Uname, '"',
	', "ClientAutoPrune": ',	c.AutoPrune,
	', "ClientFileRetention": ',	c.FileRetention,
	', "ClientJobRetention": ',	c.JobRetention,
	', "JobName": [ ',		ifnull( ( select group_concat(  DISTINCT concat('"', j.Name, '"')
									order by j.Name separator ', ')
						  from Job j
						  where j.ClientId = c.ClientId
						),
						''
					), ' ]',
	' }'
) output
from 	Client c;
EOF

curl -s -XPOST $ES_URL/_bulk --data-binary @/tmp/kibala-spool && rm /tmp/kibala-spool

echo
