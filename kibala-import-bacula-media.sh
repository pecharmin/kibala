#!/bin/bash
# kibala-import-bacula-media.sh
# Dump medias from Bacula database and import into ElasticSearch for kibala visualization

# Load configuration
source $(dirname $0)/kibala.conf

# Generate and insert documents for elasticsearch of kibala
mysql	--silent --raw \
	-h$BACULA_DB_HOST \
	-u$BACULA_DB_USERNAME \
	$BACULA_DB_SCHEMA >/tmp/kibala-spool <<EOF
select concat(
	'{ "index": { "_index": "$ES_INDEX", "_type": "Media", "_id": ', m.MediaId, ' } }\n',
	'{ "@timestamp": "',		date_format(m.LabelDate, '%Y-%m-%dT%H:%i:%s'), '"',
	', "MediaId": ',		m.MediaId,
	', "MediaVolumeName": "',	m.VolumeName, '"',
	', "MediaTypeId": ',		m.MediaTypeId,
	', "MediaType": "',		m.MediaType, '"',
	', "MediaVolJobs": ', 		m.VolJobs,
	', "MediaVolFiles": ',	 	m.VolFiles,
	', "MediaVolBlocks": ', 	m.VolBlocks,
	', "MediaVolMounts": ', 	m.VolMounts,
	', "MediaVolBytes": ',	 	m.VolBytes,
	', "MediaVolParts": ',	 	m.VolParts,
	', "MediaVolErrors": ', 	m.VolErrors,
	', "MediaVolWrites": ', 	m.VolWrites,
	', "MediaVolCapacityBytes": ', 	m.VolCapacityBytes,
	', "MediaVolStatus": "',	m.VolStatus, '"',
	', "VolRetention": ', 		m.VolRetention,
	', "VolUseDuration": ',		m.VolUseDuration,
	', "MediaMaxVolJobs": ',	m.MaxVolJobs,
	', "MediaMaxVolFiles": ',	m.MaxVolFiles,
	', "MediaMaxVolBytes": ',	m.MaxVolBytes,
	', "MediaEnabled": ', 		m.Enabled,
	', "MediaRecycle": ', 		m.Recycle,
	', "MediaComment": "', 		ifnull(m.Comment, ''), '"',
	', "MediaEnabled": ', 		m.Enabled,
	', "PoolId": ',			m.PoolId,
	', "PoolName": "',		p.Name, '"',
	', "JobMediaId": ',		ifnull(jm.JobMediaId, 'null'),
	', "JobId": ',			ifnull(jm.JobId, 'null'),
	', "JobName": "',		ifnull(j.Name, ''), '"',
	', "ClientId": ',		ifnull(c.ClientId, 'null'),
	', "ClientName": "',		ifnull(c.Name, ''), '"',
	' }'
) output
from 	Media m
	left join Pool p on m.PoolId = p.PoolId
	left join JobMedia jm on jm.MediaId = m.MediaId
	left join Job j on j.JobId = jm.JobId
	left join Client c on j.ClientId = c.ClientId
EOF

curl -s -XPOST $ES_URL/_bulk --data-binary @/tmp/kibala-spool && rm /tmp/kibala-spool

echo
