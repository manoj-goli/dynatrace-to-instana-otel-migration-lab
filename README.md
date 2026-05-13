# dynatrace-to-instana-otel-migration-lab

This repository is a migration lab for comparing Dynatrace and Instana using OpenTelemetry telemetry from a sample application.
The MVP focuses on running the Astronomy Shop on a controlled GCP VM, sending traces and metrics to both observability platforms, and documenting rule migration evidence.
The goal is to build a repeatable, low-cost workflow for translating a small set of Dynatrace rules into equivalent Instana configuration.
This project is intentionally staged so infrastructure, platform setup, and automation can be added in later issues.

## MVP Scope

- Run the Astronomy Shop on a GCP VM.
- Send traces and metrics to Dynatrace.
- Send traces and metrics to Instana.
- Create 3 Dynatrace rules.
- Map and recreate those 3 rules in Instana.
- Validate 1 failure scenario.

## Work In Progress

This repository is in early MVP scaffolding. Do not use it as a production migration template yet.

## High-Level Architecture

Placeholder: architecture details will be documented after the local and GCP runtime design is finalized.

## Tech Stack

Placeholder: expected components include OpenTelemetry Collector, Docker Compose, GCP VM, Dynatrace, and Instana.
