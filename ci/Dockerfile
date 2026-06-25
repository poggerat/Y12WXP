# Static-content image for the Y12WXP tutorial suite.
# Build context: repository root.
#
#   docker build -f ci/Dockerfile -t <image> .
#
# Uses the unprivileged variant of nginx so the container can run as a
# non-root user and satisfy the cluster's security context constraints
# (readOnlyRootFilesystem, runAsNonRoot, drop ALL caps).
FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY ci/nginx.conf /etc/nginx/conf.d/default.conf
COPY tuts/        /usr/share/nginx/html/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1
