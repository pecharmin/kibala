#!/bin/bash
# kibala-import-bacula-media.sh
# Dump medias from Bacula database and import into ElasticSearch for kibala visualization

echo "Indexing medias..."

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
	'{ "@timestamp": ',		if(	STRCMP(	date_format(m.LabelDate, '%Y-%m-%dT%H:%i:%s'),
							'0000-00-00T00:00:00'),
						concat('"', date_format(m.LabelDate, '%Y-%m-%dT%H:%i:%s'), '"'),
						'null'
					),
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

	', "Job": [ ',			ifnull( ( select group_concat(  DISTINCT concat('"', j.Job, '"')
									order by j.Job separator ', ')
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

        ', "JobStatus": [ ',            ifnull( ( select group_concat( DISTINCT concat('"', j.JobStatus, '"')
									order by j.Level separator ', ')

						  from Job j
						  left join JobMedia jm on jm.JobId = j.JobId
						  where jm.JobMediaId = m.MediaId
						),
						''
					), ' ]',

        ', "JobStatusName": [ ',         ifnull( ( select group_concat(
						DISTINCT concat('"',
						case j.JobStatus
                                                when 'A' then 'CanceledByUser'
                                                when 'B' then 'Blocked'
                                                when 'C' then 'CreatedNotYetRun'
                                                when 'D' then 'VerifyDifferences'
                                                when 'E' then 'Error'
                                                when 'F' then 'WaitingOnFileDaemon'
                                                when 'I' then 'Incomplete'
                                                when 'L' then 'CommittingData'
                                                when 'M' then 'WaitingForMount'
                                                when 'R' then 'Running'
                                                when 'S' then 'WaitingOnStorageDaemon'
                                                when 'T' then 'Completed'
                                                when 'W' then 'Warning'
                                                when 'a' then 'StorageDaemonDespoolingAttributes'
                                                when 'c' then 'WaitingForClientResource'
                                                when 'd' then 'WaitingForMaximumJobs'
                                                when 'f' then 'FatalError'
                                                when 'i' then 'BatchInsertFileRecords'
                                                when 'j' then 'WaitingforJobResource'
                                                when 'l' then 'DespoolingData'
                                                when 'm' then 'WaitingForNewMedia'
                                                when 'p' then 'WaitingForFinishOfPriorisedJob'
                                                when 'q' then 'QueuedWaitingForDevice'
                                                when 's' then 'WaitingForStorageResource'
                                                when 't' then 'WaitingForStartTime'
                                        	end,
                                        '"') separator ', ')
						  from Job j
						  left join JobMedia jm on jm.JobId = j.JobId
						  where jm.JobMediaId = m.MediaId
						),
						''
					), ' ]',

	', "JobLevelName": [ ',		ifnull( ( select group_concat(
								DISTINCT concat('"',
								   case j.Level
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
								'"') separator ', ')
						  from Job j
						  left join JobMedia jm on jm.JobId = j.JobId
						  where jm.JobMediaId = m.MediaId
						),
						'null'
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
