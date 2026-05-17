# Export Artifacts Guide

This document explains the exported files produced during the Dynatrace MVP alert export phase.

The goal is to make it clear which files came from the Dynatrace Settings API, which files came from Monaco, and how each file is useful for migration analysis.

---

## Dynatrace API Exports

Location:

`configs/dynatrace/api-exports/`

| File | What it is | Why it matters |
|---|---|---|
| `davis-anomaly-detectors-schema.json` | Schema definition for `builtin:davis.anomaly-detectors` | Shows the Dynatrace schema used by the new Anomaly Detection custom alerts |
| `davis-anomaly-detectors.json` | Raw Settings API export of the 3 MVP custom alerts | Main API export artifact for the Dynatrace rules |
| `metric-events.json` | Settings API export attempt for classic metric events | Used to confirm the rules were not stored as classic metric events |
| `mvp-alerts-summary.json` | Cleaned summary of the 3 exported MVP alerts | Human-readable summary for quick review |

Key finding:

The 3 MVP alerts were exported under:

```text
builtin:davis.anomaly-detectors
```

not under:

```text
builtin:anomaly-detection.metric-events
```

---

## Dynatrace Monaco Exports

Location:

`configs/dynatrace/exported/monaco/`

| File / Folder | What it is | Why it matters |
|---|---|---|
| `manifest.yaml` | Monaco manifest file | Defines the Monaco project/environment export structure |
| `dynatrace-mvp-alerts/` | Monaco project folder | Contains the exported Dynatrace configuration project |
| `dynatrace-mvp-alerts/builtindavis.anomaly-detectors/` | Exported schema folder | Contains the exported custom alert definitions |
| `config.yaml` | Monaco config mapping file | Maps exported config IDs to JSON template files and schema metadata |
| `*.json` files | Individual exported alert definitions | Each JSON file represents one Dynatrace MVP alert |

The Monaco export confirmed the same schema:

```text
builtin:davis.anomaly-detectors
```

---

## API Export vs Monaco Export

| Export method | Location | Format | Best use |
|---|---|---|---|
| Settings API | `configs/dynatrace/api-exports/` | Raw JSON response | Easy to inspect with `jq`, useful for API automation |
| Monaco | `configs/dynatrace/exported/monaco/` | Config-as-code structure | Useful for backup, redeployment, templating, and config-as-code workflows |

Important difference:

API export structure:

```text
.items[].value.title
.items[].value.enabled
```

Monaco export structure:

```text
.title
.enabled
.source
.analyzer
.eventTemplate
```

This means a parser written for the API export will not work directly against Monaco files without transformation logic.

---

## Evidence Screenshots

Location:

`evidence/dynatrace/`

| File | What it shows | Why it matters |
|---|---|---|
| `services-visible.png` | Astronomy Shop services visible in Dynatrace | Proves telemetry reached Dynatrace |
| `traces-flowing.png` | Distributed traces visible | Proves trace ingest works |
| `metrics-explorer.png` | Metrics/service graphs visible | Proves service-level metric visibility |
| `rule-01-frontend-p95-latency-preview.png` | Latency alert preview | Proves Rule 1 query returns data |
| `rule-02-frontend-failure-rate-preview.png` | Failure-rate alert preview | Proves Rule 2 query returns data |
| `rule-03-frontend-throughput-drop-preview.png` | Throughput-drop alert preview | Proves Rule 3 query returns data |

---

## Rule Inventory

Location:

`rule-inventory/rule-inventory.md`

| File | What it is | Why it matters |
|---|---|---|
| `rule-inventory.md` | Human-readable inventory of the 3 MVP Dynatrace rules | Main migration tracking document |
| `rule-inventory.csv` | Optional machine-readable version | Useful later for automation or stakeholder review |
| `migration-status-tracker.md` | Optional migration progress tracker | Useful when rebuilding rules in Instana |

---

## Key Migration Lesson

Exporting alerts is not just about downloading files.

The real migration questions are:

1. Which Dynatrace alerting model was used?
2. Which API schema stores that model?
3. Which export method was used?
4. Does the exported structure preserve the query, threshold, event name, and scope?
5. Can the exported rule be mapped cleanly to Instana?

For this MVP, both Settings API and Monaco confirmed that the new Dynatrace custom alerts are stored as Davis anomaly detectors.
