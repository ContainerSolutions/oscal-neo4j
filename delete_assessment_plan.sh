#!/bin/bash
echo 'MATCH (a:assessmentPlan) DETACH DELETE a' | cypher-shell -u neo4j -p testtest
echo 'MATCH (a:parties) DELETE a' | cypher-shell -u neo4j -p testtest
