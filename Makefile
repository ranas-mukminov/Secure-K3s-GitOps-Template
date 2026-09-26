SHELL := /bin/bash
ROOT_DIR := $(shell pwd)
TF_DIR := $(ROOT_DIR)/infrastructure/terraform

.PHONY: help install deploy audit audit-cluster

help:
	@echo "Targets: install, deploy, audit, audit-cluster"
	@echo "  install        - bootstrap local env"
	@echo "  deploy         - terraform apply (needs secrets)"
	@echo "  audit          - terraform fmt/validate"
	@echo "  audit-cluster  - run Kube-Simple-Audit one-liner (needs kubectl)"

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

audit-cluster:
	@curl -fsSL https://raw.githubusercontent.com/ranas-mukminov/Kube-Simple-Audit/main/audit.sh | bash -s -- --markdown
