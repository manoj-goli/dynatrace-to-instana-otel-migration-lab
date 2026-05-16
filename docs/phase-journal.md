

# Phase Journal — Dynatrace to Instana Observability Migration Lab

This journal tracks the execution progress of the MVP version of the lab.

MVP scope:
- GCP VM
- Docker Compose
- OpenTelemetry Astronomy Shop
- Dynatrace OTLP export
- Instana OTLP export later
- 3 core rules
- 1 validation scenario

---

## Issue #1 — Repository Scaffold

Status: Complete

### What was done

Created the local project repository structure for:

- documentation
- OpenTelemetry Collector configs
- Dynatrace configs
- Instana configs
- Docker Compose overrides
- rule inventory
- evidence screenshots
- future Kubernetes, Terraform, and automation work

Initial files created:

- `README.md`
- `SECURITY.md`
- `LICENSE`
- `.gitignore`
- `docs/architecture.md`
- `docs/cost-control.md`
- `docs/mvp-scope.md`
- `docs/phase-journal.md`
- `docker-compose/.env.example`
- placeholder folders under `configs/`, `evidence/`, `scripts/`, `rule-inventory/`

### Key decisions

- Keep real secrets out of Git.
- Use `.env.example` only for placeholders.
- Keep real `.env` files local to the runtime environment.
- Keep Kubernetes, Terraform, and automation as future phases, not part of MVP.

### Result

Repository scaffold was created locally and pushed to GitHub.

### Lessons learned

The repo structure matters because this project is not just a lab. It is also intended to become a portfolio-ready migration playbook.

---

## Issue #2 — GCP VM and Docker Baseline

Status: Complete

### What was done

Created the GCP baseline infrastructure for the MVP lab.

Provisioned:

- Custom VPC: `otel-mvp-vpc`
- Subnet: `otel-mvp-us-central1`
- VM: `otel-mvp-vm`
- Machine type: `e2-standard-4`
- OS: Ubuntu 22.04.5 LTS
- Boot disk: 40 GB `pd-balanced`
- SSH firewall rule restricted to my public IP only
- No public exposure for OTLP ports `4317` or `4318`
- No public exposure for app port `8080`
- SSH tunnel used for browser access

Verified VM:

```text
Ubuntu 22.04.5 LTS
User: manoj
Docker installed
Docker Compose v2 installed
```

### Cost controls

Created a GCP billing budget:

* Budget: CAD 50
* Alert thresholds:

  * 20% = CAD 10
  * 40% = CAD 20
  * 100% = CAD 50

Configured auto-shutdown:

```text
0 23 * * * /usr/local/bin/auto-shutdown-vm.sh
```

### Key decisions

* Use a custom VPC instead of default VPC for cleaner isolation.
* Use SSH tunneling instead of opening port 8080 publicly.
* Do not create broad service account permissions.
* Do not use GKE for MVP.

### Result

GCP VM was ready with Docker and Docker Compose.

### Lessons learned

For a lab like this, security and cost control should be built in from the start. The VM only needs outbound access to send telemetry to SaaS tools. It does not need public OTLP ports.

---

## Issue #3 — OpenTelemetry Astronomy Shop Baseline

Status: Complete

### What was done

Cloned and started the OpenTelemetry Astronomy Shop demo on the GCP VM using Docker Compose.

Verified:

* Docker Compose stack started successfully.
* Astronomy Shop frontend was accessible using SSH tunnel.
* Browser access worked through:

```text
http://localhost:8080
```

Validated basic user flow:

* Browse products
* Open product details
* Add item to cart
* Checkout flow

### Access method

Used SSH local port forwarding from local machine to VM:

```powershell
gcloud compute ssh otel-mvp-vm `
  --project=project-2e1b7100-bf26-4dcf-b0e `
  --zone=us-central1-a `
  --ssh-flag="-L 8080:localhost:8080"
