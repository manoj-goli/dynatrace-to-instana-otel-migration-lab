# Issue #9 - Semi-Automated Dynatrace to Instana Rule Migration Tool

## Objective

Issue #9 adds an active project workstream for semi-automated alert rule migration.

The core goal is to build a workflow that takes Dynatrace alert exports, normalizes and classifies the rules, maps them to Instana Smart Alert candidates, and generates reviewable outputs before any API creation is attempted.

Manual Instana alert rebuilding worked for the 3-rule MVP, but it does not scale to 100+ rules. The migration needs a translation workflow that preserves alert intent while making thresholds, platform-specific metric semantics, unsupported alert types, and human-review decisions explicit.

## Workflow

```text
Dynatrace API / Monaco export
  -> parse alert rules
  -> normalize rule data
  -> classify rule type
  -> map to Instana Smart Alert candidates
  -> generate CSV / JSON / Markdown review outputs
  -> human review
  -> optional API or Terraform creation later
```

Exported Dynatrace rules are source artifacts. They are not directly importable Instana configurations.

## Scope

### Phase 1: Planning and scaffold only

- Create the `rule-migration-tool/` scaffold.
- Create safe placeholder docs and config files.
- Document output locations, phase boundaries, mapping principles, confidence levels, and risks.
- Update project docs to include Issue #9 as active scope.
- Make no live API calls.
- Implement no parser, mapper, API client, Terraform creation, or alert creation.

### Phase 2: Dynatrace parser and normalizer

- Parse Dynatrace Settings API exports.
- Parse Dynatrace Monaco exports.
- Normalize both formats into one internal rule schema.
- Add parser tests against safe local export artifacts.

### Phase 3: Classifier, mapper, and review outputs

- Classify rules as latency, error_rate, throughput, availability, log_based, slo, davis_anomaly, or custom_unknown.
- Generate Instana Smart Alert candidate mappings.
- Generate reviewable JSON, CSV, and Markdown outputs.
- Flag unsupported and low-confidence rules.

### Phase 4: API or Terraform creation after validation

- Evaluate Instana REST API creation only after tenant validation.
- Evaluate Terraform creation only after schema and lifecycle behavior are validated.
- Validate Application Perspective IDs and alert channel IDs.
- Keep dry-run behavior as the default.
- Require explicit human approval before any live creation.

## Folder Structure

```text
rule-migration-tool/
  README.md
  requirements.txt
  src/
    __init__.py
  config/
    mapping-rules.yaml
    metric-mapping.yaml
    service-name-overrides.yaml
  samples/
    dynatrace/
    instana/
  outputs/
    .gitkeep
  tests/
    __init__.py
```

Future Phase 4 files may include:

```text
rule-migration-tool/src/instana_api_client.py
rule-migration-tool/src/create_instana_alerts.py
```

These files are intentionally not created in Phase 1.

## Output Locations

- `rule-migration-tool/outputs/`: local/generated working outputs from the tool.
- `rule-inventory/generated/`: curated/reviewed migration outputs that may be committed later.

## Research Findings

### Dynatrace export format

The 3 MVP rules are stored under `builtin:davis.anomaly-detectors`.

Local source artifacts:

- `configs/dynatrace/api-exports/davis-anomaly-detectors.json`
- `configs/dynatrace/exported/monaco/`

Dynatrace documentation confirms that anomaly detectors use the Settings API schema `builtin:davis.anomaly-detectors`, with fields such as `enabled`, `title`, `description`, `source`, `executionSettings`, `analyzer`, and `eventTemplate`.

Source:

- https://docs.dynatrace.com/docs/dynatrace-api/environment-api/settings/schemas/builtin-davis-anomaly-detectors

### Instana REST API

Research finding - needs tenant/API validation.

IBM API Hub lists Instana REST API resources for Smart Alert configuration, including application and global Smart Alert config operations. The historical Instana OpenAPI page redirects to IBM API Hub.

Source:

- https://developer.ibm.com/apis/catalog/instana--instana-rest-api/

The plan must not treat API creation as complete or proven until payloads are tested against the target tenant.

Validation still required:

- Exact payload schema accepted by the current tenant.
- Required Application Perspective IDs.
- Required alert channel IDs.
- Enable/disable/delete behavior.
- Trial tenant restrictions.

### Instana Terraform provider

Research finding - needs tenant/Terraform validation.

The Terraform Registry lists the `instana/instana` provider and a `global_application_alert_config` resource for Global Application Smart Alerts.

Sources:

- https://registry.terraform.io/providers/instana/instana
- https://registry.terraform.io/providers/instana/instana/latest/docs/resources/global_application_alert_config

Validation still required:

- Provider version behavior in this project.
- Required fields for the actual target tenant.
- Import/lifecycle behavior for existing alerts.
- Whether Terraform is appropriate for this lab's Phase 4.

## Seed Mapping Examples

| Dynatrace rule | Dynatrace signal | Dynatrace threshold | Instana candidate | Instana signal | Instana threshold | Confidence |
|---|---|---|---|---|---|---|
| MVP - Frontend P95 Latency High | `percentile(dt.service.request.response_time, 95)` | 500000 microseconds, ABOVE | Slowness Smart Alert | Latency 95th percentile | 500 ms | High |
| MVP - Frontend Failure Rate High | `100 * failures / total` | 5 percent, ABOVE | Erroneous Calls Smart Alert | Error rate | 5 percent | High |
| MVP - Frontend Throughput Drop | `sum(dt.service.request.count, rate: 1m)` | `request_rate < 300` | Throughput Smart Alert | Calls | Calls < 1 | Medium |

The mapping principle is to preserve alert intent, not blindly copy numeric thresholds.

## Confidence Levels

| Level | Criteria | Action |
|---|---|---|
| High | Simple static-threshold latency or error-rate rule with clear signal equivalence. | Generate candidate mapping and require human threshold review. |
| Medium | Throughput/drop rule, unit conversion, scope difference, or likely threshold recalibration. | Generate candidate mapping with review required. |
| Low | Davis AI, baseline, SLO, log-based, arbitrary DQL, or unclear Instana equivalent. | Flag for manual review and do not auto-map. |

## Risks

- Threshold recalibration is rule-specific and cannot be automated generically.
- Dynatrace and Instana may expose similar alert intent through different metric semantics.
- Missing-data behavior may differ by platform.
- Repeated alert behavior, deduplication, persistence, and cool-down behavior may differ by platform.
- Unsupported alert types may require manual rebuild.
- Application Perspective IDs may not be known from Dynatrace exports.
- Alert channel IDs must exist before live Instana alert creation.
- Trial tenant restrictions may block some alert types or APIs.

## Acceptance Criteria For Phase 1

- Scaffold folders exist.
- Safe placeholder docs/config files exist.
- No Phase 2, Phase 3, or Phase 4 implementation files are created.
- Existing project docs show Issue #9 as active scope.
- v1 is clearly documented as generate-only.
- v2/Phase 4 API or Terraform creation is clearly documented as requiring validation.
- No real tokens, `.env` edits, API calls, VM commands, Docker commands, screenshots, or commits are involved.
