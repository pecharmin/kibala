#!/bin/bash
# kibala-import-bacula-clients.sh
# Dump clients from Bacula database and import into ElasticSearch for kibala visualization

# Generate and insert documents with job infos into elasticsearch for kibala
mysql --silent --raw -ubacula -pbacula bacula >/tmp/kibala-clients <<EOF
select concat(
	'{ "index": { "_index": "kibala", "_type": "clients", "_id": ', c.ClientId, ' } }\n', 
	'{ "ClientId": ',		c.ClientId,
	', "Name": "',			c.Name, '"',
	', "Uname": "',			c.Uname, '"',
	', "AutoPrune": ',		c.AutoPrune,
	', "FileRetention": ',		c.FileRetention,
	', "JobRetention": ',		c.JobRetention,
	' }'
) output
from 	Client c;
EOF

curl -s -XPOST http://localhost:9200/_bulk --data-binary @/tmp/kibala-clients
