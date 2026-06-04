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

- Budget: CAD 50
- Alert thresholds:

  - 20% = CAD 10
  - 40% = CAD 20
  - 100% = CAD 50

Configured auto-shutdown:

```text
0 23 * * * /usr/local/bin/auto-shutdown-vm.sh
```

### Key decisions

- Use a custom VPC instead of default VPC for cleaner isolation.
- Use SSH tunneling instead of opening port 8080 publicly.
- Do not create broad service account permissions.
- Do not use GKE for MVP.

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

- Docker Compose stack started successfully.
- Astronomy Shop frontend was accessible using SSH tunnel.
- Browser access worked through:

```text
http://localhost:8080
```

Validated basic user flow:

- Browse products
- Open product details
- Add item to cart
- Checkout flow

### Access method

Used SSH local port forwarding from local machine to VM:

```powershell
gcloud compute ssh otel-mvp-vm `
  --project=project-2e1b7100-bf26-4dcf-b0e `
  --zone=us-central1-a `
  --ssh-flag="-L 8080:localhost:8080"
```

### Key decisions

- Do not start Dynatrace trial until the demo app is confirmed running.
- Use the existing OpenTelemetry demo collector instead of installing a separate collector from scratch.
- Treat this as the known-good baseline before adding external observability backends.

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

- `openTelemetryTrace.ingest`
- `metrics.ingest`
- `logs.ingest`

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

- traces
- metrics
- logs

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

- Astronomy Shop services
- Distributed traces
- Request data
- Service metrics such as response time, failure rate, throughput, and HTTP errors

Evidence captured:

- `evidence/dynatrace/services-visible.png`
- `evidence/dynatrace/traces-flowing.png`
- `evidence/dynatrace/metrics-explorer.png`

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

| Issue | Description | Status |
|---|---|---|
| #1 | Repository scaffold | Complete |
| #2 | GCP VM and Docker baseline | Complete |
| #3 | Astronomy Shop running | Complete |
| #4 | Dynatrace OTLP export | Complete |
| #5 | Create 3 Dynatrace rules and export | Complete |
| #6 | Configure Instana OTLP export (dual-export) | Complete |
| #7 | Map and rebuild 3 rules in Instana | Complete |
| #8 | Validate with one failure scenario | Validation complete / evidence cleanup pending |
| #9 | Semi-automated rule migration tool | Phase 1 active |

---

## Next Step

Proceed with Issue #9 Phase 1 planning and scaffold.

Issue #9 creates the safe structure and documentation for a semi-automated Dynatrace to Instana rule migration workflow. Phase 1 does not implement parser, mapper, API client, Terraform, or alert creation logic.

---

## Issue #5 — Create 3 Dynatrace MVP Rules and Export

Status: Complete

Date: May 15, 2026

### VM CPU Rule Adjustment

During Dynatrace validation, I confirmed that the current MVP uses the OpenTelemetry demo's in-container telemetry pipeline only. Since no Dynatrace OneAgent or OpenTelemetry hostmetrics receiver is installed on the VM, VM-level CPU saturation is not available as a reliable signal yet.

Decision:

Replace the VM CPU saturation rule in the MVP with an application-level rule based on already-verified Dynatrace service telemetry.

Updated MVP rules:

1. Frontend or checkout latency
2. Frontend or payment error rate
3. Frontend HTTP errors or throughput

Reason:

A reliable alert should only be created from telemetry that exists, updates consistently, and maps to real service behavior.

---

### API Export Progress

Exported the 3 MVP Dynatrace alerts using the Settings API.

The alerts were found under:

`builtin:davis.anomaly-detectors`

Confirmed exported rules:

- MVP - Frontend P95 Latency High
- MVP - Frontend Failure Rate High
- MVP - Frontend Throughput Drop

All 3 were enabled.

Key lesson:

The new Dynatrace Anomaly Detection custom alerts are stored as Davis anomaly detectors, not classic metric events. This matters for migration because different alerting models require different export schemas.

## Key Migration Lesson

Exporting alerts is not just about downloading files.

The real migration questions are:

1. Which Dynatrace alerting model was used?
2. Which API schema stores that model?
3. Which export method was used?
4. Does the exported structure preserve the query, threshold, event name, and scope?
5. Can the exported rule be mapped cleanly to Instana?

For this MVP, both Settings API and Monaco confirmed that the new Dynatrace custom alerts are stored as Davis anomaly detectors.

### Export Artifact Notes

Created `docs/export-artifacts.md` to document the purpose of each export file and folder.

This was added because the Dynatrace Settings API and Monaco export the same alert rules in different JSON structures. The artifact guide helps distinguish API exports, Monaco config-as-code exports, screenshots, and rule inventory files.

---

## Issue #6 — Instana OTLP Export (Dual-Export)

Status: Completed

Date: May 25–26, 2026

### Goal

Configure IBM Instana to receive OTLP telemetry from the existing OpenTelemetry Collector while keeping Dynatrace export active.

Target architecture:

```text
Astronomy Shop services
  → OpenTelemetry Collector
    → Dynatrace
    → Instana
