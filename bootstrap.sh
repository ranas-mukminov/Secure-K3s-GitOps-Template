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

if [[ -f "$ROOT_DIR/.env" ]]; then
  info "Loading .env (not committed)"
  set -a
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
  set +a
elif [[ -f "$ROOT_DIR/.env.example" ]]; then
  warn "No .env found — copy .env.example to .env and fill secrets before deploy"
fi

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

TF_MAIN="$ROOT_DIR/infrastructure/terraform/main.tf"
if [[ ! -f "$TF_MAIN" ]]; then
  warn "Terraform main.tf missing — treat infrastructure/ as stub until you add providers"
fi

if [[ "${SKIP_TERRAFORM_INIT:-}" != "true" ]] && [[ -f "$TF_MAIN" ]]; then
  info "📦 Initializing Terraform providers"
  TF_IN_AUTOMATION=true terraform -chdir="$ROOT_DIR/infrastructure/terraform" init -input=false
  ok "Terraform initialized"
else
  warn "Skipping Terraform init (SKIP_TERRAFORM_INIT=true or no main.tf)"
fi

info "🧭 Next steps"
echo "  • Fill .env / secret manager (Hetzner, SSH key, Cloudflare tunnel)."
echo "  • make install && make deploy — then commit so ArgoCD reconciles."
echo "  • Copy examples/ci/k8s-security-gate.yml → .github/workflows/ when cluster YAML exists."
echo "  • Runtime check: curl -fsSL https://raw.githubusercontent.com/ranas-mukminov/Kube-Simple-Audit/main/audit.sh | bash"
echo "  • Commercial pack: docs/starter-pack-deliverables.md"

echo "🚀 Bootstrap complete"
