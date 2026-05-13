# Cost Control

## Pre-VM Checklist

- Confirm GCP free trial credits.
- Set billing alerts at `$10`, `$20`, and `$50`.
- Use `e2-standard-4`.
- Stop VM when not working.
- Do not expose unnecessary ports.
- Do not expose OTLP ports `4317` or `4318` publicly.
- Restrict any temporary frontend port, such as `8080`, to the current public IP only.

## Baseline VM Cost Rules

- Use one VM for the MVP.
- Use zone `us-central1-a` unless there is a capacity or quota issue.
- Use Ubuntu 22.04 LTS if available; Debian 12 is acceptable as a fallback.
- Do not use GKE for the MVP.
- Do not use Terraform for the MVP.
- Stop the VM whenever active testing is finished.

## Auto-Shutdown Approach

The MVP VM should have a systemd timer installed with `scripts/auto-shutdown-vm.sh`.
The default shutdown time is `23:00 UTC`, and it can be overridden with `SHUTDOWN_TIME_UTC`.

Example:

```bash
SHUTDOWN_TIME_UTC=23:30 ./scripts/auto-shutdown-vm.sh
```

## Manual Stop Command

Use `scripts/stop-vm.sh` from a workstation with `gcloud` authenticated to stop the VM:

```bash
./scripts/stop-vm.sh
```

Defaults:

- Project: `project-2e1b7100-bf26-4dcf-b0e`
- Zone: `us-central1-a`
- VM name: `otel-mvp-vm`