````

### Repo preparation completed

Prepared the repo-side configuration templates and documentation:

* Created `configs/otel-collector/otelcol-config-extras-instana.yaml`
* Created `configs/otel-collector/otelcol-config-extras-dual.yaml`
* Updated `docker-compose/.env.example` with Instana placeholder variables
* Used `${env:INSTANA_OTLP_ENDPOINT}` and `${env:INSTANA_AGENT_KEY}` references only
* No real Instana endpoint, key, tenant URL, or token was committed
* Preserved local demo exporters instead of replacing them with a simplified backend-only config
* Used the current working exporter naming style:

  * `otlp_http/dynatrace`
  * `otlp_http/instana`

Preserved local exporters:

* traces: `otlp_grpc/jaeger`, `debug`, `spanmetrics`
* metrics: `otlp_http/prometheus`, `debug`
* logs: `opensearch`, `debug`

### VM execution completed so far

Added Instana OTLP values to the VM-side `.env` file only:

```text
INSTANA_OTLP_ENDPOINT=***SET ON VM ONLY***
INSTANA_AGENT_KEY=***REDACTED***
```

Recreated the `otel-collector` container so it could reload `.env`.

Verified that the collector receives the new environment variables using `docker inspect`, instead of `docker compose exec`, because the collector image may not include shell utilities.

Configured the existing Astronomy Shop `otel-collector` container for dual export.

Current pipeline:

* traces: local Jaeger/debug/spanmetrics + Dynatrace + Instana
* metrics: local Prometheus/debug + Dynatrace + Instana
* logs: local OpenSearch/debug + Dynatrace only

### Blocker encountered

Initial dual-export config sent logs to Instana:

```text
logs → opensearch + debug + Dynatrace + Instana
```

Instana returned HTTP 402 for log ingest:

```text
None of the tenants are permitted to send log data
```

### Decision

Removed Instana from the logs pipeline only.

Reason:

Logs are best-effort for Issue #6. Traces and metrics are the mandatory success criteria.

Final logs pipeline:

```text
logs → opensearch + debug + Dynatrace
```

Instana remains active for:

```text
traces
metrics
```

### Validation completed so far

Collector logs show:

* traces flowing
* metrics flowing
* no more Instana HTTP 402 log-ingest errors after removing Instana from the logs pipeline
* Dynatrace still receives telemetry, with the same known partial metric warnings seen earlier

The remaining Dynatrace partial-success metric warnings are not blocking because they are related to unsupported metric types, not a broken pipeline.

### Validation still remaining

Issue #6 is not complete until the Instana UI confirms:

* Instana shows Astronomy Shop services
* Instana shows distributed traces
* Instana shows service-level metrics
* Dynatrace still receives recent telemetry after Instana was added

### Evidence to capture

Save screenshots under:

```text
evidence/instana/
```

Expected files:

* `services-visible.png`
* `traces-flowing.png`
* `metrics-visible.png`
* `dynatrace-still-active.png`
* `logs-attempt.png` if useful, showing that logs were attempted but blocked by tenant permissions

### Lessons learned

* Reusing the existing Astronomy Shop OpenTelemetry Collector is cleaner than installing a second collector.
* Dual export is a collector fan-out pattern: one telemetry source can send to multiple backends.
* Adding values to `.env` does not update a running container; the collector must be recreated.
* `docker inspect` is safer than `docker compose exec` for minimal collector images.
* Not every telemetry signal is supported or enabled in every SaaS trial. In this case, Instana log ingest returned HTTP 402, so logs were documented as best-effort.
* When one signal fails, remove only the failing exporter path instead of disabling the whole backend integration.

