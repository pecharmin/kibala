#!/bin/bash
# kibala-init.sh
# Initialize elasticsearch instance for kibala index

# Load configuration
source $(dirname $0)/kibala.conf

curl -XDELETE $ES_URL/$ES_INDEX
curl -XPUT $ES_URL/$ES_INDEX -d '{
	"settings" : {
		"index" : {
			"number_of_shards" : 3,
			"number_of_replicas" : 1
		}
	}
}'

echo
