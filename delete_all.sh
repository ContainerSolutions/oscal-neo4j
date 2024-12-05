#!/bin/bash
echo 'MATCH (n) DETACH DELETE n' | cypher-shell -u neo4j -p testtest

# Remove indices
echo 'SHOW INDEXES' | cypher-shell -u neo4j -p testtest | awk '{print $2}' | grep _idx | tr -d ',"' | sed 's/^\(.*\)/DROP INDEX \1;/g'  | cypher-shell -u neo4j -p testtest
echo 'SHOW CONSTRAINTS' | cypher-shell -u neo4j -p testtest | awk '{print $2}' | grep _idx | tr -d ',"' | sed 's/^\(.*\)/DROP CONSTRAINT \1;/g'  | cypher-shell -u neo4j -p testtest
