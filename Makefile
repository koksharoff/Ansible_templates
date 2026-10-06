ENV       ?= dev
INVENTORY := inventories/$(ENV)/hosts.yml
LIMIT     ?=
TAGS      ?=
ARGS      ?=

ANSIBLE_OPTS := -i $(INVENTORY) $(if $(LIMIT),--limit $(LIMIT)) $(if $(TAGS),--tags $(TAGS)) $(ARGS)

.DEFAULT_GOAL := help
.PHONY: help deps lint syntax ping check deploy bootstrap guard-env guard-prod

help: ## Show available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables: ENV=dev|stage|prod  LIMIT=<host|group>  TAGS=<tag,...>  ARGS='<extra ansible args>'"

deps: ## Install required Ansible collections
	ansible-galaxy collection install -r requirements.yml

lint: ## Run yamllint and ansible-lint
	yamllint .
	ansible-lint

syntax: guard-env ## Syntax-check all playbooks
	ansible-playbook $(ANSIBLE_OPTS) --syntax-check playbooks/bootstrap.yml playbooks/site.yml

ping: guard-env ## Check connectivity to hosts
	ansible all -i $(INVENTORY) $(if $(LIMIT),--limit $(LIMIT)) -m ansible.builtin.ping

check: guard-env ## Dry run of site.yml (shows diff, changes nothing)
	ansible-playbook $(ANSIBLE_OPTS) --check --diff playbooks/site.yml

deploy: guard-env guard-prod ## Apply site.yml
	ansible-playbook $(ANSIBLE_OPTS) --diff playbooks/site.yml

bootstrap: guard-env guard-prod ## First run on fresh hosts (connects as root / cloud user)
	ansible-playbook $(ANSIBLE_OPTS) playbooks/bootstrap.yml

guard-env:
	@test -f $(INVENTORY) || { echo "Unknown environment '$(ENV)': $(INVENTORY) not found"; exit 1; }

guard-prod:
	@if [ "$(ENV)" = "prod" ] && [ "$(CONFIRM)" != "yes" ]; then \
		echo "Refusing to touch prod without CONFIRM=yes"; exit 1; \
	fi
