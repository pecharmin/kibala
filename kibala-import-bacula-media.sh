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
SET SESSION group_concat_max_len = 1000000;

select concat(
	'{ "index": { "_index": "$ES_INDEX", "_type": "Media", "_id": ', m.MediaId, ' } }\n',
	'{ "@timestamp": "',		date_format(m.LabelDate, '%Y-%m-%dT%H:%i:%s'), '"',
	', "MediaId": ',		m.MediaId,
	', "VolumeName": "',		m.VolumeName, '"',
	', "MediaTypeId": ',		m.MediaTypeId,
	', "MediaType": "',		m.MediaType, '"',
	', "VolJobs": ', 		m.VolJobs,
	', "VolFiles": ',	 	m.VolFiles,
	', "VolBlocks": ', 		m.VolBlocks,
	', "VolMounts": ', 		m.VolMounts,
	', "VolBytes": ',	 	m.VolBytes,
	', "VolParts": ',	 	m.VolParts,
	', "VolErrors": ', 		m.VolErrors,
	', "VolWrites": ', 		m.VolWrites,
	', "VolCapacityBytes": ', 	m.VolCapacityBytes,
	', "VolStatus": "',		m.VolStatus, '"',
	', "VolRetention": ', 		m.VolRetention,
	', "VolUseDuration": ',		m.VolUseDuration,
	', "MaxVolJobs": ',		m.MaxVolJobs,
	', "MaxVolFiles": ',		m.MaxVolFiles,
	', "MaxVolBytes": ',		m.MaxVolBytes,
	', "Enabled": ', 		m.Enabled,
	', "Recycle": ', 		m.Recycle,
	', "Comment": "', 		ifnull(m.Comment, ''), '"',
	', "PoolId": ',			m.PoolId,
	', "PoolName": "',		p.Name, '"',
	', "JobMediaId": ',		ifnull(jm.JobMediaId, 'null'),
	', "JobId": [ ',		ifnull( ( select group_concat(  DISTINCT j.JobId
									order by j.JobId separator ', ')
						  from Job j
						  left join JobMedia jm on jm.JobId = j.JobId
						  where jm.JobMediaId = m.MediaId
						),
						''
					), ' ]',
	', "JobName": [ ',		ifnull( ( select group_concat(  DISTINCT concat('"', j.Name, '"')
									order by j.Name separator ', ')
						  from Job j
						  left join JobMedia jm on jm.JobId = j.JobId
						  where jm.JobMediaId = m.MediaId
						),
						''
					), ' ]',
	', "ClientId": [ ',		ifnull( ( select group_concat(  DISTINCT c.ClientId
									order by c.ClientId separator ', ')
						  from Client c
						  left join Job j on c.ClientId = j.ClientId
						  left join JobMedia l_jm on l_jm.JobId = j.JobId
						  where l_jm.JobMediaId = jm.JobMediaId
						),
						''
					), ' ]',
	', "ClientName": [ ',		ifnull( ( select group_concat(  DISTINCT concat('"', c.Name, '"')
									order by c.Name separator ', ')
						  from Client c
						  left join Job j on c.ClientId = j.ClientId
						  left join JobMedia l_jm on l_jm.JobId = j.JobId
						  where l_jm.JobMediaId = jm.JobMediaId
						),
						''
					), ' ]',
	' }'
) output
from 	Media m
	left join Pool p on m.PoolId = p.PoolId
	left join JobMedia jm on jm.MediaId = m.MediaId
	left join Job j on j.JobId = jm.JobId
	left join Client c on j.ClientId = c.ClientId
EOF

curl -s -XPOST $ES_URL/_bulk --data-binary @/tmp/kibala-spool | format_es_response
rm /tmp/kibala-spool

echo
