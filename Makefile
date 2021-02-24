isDocker := $(shell docker info > /dev/null 2>&1 && echo 1)

.DEFAULT_GOAL := help
STACK         := joomla
NETWORK       := proxynetwork

APACHE         := $(STACK)_apache
APACHEFULLNAME := $(APACHE).1.$$(docker service ps -f 'name=$(APACHE)' $(APACHE) -q --no-trunc | head -n1)

PHPFPM         := $(STACK)_phpfpm
PHPFPMFULLNAME := $(PHPFPM).1.$$(docker service ps -f 'name=$(PHPFPM)' $(PHPFPM) -q --no-trunc | head -n1)

MAILHOG         := $(STACK)_mailhog
MAILHOGFULLNAME := $(MAILHOG).1.$$(docker service ps -f 'name=$(MAILHOG)' $(MAILHOG) -q --no-trunc | head -n1)

MARIADB         := $(STACK)_mariadb
MARIADBFULLNAME := $(MARIADB).1.$$(docker service ps -f 'name=$(MARIADB)' $(MARIADB) -q --no-trunc | head -n1)

PHPMYADMIN         := $(STACK)_phpmyadmin
PHPMYADMINFULLNAME := $(PHPMYADMIN).1.$$(docker service ps -f 'name=$(PHPMYADMIN)' $(PHPMYADMIN) -q --no-trunc | head -n1)

DOCKER_EXECPHP := @docker exec $(PHPFPMFULLNAME)

SUPPORTED_COMMANDS := contributors docker logs git linter ssh update inspect sleep
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

package-lock.json: package.json
	@npm install

.PHONY: isdocker
isdocker: ## Docker is launch
ifeq ($(isDocker), 0)
	@echo "Docker is not launch"
	exit 1
endif

node_modules: package-lock.json
	@npm install

dump:
	@mkdir dump

folders: dump ## Create folder

contributors: node_modules ## Contributors
ifeq ($(COMMAND_ARGS),add)
	@npm run contributors add
else ifeq ($(COMMAND_ARGS),check)
	@npm run contributors check
else ifeq ($(COMMAND_ARGS),generate)
	@npm run contributors generate
else
	@npm run contributors
endif

.PHONY: sleep
sleep: ## sleep
	@sleep  $(COMMAND_ARGS)

docker: isdocker ## Scripts docker
ifeq ($(COMMAND_ARGS),create-network)
	@docker network create --driver=overlay $(NETWORK)
else ifeq ($(COMMAND_ARGS),deploy)
	@docker stack deploy -c docker-compose.yml $(STACK)
else ifeq ($(COMMAND_ARGS),ls)
	@docker stack services $(STACK)
else ifeq ($(COMMAND_ARGS),stop)
	@docker stack rm $(STACK)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make docker ARGUMENT"
	@echo "---"
	@echo "create-network: create network"
	@echo "deploy: deploy"
	@echo "ls: docker service"
	@echo "stop: docker stop"
endif

logs: isdocker ## Scripts logs
ifeq ($(COMMAND_ARGS),stack)
	@docker service logs -f --tail 100 --raw $(STACK)
else ifeq ($(COMMAND_ARGS),apache)
	@docker service logs -f --tail 100 --raw $(APACHEFULLNAME)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service logs -f --tail 100 --raw $(PHPFPMFULLNAME)
else ifeq ($(COMMAND_ARGS),mailhog)
	@docker service logs -f --tail 100 --raw $(MAILHOGFULLNAME)
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker service logs -f --tail 100 --raw $(MARIADBFULLNAME)
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker service logs -f --tail 100 --raw $(PHPMYADMINFULLNAME)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make logs ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "apache: APACHE"
	@echo "mailhog: MAILHOG"
	@echo "mariadb: MARIADB"
	@echo "phpfpm: PHPFPM"
	@echo "phpmyadmin: PHPMYADMIN"
endif

git: node_modules ## Scripts GIT
ifeq ($(COMMAND_ARGS),status)
	@git status
else ifeq ($(COMMAND_ARGS),check)
	@make bdd validate -i
	@make contributors check -i
	@make linter all -i
	@make git status -i
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make git ARGUMENT"
	@echo "---"
	@echo "check: CHECK before"
	@echo "status: status"
endif

install: folders node_modules ## Installation
	@make docker deploy -i

linter: isdocker node_modules ## Scripts Linter
ifeq ($(COMMAND_ARGS),all)
	@make linter readme -i
else ifeq ($(COMMAND_ARGS),readme)
	@npm run linter-markdown README.md
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make linter ARGUMENT"
	@echo "---"
	@echo "all: ## Launch all linter"
	@echo "readme: linter README.md"
endif

ssh: isdocker ## SSH
ifeq ($(COMMAND_ARGS),apache)
	@docker exec -it $(APACHEFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker exec -it $(PHPFPMFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker exec -it $(PHPFPMFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),mailhog)
	@docker exec -it $(MAILHOGFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker exec -it $(MARIADBFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker exec -it $(PHPMYADMINFULLNAME) /bin/bash
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make ssh ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "apache: APACHE"
	@echo "mailhog: MAILHOG"
	@echo "mariadb: MARIADB"
	@echo "phpfpm: PHPFPM"
	@echo "phpmyadmin: PHPMYADMIN"
endif

update: isdocker ## update
ifeq ($(COMMAND_ARGS),apache)
	@docker service update $(APACHE)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service update $(PHPFPM)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service update $(PHPFPM)
else ifeq ($(COMMAND_ARGS),mailhog)
	@docker service update $(MAILHOG)
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker service update $(MARIADB)
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker service update $(PHPMYADMIN)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make update ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "apache: APACHE"
	@echo "mailhog: MAILHOG"
	@echo "mariadb: MARIADB"
	@echo "phpfpm: PHPFPM"
	@echo "phpmyadmin: PHPMYADMIN"
endif

inspect: isdocker ## inspect
ifeq ($(COMMAND_ARGS),apache)
	@docker service inspect $(APACHE)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service inspect $(PHPFPM)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service inspect $(PHPFPM)
else ifeq ($(COMMAND_ARGS),mailhog)
	@docker service inspect $(MAILHOG)
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker service inspect $(MARIADB)
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker service inspect $(PHPMYADMIN)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make inspect ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "apache: APACHE"
	@echo "mailhog: MAILHOG"
	@echo "mariadb: MARIADB"
	@echo "phpfpm: PHPFPM"
	@echo "phpmyadmin: PHPMYADMIN"
endif
