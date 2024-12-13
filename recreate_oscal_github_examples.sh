#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
cd "${SCRIPT_DIR}"

./delete_all.sh
./restart_neo4j.sh
./load_oscal_github_examples.sh
