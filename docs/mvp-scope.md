# MVP Scope

## Success Criteria

- Astronomy Shop runs on GCP VM.
- Dynatrace receives traces and metrics.
- Instana receives traces and metrics.
- 3 Dynatrace rules created.
- 3 rules mapped and recreated in Instana.
- 1 failure scenario validated.

## Issue #6 Scope Guardrails

Status: Complete

Instana OTLP export must be added as a safe dual-export change, not as a replacement for the currently working Dynatrace collector configuration.

The collector templates must preserve the existing local demo exporters:

- traces: `otlp_grpc/jaeger`, `debug`, `spanmetrics`
- metrics: `otlp_http/prometheus`, `debug`
- logs: `opensearch`, `debug`

Exporter naming must match the style already working in this environment:

- Dynatrace OTLP/HTTP: `otlp_http/dynatrace`
- Instana OTLP/HTTP on port `4318`: `otlp_http/instana`
- Instana OTLP/gRPC on port `4317`: `otlp/instana`

Issue #6 used safe template files and documentation in the repo. Real Instana endpoints, tenant URLs, agent keys, API tokens, and other secrets stayed only in the VM-side `.env` file and were not committed.

Issue #6 was marked complete after:

- Instana services are visible.
- Instana traces are visible.
- Instana metrics are visible.
- Dynatrace still receives telemetry.
- `evidence/instana/` screenshots are captured.

## Issue #8 Validation Scope

Status: Validation complete / evidence cleanup pending

Issue #8 validated the throughput-drop failure scenario by stopping the Astronomy Shop `load-generator`.

Evidence filenames differ from the original expected list, so final cleanup should reconcile the documented evidence list with the files saved under `evidence/validation/`.

Saved evidence includes:

- `evidence/validation/baseline-instana-throughput.png`
- `evidence/validation/baseline-dynatrace-throughput.png`
- `evidence/validation/instana-throughput-drop-no-repeat-alert.png`
- `evidence/validation/dynatrace-throughput-drop-simulated.png`

## Issue #9 Scope: Semi-Automated Rule Migration Tool

Status: Phase 1 active

Issue #9 is part of active project scope, not a future backlog item.

The goal is to create a semi-automated workflow that takes Dynatrace alert exports, normalizes and classifies them, maps them to Instana Smart Alert candidates, and generates reviewable outputs before any API creation is attempted.

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

v1 is generate-only and makes no live Dynatrace or Instana API calls.

Manual Instana alert rebuilding is useful for discovery, but it does not scale to 100+ rules. Exported Dynatrace rules are source artifacts, not directly importable Instana configs.

Phase boundaries:

- Phase 1: Planning and scaffold only.
- Phase 2: Dynatrace parser and normalizer.
- Phase 3: Classifier, Instana candidate mapper, and review outputs.
- Phase 4: Instana API/Terraform creation, only after tenant validation.

Phase 4 requires validation of Instana API payloads, Application Perspective IDs, alert channel IDs, and tenant-specific behavior before any live creation.

Output locations:

- `rule-migration-tool/outputs/`: local/generated working outputs from the tool.
- `rule-inventory/generated/`: curated/reviewed migration outputs that may be committed later.
