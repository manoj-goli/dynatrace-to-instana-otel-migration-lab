# Rule Migration Tool

Issue #9 adds a semi-automated Dynatrace to Instana rule migration workflow to this lab.

The tool is intended to turn Dynatrace alert exports into reviewable Instana Smart Alert candidates. It is not a direct import path, and v1 does not make live API calls.

## Goal

```text
Dynatrace API / Monaco export
  -> parse
  -> normalize
  -> classify
  -> map to Instana Smart Alert candidates
  -> generate review outputs
  -> human review
  -> optional API/Terraform creation later, after validation
```

## Phase Boundaries

Phase 1 is planning and scaffold only.

Phase 2 will implement Dynatrace export parsing and normalized rule data.

Phase 3 will implement classification, Instana candidate mapping, and review output generation.

Phase 4 will evaluate Instana API or Terraform creation only after payloads, Application Perspective IDs, alert channel IDs, and tenant behavior are validated.

## Output Locations

- `rule-migration-tool/outputs/`: local generated working outputs from this tool.
- `rule-inventory/generated/`: curated and reviewed migration outputs that may be committed later.

## Safety

- No real tokens are stored here.
- No `.env` files are edited by this tool.
- v1 is generate-only and does not call Dynatrace or Instana APIs.
- Exported Dynatrace rules are source artifacts, not directly importable Instana configs.