### Next step

Check the Instana UI for services, traces, and metrics.

### Final validation

Issue #6 validation completed successfully.

Confirmed:

- Instana shows Astronomy Shop services.
- Instana shows service-level metrics including calls, erroneous call rate, and latency.
- Instana shows distributed traces with span timelines.
- Dynatrace still receives recent distributed traces after Instana was added.
- Instana log export was attempted but returned HTTP 402 because the tenant is not permitted to send log data.

Decision:

Instana logs are documented as best-effort and not a blocker for the MVP. Traces and metrics are the required success criteria for Issue #6.

Evidence captured:

- `evidence/instana/services-summary-visible.png`
- `evidence/instana/services-table-visible.png`
- `evidence/instana/traces-flowing.png`
- `evidence/instana/dynatrace-still-active.png`

## Issue #7 — Rebuild Dynatrace MVP Rules in Instana

Status: Complete

Date: May 26, 2026

### What was done

Rebuilt the 3 Dynatrace MVP rules in Instana as Global Application Smart Alerts.

Created Instana rules:

1. MVP 1 - Frontend P95 Latency High
2. MVP 2 - Frontend Failure Rate High
3. MVP 3 - Frontend Throughput Drop

### Mapping summary

| Dynatrace rule | Instana rule | Signal mapping | Condition |
|---|---|---|---|
| MVP - Frontend P95 Latency High | MVP 1 - Frontend P95 Latency High | p95 response time → latency 95th percentile | Latency >= 500 ms |
| MVP - Frontend Failure Rate High | MVP 2 - Frontend Failure Rate High | failure rate % → error rate | Error rate > 5% |
| MVP - Frontend Throughput Drop | MVP 3 - Frontend Throughput Drop | request rate → calls | Calls < 1 |

### Evidence captured

- `evidence/instana/instana-smart-alerts-list.png`
- `evidence/instana/rule-01-frontend-p95-latency-high.png`
- `evidence/instana/rule-02-frontend-failure-rate-high.png`
- `evidence/instana/rule-03-frontend-throughput-drop.png`

### Lessons learned

- Dynatrace alerts were exportable through API/Monaco, but Instana rules were rebuilt manually through Smart Alerts.
- Rule migration required mapping by reliability signal, not by direct file import.
- Latency and error-rate rules mapped cleanly.
- Throughput-drop rule required checking the actual saved threshold because the Instana list view may round or simplify small displayed values.

---

## New Dynatrace Tenant Rehydration

Status: Complete

The original Dynatrace trial expired before Issue #8 validation was finished. A new Dynatrace tenant was created and the VM-side Dynatrace ingest settings were updated.

What was done:

- Updated the VM-side `DT_ENDPOINT` and `DT_API_TOKEN` values.
- Recreated the collector so it loaded the new Dynatrace ingest settings.
- Confirmed telemetry reached the new Dynatrace tenant.
- Manually recreated the 3 Dynatrace MVP rules in the new tenant.

No real tenant URLs, tokens, or secrets are stored in the repo.

### Monaco dry-run vs real deploy finding

The existing Monaco export was updated to point at the new Dynatrace tenant.

Result:

- `monaco deploy --dry-run manifest.yaml` passed.
- Real `monaco deploy manifest.yaml` failed for `builtin:davis.anomaly-detectors`.
- The failure message included: `Could not do validation as request was not done using oAuth.`

Decision:

This is not a blocker for the MVP because the 3 rules were manually recreated in the new Dynatrace tenant.

Lesson:

Exportability does not always equal redeployability. The Monaco export remains useful as a source/config artifact, but some Davis anomaly detector deploy paths may require OAuth-backed validation.

---

## Issue #8 - Throughput-Drop Failure Validation

Status: Validation complete / evidence cleanup pending

Goal:

Validate one failure scenario by stopping the Astronomy Shop `load-generator` and confirming the throughput/calls drop is visible in Dynatrace and Instana.

### Issue #8 Validation Result - Throughput Drop

Validated the throughput-drop failure scenario by stopping the `load-generator` container.

