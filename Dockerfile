# hostile-e2e-runner — sealed-application client runtime.
#
# Python HTTP client only. Suites are mounted at runtime (volume preferred).
# Never bake product source or product e2e trees into this image.
#
# Multi-arch OK (linux/amd64 + linux/arm64 via buildx/QEMU). Unlike
# rust-builder / services-rs server images, this is not a ship binary and
# does not hit aws-lc-rs — pip wheels cover both arches.
FROM python:3.12-slim

LABEL org.opencontainers.image.title="hostile-e2e-runner" \
      org.opencontainers.image.description="Python HTTP client for sealed-application e2e: network-only tests against a shipped binary; no product source." \
      org.opencontainers.image.source="https://forgejo.softwarepatterns.com/softwarepatterns/hostile-e2e-runner" \
      org.opencontainers.image.licenses="MIT"

WORKDIR /e2e

COPY requirements.txt .
ENV PIP_PROGRESS_BAR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=1
RUN pip install --no-cache-dir -r requirements.txt

# Suites come from the product repo via -v …:/e2e (or equivalent).
CMD ["pytest", "-q"]
