# dynatrace-to-instana-otel-migration-lab

This repository is a migration lab for comparing Dynatrace and Instana using OpenTelemetry telemetry from a sample application.
The MVP focuses on running the Astronomy Shop on a controlled GCP VM, sending traces and metrics to both observability platforms, and documenting rule migration evidence.
The goal is to build a repeatable, low-cost workflow for translating Dynatrace alert intent into equivalent Instana configuration.
This project is intentionally staged so infrastructure, platform setup, and automation can be added in later issues.

## MVP Scope

- Run the Astronomy Shop on a GCP VM.
- Send traces and metrics to Dynatrace.
- Send traces and metrics to Instana.
- Create 3 Dynatrace rules.
- Map and recreate those 3 rules in Instana.
- Validate 1 failure scenario.

## Active Scope: Issue #9

Issue #9 adds a semi-automated Dynatrace to Instana rule migration tool as an active project workstream.

Manual Instana alert rebuilding worked for the 3 MVP rules, but it does not scale to 100+ rules. The next workflow is:

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

v1 is generate-only. It creates reviewable CSV, JSON, and Markdown outputs and makes no live Dynatrace or Instana API calls.

Exported Dynatrace rules are source artifacts, not directly importable Instana configs.

## Work In Progress

This repository is an MVP migration lab in progress. Issues #1-#7 are complete. Issue #8 validation is complete with evidence cleanup pending. Issue #9 is active for planning and safe scaffold work. Do not use it as a production migration template yet.

## High-Level Architecture

Placeholder: architecture details will be documented after the local and GCP runtime design is finalized.

## Tech Stack

Placeholder: expected components include OpenTelemetry Collector, Docker Compose, GCP VM, Dynatrace, and Instana.
