# Rule Inventory — Dynatrace MVP Rules

## Summary

This inventory captures the 3 Dynatrace MVP alerts created for the OpenTelemetry Astronomy Shop demo. These rules are based on verified service-level telemetry exported from the OpenTelemetry Collector to Dynatrace.

## Rules

| # | Rule name | Signal | Scope | Query dimension | Threshold | Condition | Dynatrace type | Expected Instana equivalent | Migration difficulty | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | MVP - Frontend P95 Latency High | Service response time p95 | frontend | dt.smartscape.service | 500000 microseconds | Above threshold | Anomaly Detection custom alert, static threshold | Instana Smart Alert, latency | Easy | 500000 microseconds = 500 ms. Unit conversion was unavailable, so raw metric unit was used. |
| 2 | MVP - Frontend Failure Rate High | Service failure rate percentage | frontend | dt.smartscape.service | 5 | Above threshold | Anomaly Detection custom alert, static threshold | Instana Smart Alert, error rate | Easy | Query calculates `100 * failures / total`, so threshold 5 means 5%. |
| 3 | MVP - Frontend Throughput Drop | Service request rate | frontend | dt.smartscape.service | 300 requests/min | Below threshold | Anomaly Detection custom alert, static threshold | Instana Smart Alert, throughput / traffic drop | Medium | Normal observed traffic was around 500 requests/min. Tested by stopping load-generator. |

## Validation notes

- All 3 alert preview queries returned data for the frontend service.
- `dt.smartscape.service` worked as the correct grouping dimension.
- `dt.source_entity` returned no data for the failure-rate query, so it was not used for the MVP.
- Throughput-drop validation was tested by stopping the `load-generator` container.

## Dynatrace API Export Finding

The 3 MVP alerts were successfully exported through the Dynatrace Settings API using the schema:

`builtin:davis.anomaly-detectors`

Exported alerts:

- MVP - Frontend P95 Latency High
- MVP - Frontend Failure Rate High
- MVP - Frontend Throughput Drop

All 3 alerts were enabled at export time.

Important finding:

These alerts were not stored as classic metric events. They were stored as Davis anomaly detector custom alerts. This means Dynatrace alert export depends heavily on the alerting model and schema used.

For this MVP:

| UI concept | API schema |
|---|---|
| Anomaly Detection custom alert | `builtin:davis.anomaly-detectors` |
| Classic metric event | `builtin:anomaly-detection.metric-events` |

Migration note:

When migrating Dynatrace rules to Instana, the first step is not just “export alerts.” The first step is to identify which Dynatrace alerting model was used, because each model may be stored under a different API schema.



## Issue #7 — Instana Rule Mapping

| # | Dynatrace rule | Instana rule | Dynatrace signal | Instana signal | Condition | Status |
|---|---|---|---|---|---|---|
| 1 | MVP - Frontend P95 Latency High | MVP 1 - Frontend P95 Latency High | p95 response time | latency 95th percentile | Latency >= 500 ms | Created |
| 2 | MVP - Frontend Failure Rate High | MVP 2 - Frontend Failure Rate High | failure rate % | error rate | Error rate > 5% | Created |
| 3 | MVP - Frontend Throughput Drop | MVP 3 - Frontend Throughput Drop | request rate | calls | Calls < 0.1 or lowest supported threshold | Created, threshold verified |