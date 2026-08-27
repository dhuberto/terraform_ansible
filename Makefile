.PHONY: help setup tfvars apply destroy clean

# Cores
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
RED    := $(shell tput -Txterm setaf 1)
RESET  := $(shell tput -Txterm sgr0)

help: ## Mostra esta ajuda
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${YELLOW}%-15s${RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Configuração completa do ambiente (bootstrap + tfvars)
	@echo "${GREEN}Iniciando configuração completa...${RESET}"
	@./scripts/bootstrap.sh
	@./scripts/generate-tfvars.sh
	@echo "${GREEN}Configuração concluída!${RESET}"
	@echo "${YELLOW}Próximo passo: cd terraform && terraform init -reconfigure${RESET}"

tfvars: ## Gera o arquivo terraform.tfvars
	@echo "${GREEN}Gerando terraform.tfvars...${RESET}"
	@./scripts/generate-tfvars.sh

bootstrap: ## Cria bucket S3 e tabela DynamoDB
	@echo "${GREEN}Executando bootstrap...${RESET}"
	@./scripts/bootstrap.sh

apply-dev: ## Aplica no ambiente DEV (cria o workspace se não existir)
	@echo "${GREEN}Aplicando ambiente DEV...${RESET}"
	@cd terraform && (terraform workspace new dev 2>/dev/null || terraform workspace select dev) && terraform apply -auto-approve

apply-prod: ## Aplica no ambiente PROD (cria o workspace se não existir)
	@echo "${GREEN}Aplicando ambiente PROD...${RESET}"
	@cd terraform && (terraform workspace new prod 2>/dev/null || terraform workspace select prod) && terraform apply -auto-approve

destroy: ## Destrói todos os recursos (CUIDADO!)
	@echo "${RED}ATENÇÃO: Isso vai destruir TODOS os recursos!${RESET}"
	@read -p "Digite 'sim' para confirmar: " confirm && [ "$$confirm" = "sim" ] || (echo "Cancelado." && exit 1)
	@./scripts/destroy-all.sh

clean: ## Remove arquivos locais (state, .terraform)
	@echo "${YELLOW}Limpando arquivos locais...${RESET}"
	@cd terraform && rm -rf .terraform terraform.tfstate terraform.tfstate.backup
	@echo "${GREEN}Limpeza concluída!${RESET}"
