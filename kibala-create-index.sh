#!/bin/bash
# kibala-create-index.sh
# Initialize elasticsearch instance for kibala index

# Load configuration
source $(dirname $0)/kibala.conf

curl -XPUT $ES_URL/$ES_INDEX -d "{
	\"settings\" : {
		\"index\" : {
			\"number_of_shards\" : ${ELASTICSEARCH_number_of_shards:-3},
			\"number_of_replicas\" : ${ELASTICSEARCH_number_of_replicas:-1}
		}
	},
	\"mappings\": {
		\"Client\": {
			\"properties\": {
				\"ClientName\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				},
				\"ClientUname\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				},
				\"JobName\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				}
			}
		},
		\"Media\": {
			\"properties\": {
				\"VolumeName\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				},
				\"VolBytes\": {
					\"type\": \"byte\"
				}
			}
		}
	}
}"

echo
