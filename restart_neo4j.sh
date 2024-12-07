#!/bin/bash
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
  -d \
  neo4j