#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
cd "${SCRIPT_DIR}"/..
docker stop neo4j && docker rm neo4j  && \
docker run \
  --name neo4j \
  -p 7474:7474 \
  -p 7687:7687 \
  -e NEO4J_AUTH=neo4j/testtest \
  -e NEO4J_server_memory_heap_max__size=8G \
  -v $HOME/docker_volumes/neo4j/data:/data \
  -e NEO4J_PLUGINS='["apoc", "graph-data-science"]' \
  -e NEO4J_apoc_import_file_enabled=true \
  -e NEO4J_apoc_import_http_enabled=true \
  -e NEO4J_browser_remote__content__hostname__whitelist='*' \
  -v $(pwd):/import \
  -d \
  neo4j

echo 'Waiting until database started'
while true
do
    echo -n .
	sleep 1
	if docker logs neo4j | grep Started
	then
		break
	fi
done
