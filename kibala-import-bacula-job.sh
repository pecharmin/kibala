#!/bin/bash
# kibala-import-bacula-job.sh
# Dump job definitions from Bacula database and import into ElasticSearch for kibala visualization

# Generate and insert documents with job infos into elasticsearch for kibala
mysql --silent --raw -ubacula -pbacula bacula >/tmp/kibala-job <<EOF
select distinct concat(
	'{ "index": { "_index": "kibala", "_type": "Job", "_id": "', j.Name , '" } }\n',
	'{ "JobName": "',		j.Name, '"',
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
	' }'
) output
from 	Job j;
EOF

curl -s -XPOST http://localhost:9200/_bulk --data-binary @/tmp/kibala-job
