# MVP Scope

## Success Criteria

- Astronomy Shop runs on GCP VM.
- Dynatrace receives traces and metrics.
- Instana receives traces and metrics.
- 3 Dynatrace rules created.
- 3 rules mapped and recreated in Instana.
- 1 failure scenario validated.

## Issue #6 Scope Guardrails

Instana OTLP export must be added as a safe dual-export change, not as a replacement for the currently working Dynatrace collector configuration.

The collector templates must preserve the existing local demo exporters:

- traces: `otlp_grpc/jaeger`, `debug`, `spanmetrics`
- metrics: `otlp_http/prometheus`, `debug`
- logs: `opensearch`, `debug`

Exporter naming must match the style already working in this environment:

- Dynatrace OTLP/HTTP: `otlp_http/dynatrace`
- Instana OTLP/HTTP on port `4318`: `otlp_http/instana`
- Instana OTLP/gRPC on port `4317`: `otlp/instana`

For now, Issue #6 only allows safe template files and documentation in the repo. Real Instana endpoints, tenant URLs, agent keys, API tokens, and other secrets must stay only in the VM-side `.env` file and must not be committed.

Issue #6 can only be marked complete after:

- Instana services are visible.
- Instana traces are visible.
- Instana metrics are visible.
- Dynatrace still receives telemetry.
- `evidence/instana/` screenshots are captured.
