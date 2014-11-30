#!/bin/bash
# kibala-init.sh
# Initialize elasticsearch instance for kibala index

curl -XDELETE http://localhost:9200/kibala
curl -XPUT http://localhost:9200/kibala -d '{
	"settings" : {
		"index" : {
			"number_of_shards" : 3,
			"number_of_replicas" : 1
		}
	}
}'
