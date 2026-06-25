#!/usr/bin/env bash
#
# Build, push, and deploy the Y12WXP tutorial suite to Sky's internal
# Kubernetes cluster behind https://y12wxp-tuts.dev.ce.eu-central-1-aws.npottdc.sky
#
# Usage:
#   ./ci/deploy.sh build                  # docker build
#   ./ci/deploy.sh push                   # docker push (requires registry login)
#   ./ci/deploy.sh apply                  # kubectl apply manifests
#   ./ci/deploy.sh build-deploy           # all of the above
#   ./ci/deploy.sh status                 # show deploy / pods / ingress
#   ./ci/deploy.sh logs [-f]              # pod logs
#   ./ci/deploy.sh restart                # rolling restart
#   ./ci/deploy.sh delete                 # tear down (confirms first)
#
# Override defaults via env vars: NAMESPACE, KUBECTL_CONTEXT, VERSION.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-plutus-tools}"
KUBECTL_CONTEXT="${KUBECTL_CONTEXT:-dev.ce.eu-central-1-aws.npottdc.sky}"
REGISTRY="registry-adapter.tools.cosmic.sky/core-platform/plutus/test/y12wxp/tuts"
VERSION="${VERSION:-$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d-%H%M%S)}"
IMAGE_TAGGED="${REGISTRY}:${VERSION}"
IMAGE_LATEST="${REGISTRY}:latest"
MANIFEST="${REPO_ROOT}/ci/deployment.yaml"

BLU='\033[0;34m'; GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${BLU}[INFO]${NC} $*"; }
ok()    { echo -e "${GRN}[ OK ]${NC} $*"; }
warn()  { echo -e "${YLW}[WARN]${NC} $*"; }
fail()  { echo -e "${RED}[FAIL]${NC} $*" >&2; exit 1; }

require()  { command -v "$1" >/dev/null 2>&1 || fail "$1 not found in PATH"; }

cmd_build() {
  require docker
  info "Building ${IMAGE_TAGGED}"
  docker build --platform linux/amd64 \
    -f "${REPO_ROOT}/ci/Dockerfile" \
    -t "${IMAGE_TAGGED}" \
    -t "${IMAGE_LATEST}" \
    "${REPO_ROOT}"
  ok "Built ${IMAGE_TAGGED}"
}

cmd_push() {
  require docker
  info "Pushing ${IMAGE_TAGGED}"
  docker push "${IMAGE_TAGGED}"
  docker push "${IMAGE_LATEST}"
  ok "Pushed"
}

# Rewrite the image tag in the manifest in-place to point at this version.
stamp_manifest() {
  info "Setting image tag in manifest to ${VERSION}"
  sed -i.bak -E "s|(image: ${REGISTRY}:).*|\1${VERSION}|" "${MANIFEST}"
  rm -f "${MANIFEST}.bak"
}

cmd_apply() {
  require kubectl
  stamp_manifest
  info "Applying manifest to ${NAMESPACE}@${KUBECTL_CONTEXT}"
  kubectl --context "${KUBECTL_CONTEXT}" -n "${NAMESPACE}" apply -f "${MANIFEST}"
  info "Waiting for rollout"
  kubectl --context "${KUBECTL_CONTEXT}" -n "${NAMESPACE}" \
    rollout status deploy/y12wxp-tuts --timeout=180s || warn "rollout timed out"
  cmd_status
  ok "Ingress: https://y12wxp-tuts.dev.ce.eu-central-1-aws.npottdc.sky"
}

cmd_status() {
  require kubectl
  kubectl --context "${KUBECTL_CONTEXT}" -n "${NAMESPACE}" \
    get deploy,svc,ingress,pods -l app=y12wxp-tuts
}

cmd_logs() {
  require kubectl
  kubectl --context "${KUBECTL_CONTEXT}" -n "${NAMESPACE}" \
    logs -l app=y12wxp-tuts --all-containers=true --prefix=true "$@"
}

cmd_restart() {
  require kubectl
  kubectl --context "${KUBECTL_CONTEXT}" -n "${NAMESPACE}" \
    rollout restart deploy/y12wxp-tuts
  kubectl --context "${KUBECTL_CONTEXT}" -n "${NAMESPACE}" \
    rollout status  deploy/y12wxp-tuts --timeout=180s
}

cmd_delete() {
  read -r -p "Really delete y12wxp-tuts from ${NAMESPACE}@${KUBECTL_CONTEXT}? (yes/no) " confirm
  [ "${confirm}" = "yes" ] || { info "Aborted"; exit 0; }
  kubectl --context "${KUBECTL_CONTEXT}" -n "${NAMESPACE}" delete -f "${MANIFEST}" --ignore-not-found
}

case "${1:-help}" in
  build)        cmd_build ;;
  push)         cmd_push ;;
  apply|deploy) cmd_apply ;;
  build-deploy) cmd_build; cmd_push; cmd_apply ;;
  status)       cmd_status ;;
  logs)         shift; cmd_logs "$@" ;;
  restart)      cmd_restart ;;
  delete)       cmd_delete ;;
  *)
    cat <<EOF
Usage: $0 {build|push|apply|build-deploy|status|logs|restart|delete}

Env:
  NAMESPACE        (default: plutus-tools)
  KUBECTL_CONTEXT  (default: dev.ce.eu-central-1-aws.npottdc.sky)
  VERSION          (default: short git sha)

Image: ${REGISTRY}:\$VERSION
Host:  https://y12wxp-tuts.dev.ce.eu-central-1-aws.npottdc.sky
EOF
    ;;
esac
