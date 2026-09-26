# Day-to-prod path

1. **Prerequisites** — `kubectl`, `terraform` ≥ 1.6, `ansible` (recommended), `helm`, Cloudflare account, Hetzner (or adapt Terraform).
2. **Use this template** — create your private repo from the green button.
3. **Secrets** — copy `.env.example` → `.env`; fill tokens. Prefer GitHub Actions secrets / SOPS+age for CI — never commit `.env`.
4. **Bootstrap** — `./bootstrap.sh` validates deps and runs `terraform init` (stub-safe if dirs exist).
5. **Install** — `make install` (wraps bootstrap).
6. **Deploy** — `make deploy` provisions infra; push Git so ArgoCD reconciles `cluster/`.
7. **Verify** — Cloudflare Tunnel up; no public kube-apiserver/SSH; ArgoCD healthy.
8. **Gate + audit** — copy `examples/ci/k8s-security-gate.yml` into `.github/workflows/` when you add manifests; run [Kube-Simple-Audit](https://github.com/ranas-mukminov/Kube-Simple-Audit) one-liner against the live cluster.

Commercial acceleration: [starter-pack-deliverables.md](./starter-pack-deliverables.md).
