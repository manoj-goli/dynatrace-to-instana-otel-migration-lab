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

## Current Issue #8 Validation Scope

Status: In progress

The current MVP focus is the throughput-drop failure scenario by stopping the Astronomy Shop `load-generator`.

Do not mark Issue #8 complete until screenshots confirm the throughput drop or alert behavior.

Expected evidence:

- `evidence/validation/baseline-instana-throughput.png`
- `evidence/validation/baseline-dynatrace-throughput.png`
- `evidence/validation/instana-throughput-drop-triggered.png`
- `evidence/validation/dynatrace-throughput-drop-triggered.png`
