# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI catalog characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

help: ## Display this concise help, ie only the porcelain target.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

help-all: ## Display all help items, ie including plumbing targets.
	@awk 'BEGIN {FS = ":.*#"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?#/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

full-rebuild: check-deps restart-neo4j delete-all load-examples startup-instructions  ## Perform a full rebuild of the examples

restart-neo4j:  # Restart neo4j container
	@echo --------------------------------------------------------------------------------
	@echo Restarting Neo4J...
	@./scripts/restart_neo4j.sh
	@echo ...done

delete-all:  # Removes all data attached to neo4j
	@echo --------------------------------------------------------------------------------
	@echo Deleting all...
	@./scripts/delete_all.sh
	@echo ...done

startup-instructions:    # Instructions for accessing the neo4j GUI
	@echo --------------------------------------------------------------------------------
	@echo "Now go to http://localhost:7474/browser/"
	@echo "Login with: neo4j/testtest"
	@echo "Input queries at the 'neo4j$$ ' prompt, eg:"
	@echo "  MATCH (n)-[r]->(m) RETURN n, r, m"

load-examples:   # Load up the oscal examples
	@echo --------------------------------------------------------------------------------
	@echo Loading in the OSCAL examples...
	@./scripts/load_oscal_github_examples.sh
	@echo ...done

check-deps:  # Check required dependencies are in place
	@echo --------------------------------------------------------------------------------
	@echo Checking dependencies...
	@docker ps >/dev/null
	@echo ...done
