# Deployment

The tutorial suite under `tuts/` is served as a static site by an
nginx container on Sky's internal Kubernetes cluster.

**URL:** https://y12wxp-tuts.dev.ce.eu-central-1-aws.npottdc.sky
**Cluster:** `dev.ce.eu-central-1-aws.npottdc.sky` · **Namespace:** `plutus-tools`
**Image:** `registry-adapter.tools.cosmic.sky/core-platform/plutus/test/y12wxp/tuts`

## Files

| File | Purpose |
|------|---------|
| `Dockerfile`       | Builds an `nginxinc/nginx-unprivileged` image with `tuts/` baked in |
| `nginx.conf`       | Static-file config (gzip, cache headers, `/health`) |
| `deployment.yaml`  | K8s `Deployment` + `Service` + `Ingress` |
| `deploy.sh`        | Build / push / apply helper |
| `.dockerignore`    | Keeps the image small |

## Quick deploy

Prerequisites: Docker Desktop running, VPN connected, registry login,
`kubectl` configured for context `dev.ce.eu-central-1-aws.npottdc.sky`.

```bash
# One-shot: build, push, apply
./ci/deploy.sh build-deploy

# Or step by step
./ci/deploy.sh build
./ci/deploy.sh push
./ci/deploy.sh apply
```

## Operations

```bash
./ci/deploy.sh status
./ci/deploy.sh logs -f
./ci/deploy.sh restart
./ci/deploy.sh delete    # tears everything down (prompts first)
```

## Notes

- The image tag is the short git sha; `deploy.sh apply` rewrites
  `deployment.yaml` to pin that tag.
- The container is non-root (uid 101), read-only root filesystem, with
  `emptyDir` mounts for nginx tmp paths — matching the cluster's
  security context constraints.
- The ingress uses the same `sky.uk/*` annotations as the reference
  `plutus-tools/gha-board` deployment.
