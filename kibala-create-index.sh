#!/bin/bash
# kibala-create-index.sh
# Initialize elasticsearch instance for kibala index

# Set custom date to index
ES_INDEX_DATE=${ES_INDEX_DATE:-$1}

# Load configuration
source $(dirname $0)/kibala.conf

echo "Creating index '$ES_INDEX' with ${ELASTICSEARCH_number_of_shards:-3}/${ELASTICSEARCH_number_of_replicas:-1} shards/replicas..."

curl -s -XPUT $ES_URL/$ES_INDEX -d "{
	\"settings\" : {
		\"index\" : {
			\"number_of_shards\" : ${ELASTICSEARCH_number_of_shards:-3},
			\"number_of_replicas\" : ${ELASTICSEARCH_number_of_replicas:-1}
		}
	},
	\"mappings\": {
		\"JobHisto\": {
			\"properties\": {
				\"Job\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				},
				\"JobName\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				},
				\"JobLevel\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				},
				\"ClientName\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				},
				\"PoolName\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				},
				\"VolumeName\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				},
				\"FileSet\": {
					\"type\": \"string\",
					\"index\": \"not_analyzed\"
				},
				\"LogText\": {
					\"type\": \"string\",
					\"index\": \"no\"
				},
				\"Files\": {
					\"type\": \"string\",
					\"index\": \"no\"
				}
			}
		}
	}
}"
ret=$?

echo

[ $ret -ne 0 ] && echo "ERROR: Creation of index '$ES_INDEX' failed with return code $ret" >&2

exit $?
