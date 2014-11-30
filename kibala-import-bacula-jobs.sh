#!/bin/bash
# kibala-import-bacula-jobs.sh
# Dump jobs from Bacula database and import into ElasticSearch for kibala visualization

# Generate and insert documents with job infos into elasticsearch for kibala
mysql --silent --raw -ubacula -pbacula bacula >/tmp/kibala-jobs <<EOF
select concat(
	'{ "index": { "_index": "kibala", "_type": "jobs", "_id": ', j.JobId, ' } }\n', 
	'{ "@timestamp": "',		date_format(j.SchedTime, '%Y-%m-%dT%H:%i:%s'), '"',
	', "JobId": ',			j.JobId,
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
	', "JobRealEndTime": ',		if( date_format(j.RealEndTime, '%Y-%m-%dT%H:%i:%s')
					    = "0000-00-00 00:00:00",
					      concat('"', date_format(j.RealEndTime, '%Y-%m-%dT%H:%i:%s'), '"'),
					      '[]'
					),
	', "JobFiles": ',		j.JobFiles,
	', "JobBytes": ',		j.JobBytes,
	', "JobReadBytes": ',		j.ReadBytes,
	', "JobErrors": ',		j.JobErrors,
	', "JobMissingFiles": ',	j.JobMissingFiles,
	', "JobPriorJobId": ',		j.PriorJobId,
	', "ClientName": "',		c.Name, '"',
	', "ClientUname": "',		c.Uname, '"',
	', "ClientAutoPrune": ',	c.AutoPrune,
	', "ClientFileRetention": ',	c.FileRetention,
	', "ClientJobRetention": ',	c.JobRetention,
	', "FileSetId": ',		ifnull(f.FileSetId, 'null'),
	', "FileSet": "',		ifnull(f.FileSet, ''), '"',
	', "PoolId": ',			ifnull(p.PoolId, 'null'),
	', "PoolName": "',		ifnull(p.Name, ''), '"',
	', "MediaVolumeName": "',	ifnull(m.VolumeName, ''), '"',
	', "MediaType": "',		ifnull(m.MediaType, ''), '"',
	', "MediaVolStatus": "',	ifnull(m.VolStatus, ''), '"',
	' }'
) output
from 	Job j
	left join Client c on j.ClientId = c.ClientId
	left join Pool p on j.PoolId = p.PoolId
	left join JobMedia jm on j.JobId = jm.JobId
	left join Media m on jm.MediaId = m.MediaId
	left join FileSet f on j.FileSetId = f.FileSetId
	left join Status s on j.JobStatus = s.JobStatus
order	by j.JobId desc
EOF

curl -s -XPOST http://localhost:9200/_bulk --data-binary @/tmp/kibala-jobs
