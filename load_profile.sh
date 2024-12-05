#!/bin/bash
curl https://raw.githubusercontent.com/ianmiell/oscal4neo4j/refs/heads/main/data/NIST-800-53/script/load.cypher          | cypher-shell -u neo4j -p testtest
curl https://raw.githubusercontent.com/ianmiell/oscal4neo4j/refs/heads/main/data/NIST-800-53/script/load-profiles.cypher | cypher-shell -u neo4j -p testtest
curl https://raw.githubusercontent.com/ianmiell/oscal4neo4j/refs/heads/main/data/NIST-800-53/script/queries.cypher       | cypher-shell -u neo4j -p testtest
