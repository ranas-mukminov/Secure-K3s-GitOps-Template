SHELL := /bin/bash
ROOT_DIR := $(shell pwd)
TF_DIR := $(ROOT_DIR)/infrastructure/terraform

.PHONY: help install deploy audit

help:
	@echo "Targets: install, deploy, audit"

install:
	@echo "[install] Bootstrapping local environment"
	@$(ROOT_DIR)/bootstrap.sh

deploy:
	@echo "[deploy] Applying infrastructure with Terraform"
	@TF_IN_AUTOMATION=true terraform -chdir=$(TF_DIR) apply -auto-approve
	@echo "[deploy] Commit and push changes so ArgoCD can reconcile"

audit:
	@echo "[audit] Running Terraform fmt/validate"
	@terraform -chdir=$(TF_DIR) fmt -check
	@terraform -chdir=$(TF_DIR) validate
	@echo "[audit] Completed"
