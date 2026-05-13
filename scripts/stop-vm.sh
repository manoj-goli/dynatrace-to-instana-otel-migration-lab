#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-project-2e1b7100-bf26-4dcf-b0e}"
ZONE="${ZONE:-us-central1-a}"
VM_NAME="${VM_NAME:-otel-mvp-vm}"

gcloud compute instances stop "${VM_NAME}" \
  --project="${PROJECT_ID}" \
  --zone="${ZONE}"
