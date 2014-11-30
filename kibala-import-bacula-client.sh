#!/bin/bash
# kibala-import-bacula-clients.sh
# Dump clients from Bacula database and import into ElasticSearch for kibala visualization

# Generate and insert documents with job infos into elasticsearch for kibala
mysql --silent --raw -ubacula -pbacula bacula >/tmp/kibala-clients <<EOF
select concat(
	'{ "index": { "_index": "kibala", "_type": "Client", "_id": ', c.ClientId, ' } }\n',
	'{ "ClientId": ',		c.ClientId,
	', "ClientName": "',		c.Name, '"',
	', "ClientUname": "',		c.Uname, '"',
	', "ClientAutoPrune": ',	c.AutoPrune,
	', "ClientFileRetention": ',	c.FileRetention,
	', "ClientJobRetention": ',	c.JobRetention,
	' }'
) output
from 	Client c;
EOF

curl -s -XPOST http://localhost:9200/_bulk --data-binary @/tmp/kibala-clients
