#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { echo "ℹ️  $*"; }
ok()    { echo "✅ $*"; }
warn()  { echo "⚠️  $*"; }
fail()  { echo "❌ $*" >&2; exit 1; }

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || fail "Missing required dependency: $cmd"
}

info "🔍 Checking dependencies"
for tool in kubectl terraform; do
  require_cmd "$tool"
  ok "Found $tool"
done

if command -v ansible >/dev/null 2>&1; then
  ok "Found ansible"
else
  warn "ansible not found (recommended for host hardening)"
fi

if command -v helm >/dev/null 2>&1; then
  ok "Found helm"
else
  warn "helm not found (required for some ArgoCD apps)"
fi

info "📂 Ensuring expected directories exist"
for dir in infrastructure/terraform infrastructure/ansible cluster scripts; do
  [[ -d "$ROOT_DIR/$dir" ]] || fail "Missing directory: $dir"
done
ok "Directory layout validated"

if [[ "${SKIP_TERRAFORM_INIT:-}" != "true" ]]; then
  info "📦 Initializing Terraform providers"
  TF_IN_AUTOMATION=true terraform -chdir="$ROOT_DIR/infrastructure/terraform" init -input=false
  ok "Terraform initialized"
else
  warn "Skipping Terraform init (SKIP_TERRAFORM_INIT=true)"
fi

info "🧭 Next steps"
echo "  • Update terraform variables/secrets (Hetzner token, SSH key, Cloudflare tunnel)."
echo "  • Run 'make install' then 'make deploy' to provision and hand off to ArgoCD."

echo "🚀 Bootstrap complete"
