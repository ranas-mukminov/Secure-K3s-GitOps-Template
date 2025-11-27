# Secure-K3s-GitOps-Template

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg) ![K3s](https://img.shields.io/badge/K3s-v1.30+-blue.svg) ![Security Scan](https://img.shields.io/badge/Security%20Scan-github--actions-brightgreen)

Vendor-grade, secure-by-default K3s reference built by **Ranas Mukminov** (run-as-daemon.dev). Click **Use this template** to bootstrap a Zero Trust cluster with no exposed ports, Cloudflare Tunnel ingress, and GitOps-first operations with ArgoCD.

## Why this exists
- Zero Trust: no direct SSH, no public kube-api; ingress is brokered by Cloudflare Tunnel.
- GitOps-first: every change is declarative and reconciled by ArgoCD.
- Opinionated security: CIS-inspired hardening via Ansible and locked-down Terraform defaults.

## Repository layout
```
.
├─ .github/workflows/        # CI/security checks
├─ cluster/                  # ArgoCD app-of-apps + Kubernetes manifests
├─ infrastructure/
│  ├─ ansible/               # K3s host hardening playbooks
│  └─ terraform/             # IaC for Hetzner/DO
├─ scripts/                  # Helper utilities
├─ bootstrap.sh              # One-time bootstrap entrypoint
└─ Makefile                  # Common tasks
```

## How to use this template
1. Click **Use this template** → create your repo (private recommended).
2. Generate Cloudflare Tunnel credentials (no open ports) and store them as secrets (e.g., `CLOUDFLARE_TUNNEL_TOKEN`).
3. Add your Terraform/Ansible secrets to your chosen secret manager (GitHub Actions, 1Password, SOPS + age, etc.).
4. Clone your new repo locally and install prerequisites: `kubectl`, `terraform`, `ansible`, `helm`.
5. Review and adapt `infrastructure/terraform/main.tf` variables (location, server type, SSH key refs).
6. Run `./bootstrap.sh` to validate dependencies and prepare the environment.
7. Run `make install` to initialize tooling (Terraform init, provider plugins, pre-commit hooks).
8. Run `make deploy` to provision infrastructure and sync ArgoCD bootstrap manifests.
9. Verify Cloudflare Tunnel connects and that ArgoCD is reconciling apps (no inbound ports exposed).
10. Commit and push. ArgoCD will continuously enforce the desired state from Git.

## Architecture (Zero Trust ingress)
```mermaid
flowchart LR
    User([User]) -->|HTTPS| CF[Cloudflare]
    CF -->|tunnel agent| Tunnel[Cloudflare Tunnel\n(no exposed ports)]
    Tunnel -->|private link| K3s[K3s Control Plane]
    K3s -.->|GitOps sync| ArgoCD[ArgoCD]
```

## Operations
- **Bootstrap:** `./bootstrap.sh` to confirm dependencies and set up local environment.
- **Provision:** `make deploy` provisions Hetzner/DO compute and applies manifests through ArgoCD.
- **Security posture:** Terraform firewalls default to deny-all ingress; ArgoCD and API are only reachable through the tunnel.
- **Hardening:** Ansible playbooks align with CIS guidance; adjust roles in `infrastructure/ansible` per workload needs.

## Contributing
Issues and PRs welcome. Follow the Zero Trust assumptions—no new public ingress, no unmanaged mutations to cluster state.

## License
MIT License. See `LICENSE` for details.

## Enterprise support
Need white-glove onboarding or custom security reviews? [Book a call](https://calendly.com/aleksandrranas/new-meeting).