```

### Key decisions

* Do not start Dynatrace trial until the demo app is confirmed running.
* Use the existing OpenTelemetry demo collector instead of installing a separate collector from scratch.
* Treat this as the known-good baseline before adding external observability backends.

### Result

Astronomy Shop was running successfully on the VM.

### Lessons learned

The demo already includes multiple services and an OpenTelemetry Collector. This means the lab starts with a realistic microservices telemetry pipeline instead of a simple single-service app.

---

## Issue #4 — Dynatrace OTLP Export

Status: Complete

### What was done

Started Dynatrace free trial and configured the OpenTelemetry Collector to export telemetry to Dynatrace.

Created Dynatrace access token with required ingest scopes:

* `openTelemetryTrace.ingest`
* `metrics.ingest`
* `logs.ingest`

Added Dynatrace values to the VM-side `.env` file:

```text
DT_ENDPOINT=https://kdb75523.live.dynatrace.com/api/v2/otlp
DT_API_TOKEN=***REDACTED***
```

Updated the OpenTelemetry Collector extras config:

```text
src/otel-collector/otelcol-config-extras.yml
```

Added Dynatrace as an OTLP HTTP exporter for:

* traces
* metrics
* logs

### Important blocker encountered

The first collector restart failed because the collector container could not read the `.env` variables.

Error observed:

```text
Configuration references unset environment variable "DT_ENDPOINT"
Configuration references unset environment variable "DT_API_TOKEN"
```

Root cause:

The `.env` file existed on the VM, but the `otel-collector` container did not automatically receive those environment variables.

Fix:

Added this to `docker-compose.override.yml`:

```yaml
services:
  otel-collector:
    env_file:
      - .env
```

Then recreated the collector:

```bash
docker compose up -d --force-recreate otel-collector
```

### Validation

Dynatrace successfully showed:

* Astronomy Shop services
* Distributed traces
* Request data
* Service metrics such as response time, failure rate, throughput, and HTTP errors

Evidence captured:

* `evidence/dynatrace/services-visible.png`
* `evidence/dynatrace/traces-flowing.png`
* `evidence/dynatrace/metrics-explorer.png`

### Known warning

Collector logs showed partial success warnings for some unsupported collector self-metrics.

Example:

```text
Unsupported metric type
Partial success response
```

This did not block the main goal because service traces, requests, and service-level metrics were visible in Dynatrace.

### Result

Dynatrace OTLP telemetry export is working.

### Lessons learned

This was the first real observability troubleshooting moment in the lab.

The issue was not with Dynatrace, not with the token, and not with the application. The problem was environment variable scope:

```text
Local machine repo
  → only stores safe templates and docs

GCP VM
  → stores the real .env file

Docker container
  → must explicitly receive env vars using env_file or environment
```

This is a very realistic DevOps/SRE issue because many production telemetry failures come from configuration scope, secrets injection, or runtime environment mismatch.

---

## Current MVP Progress

| Issue | Description                         | Status      |
| ----- | ----------------------------------- | ----------- |
| #1    | Repository scaffold                 | Complete    |
| #2    | GCP VM and Docker baseline          | Complete    |
| #3    | Astronomy Shop running              | Complete    |
| #4    | Dynatrace OTLP export               | Complete    |
| #5    | Create 3 Dynatrace rules and export | Next        |
| #6    | Configure Instana OTLP export       | Not started |
| #7    | Map and rebuild 3 rules in Instana  | Not started |
| #8    | Validate with one failure scenario  | Not started |

---

## Next Step

Proceed to Issue #5:

Create 3 core Dynatrace rules:

1. Checkout or frontend p95 latency
2. Payment or frontend error rate
3. VM CPU saturation, if host CPU metric is available

If host CPU is not available through OTLP-only setup, replace the CPU rule temporarily with a throughput or HTTP error rule.

Key principle:

Before creating any alert rule, first confirm the metric exists, is reliable, and has enough data to alert on.

Small note: your MVP backlog defines the execution order and confirms Issue #5 is the next step after Dynatrace OTLP connectivity.
---

Date: May 15, 2026

## Issue #5 Adjustment — Replacing VM CPU Rule

During Dynatrace validation, I confirmed that the current MVP uses the OpenTelemetry demo’s in-container telemetry pipeline only. Since no Dynatrace OneAgent or OpenTelemetry hostmetrics receiver is installed on the VM, VM-level CPU saturation is not available as a reliable signal yet.

Decision:
Replace the VM CPU saturation rule in the MVP with an application-level rule based on already-verified Dynatrace service telemetry.

Updated MVP rules:
1. Frontend or checkout latency
2. Frontend or payment error rate
3. Frontend HTTP errors or throughput

Reason:
A reliable alert should only be created from telemetry that exists, updates consistently, and maps to real service behavior.
---