Observed result:

- Throughput-drop behavior was visible in both tools.
- Instana generated an active Smart Alert for the throughput-drop scenario in the first validation run.
- In repeated short start/stop tests, Instana showed the Calls graph dropping but did not create additional Smart Alerts.
- Dynatrace showed the frontend request throughput drop in the DQL preview.
- Dynatrace successfully simulated the equivalent throughput-drop alert after the threshold was recalibrated from an exact low threshold to match Dynatrace's request-rate scale.
- Repeated tests showed platform-specific differences in alert timing, deduplication, persistence, and no-data handling.

Final validated rule behavior:

| Platform | Rule | Signal | Condition | Result |
|---|---|---|---|---|
| Instana | MVP 3 - Frontend Throughput Drop | Calls | Calls < 1 | Active Smart Alert created in initial run; repeated short start/stop tests showed graph drops but no additional alert |
| Dynatrace | MVP 3 - Frontend Throughput Drop | `request_rate` from `dt.service.request.count` | request_rate < 300 | Simulated alert generated |

Dynatrace DQL used:

```dql
timeseries request_rate = sum(dt.service.request.count, rate: 1m),
  by: {dt.smartscape.service},
  interval: 1m
| fieldsAdd service_name = getNodeName(dt.smartscape.service)
| filter service_name == "frontend"
```

Key migration lesson:

The same alert intent did not use the same numeric threshold across platforms. Instana and Dynatrace exposed similar throughput behavior using different metric semantics and alert evaluation models. Therefore, alert migration required threshold recalibration and validation of platform-specific alert behavior instead of a direct one-to-one copy.

Evidence captured:

- `evidence/validation/instana-throughput-drop-triggered.png`
- `evidence/validation/instana-throughput-drop-no-repeat-alert.png`
- `evidence/validation/dynatrace-throughput-drop-simulated.png`
- `evidence/validation/dynatrace-throughput-drop-simulated-retested.png`
- `evidence/validation/baseline-instana-throughput.png`
- `evidence/validation/baseline-dynatrace-throughput.png`

Status note:

Issue #8 validation is complete based on the documented platform behavior and saved evidence. Evidence cleanup remains because some saved filenames differ from earlier expected names.

---

## Issue #9 - Semi-Automated Dynatrace to Instana Rule Migration Tool

Status: Phase 1 active

Goal:

Create a semi-automated workflow that takes Dynatrace alert exports, normalizes and classifies them, maps them to Instana Smart Alert candidates, and generates reviewable outputs before any API creation is attempted.

Why this was added:

Manual Instana alert rebuilding worked for the 3-rule MVP, but it does not scale to 100+ rules. The Issue #7 and Issue #8 work showed that migration needs translation by alert intent, not direct file import or blind threshold copying.

Target workflow:

```text
Dynatrace API / Monaco export
  -> parse
  -> normalize
  -> classify
  -> map
  -> generate review outputs
  -> human review
  -> optional API/Terraform creation later
```

Phase boundaries:

- Phase 1: Planning and scaffold only.
- Phase 2: Dynatrace parser and normalizer.
- Phase 3: Classifier, Instana candidate mapper, and review outputs.
- Phase 4: Instana API/Terraform creation, only after validation.

v1 rule:

Generate review outputs only. Do not call Dynatrace APIs, call Instana APIs, create alerts, edit secrets, or run live platform commands.

Mapping seed examples:

| Dynatrace rule | Instana candidate | Confidence | Review reason |
|---|---|---|---|
| MVP - Frontend P95 Latency High | Slowness Smart Alert | High | Unit conversion from microseconds to milliseconds |
| MVP - Frontend Failure Rate High | Erroneous Calls Smart Alert | High | Direct percentage mapping |
| MVP - Frontend Throughput Drop | Throughput Smart Alert | Medium | Threshold recalibration and platform-specific metric semantics |

Risks:

- Thresholds may need recalibration per platform.
- Metric semantics may differ even when alert intent is the same.
- Missing-data behavior, repeated alert behavior, persistence, and deduplication can differ by platform.
- Davis AI, SLO, log-based, baseline, or complex DQL alerts may be unsupported in v1.
- Phase 4 requires validation of Instana payloads, Application Perspective IDs, and alert channel IDs.
