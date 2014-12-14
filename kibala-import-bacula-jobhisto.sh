#!/bin/bash
# kibala-import-bacula-jobhisto.sh
# Dump job history from Bacula database and import into ElasticSearch for kibala visualization

echo "Indexing executed/planned jobs..."

# Load configuration
source $(dirname $0)/kibala.conf

# Generate and insert documents with job infos into elasticsearch for kibala
[ "$ES_INDEX_DATE" ] && WHERE_CONDITION="where j.SchedTime between '${ES_INDEX_DATE} 00:00:00' and '${ES_INDEX_DATE} 23:59:59'"

mysql	--silent --raw \
	-h$BACULA_DB_HOST \
	-u$BACULA_DB_USERNAME \
	$BACULA_DB_SCHEMA >/tmp/kibala-spool <<EOF
SET SESSION group_concat_max_len = 1000000;
SET sql_mode = 'NO_UNSIGNED_SUBTRACTION';

select concat(
	'{ "index": { "_index": "$ES_INDEX", "_type": "JobHisto", "_id": ', j.JobId, ' } }\n',
	'{ "@timestamp": "',		date_format(j.SchedTime, '%Y-%m-%dT%H:%i:%s'), '"',
	', "JobId": ',			j.JobId,
	', "Job": "',			j.Job, '"',
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
	', "JobStatus": "',		j.JobStatus, '"',
	', "JobStatusName": "',		case j.JobStatus
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
					'"',
	', "JobStatusLong": "',		s.JobStatusLong, '"',
	', "JobSchedTime": "',		date_format(j.SchedTime, '%Y-%m-%dT%H:%i:%s'), '"',
	', "JobStartTime": "',		date_format(j.StartTime, '%Y-%m-%dT%H:%i:%s'), '"',
	', "JobEndTime": "',		date_format(j.EndTime, '%Y-%m-%dT%H:%i:%s'), '"',
	', "JobFiles": ',		j.JobFiles,
	', "JobBytes": ',		j.JobBytes,
	', "JobReadBytes": ',		j.ReadBytes,
	', "JobErrors": ',		j.JobErrors,
	', "JobMissingFiles": ',	j.JobMissingFiles,

	', "ClientId": ',		c.ClientId,
	', "ClientName": "',		c.Name, '"',

	', "FileSetId": ',		ifnull(f.FileSetId, 'null'),
	', "FileSet": ',		ifnull(concat('"', f.FileSet, '"'), 'null'),

	', "PoolId": ',			ifnull(p.PoolId, 'null'),
	', "PoolName": ',		ifnull(concat('"', p.Name, '"'), 'null'),

	', "JobMediaId": ',		ifnull(jm.JobMediaId, 'null'),
	', "JobId": ',			ifnull(jm.JobId, 'null'),
	', "VolumeName": ',		ifnull(concat('"', m.VolumeName, '"'), 'null'),
	', "MediaType": ',		ifnull(concat('"', m.MediaType, '"'), 'null'),
	', "VolStatus": ',		ifnull(concat('"', m.VolStatus, '"'), 'null'),
	', "MediaComment": ',		ifnull(concat('"', m.Comment, '"'), 'null'),

	', "VolIndex": ',		ifnull(jm.VolIndex, 'null'),
	', "MediaBlocks": ',		ifnull(jm.EndBlock - jm.StartBlock, 0),

        ', "LogText": [ ',		ifnull( ( select
						group_concat(
							concat('"', l.Time, ' ',
						          replace(
							    replace(
							      replace(
							        replace(
							          replace(
									l.LogText,
							          0x00, ''),
							        '"', '\\\"'),
							      '\n', '\\\n'),
							    char(9), ''),
							  char(13), '')
							, '"')
						order by l.LogId separator ', ')
						from Log l
						where l.JobId = j.JobId
						),
						''
					), ' ]',
	', "Files": "',		ifnull( ( select
							group_concat(
								concat(pa.Path, fn.Name)
								order by pa.Path, fn.Name separator '\\\\n')
							from File fi
							left join Path pa on fi.PathId = pa.PathId
							left join Filename fn on fi.FilenameId = fn.FilenameId
							where fi.JobId = j.JobId
						),
						''
					), '"',
	' }'
) output
from 	Job j
	left join Client c on j.ClientId = c.ClientId
	left join Pool p on j.PoolId = p.PoolId
	left join JobMedia jm on j.JobId = jm.JobId
	left join Media m on jm.MediaId = m.MediaId
	left join FileSet f on j.FileSetId = f.FileSetId
	left join Status s on j.JobStatus = s.JobStatus
$WHERE_CONDITION
order	by j.JobId desc
EOF

curl -s -XPOST $ES_URL/_bulk --data-binary @/tmp/kibala-spool | format_es_response
rm /tmp/kibala-spool

echo
