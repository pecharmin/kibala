#!/bin/bash
# kibala-import-bacula-job.sh
# Dump job definitions from Bacula database and import into ElasticSearch for kibala visualization

echo "Indexing job definitions..."

# Load configuration
source $(dirname $0)/kibala.conf

# Generate and insert documents with job infos into elasticsearch for kibala
mysql	--silent --raw \
	-h$BACULA_DB_HOST \
	-u$BACULA_DB_USERNAME \
	$BACULA_DB_SCHEMA >/tmp/kibala-spool <<EOF
select distinct concat(
	'{ "index": { "_index": "$ES_INDEX", "_type": "Job", "_id": "', j.Name , '" } }\n',
	'{ "@timestamp": "', 		date_format(subtime(now(), '00:20:00'), '%Y-%m-%dT%H:%i:%s'), '"',
	', "JobName": "',		j.Name, '"',
	', "JobType": "',		j.Type, '"',
	', "JobTypeName": "',		case j.Type
						when 'B' then 'Backup'
						when 'M' then 'Migrated job'
						when 'V' then 'Verify'
						when 'R' then 'Restore'
						when 'U' then 'Console'
						when 'I' then 'Internal'
						when 'D' then 'Admin'
						when 'A' then 'Archive'
						when 'c' then 'Copy'
						when 'C' then 'Copyed job'
						when 'g' then 'Migration'
						when 'S' then 'Scan'
					end,
					'"',
	', "JobLevel": "',		j.Level, '"',
	', "JobLevelName": "',		case j.Level
						when 'F' then 'Full'
						when 'D' then 'Differential'
						when 'I' then 'Incremental'
						when 'S' then '?Since?'
						when 'C' then 'VerifyJobFromCatalog'
						when 'V' then 'VerifyDatabaseSchema'
						when 'O' then 'VerifyVolumeVsCatalog'
						when 'd' then 'VerifyDiskAttributesVsCatalog'
						when 'A' then 'VerifyDataOnVolume'
						when 'B' then 'Base'
						when ' ' then 'RestoreOrAdminCcommand'
						when 'f' then 'VirtualFull'
					end,
					'"',
	', "ClientId": ',		c.ClientId,
	', "ClientName": "',		c.Name, '"',
	', "ClientUname": "',		c.Uname, '"',
	' }'
) output
from 	Job j
	left join Client c on j.ClientId = c.ClientId;
EOF

curl -s -XPOST $ES_URL/_bulk --data-binary @/tmp/kibala-spool | format_es_response
rm /tmp/kibala-spool

echo
