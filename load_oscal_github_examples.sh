#!/bin/bash

set -euxo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
cd $SCRIPT_DIR

for folder in assessment_plan assessment_result catalog component_definition plan_of_action_and_milestones system_security_plan
do
	cd "${folder}"
	./load_${folder}.sh
	cd ..
done
