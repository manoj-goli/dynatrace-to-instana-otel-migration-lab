Good checkpoint. Your latest config confirms:

```text
Instana exporter exists ✅
Instana receives traces pipeline ✅
Instana receives metrics pipeline ✅
Instana was removed from logs pipeline ✅
Dynatrace still receives traces, metrics, logs ✅
```

## Where to save these notes

Save this in:

```text
docs/lessons-learned.md
```

Add a smaller progress summary in:

```text
docs/phase-journal.md
```

For the detailed commands, I would add a new file:

```text
docs/instana-dual-export-notes.md
```

That keeps the commands easy to find later.

---

# Notes for `docs/instana-dual-export-notes.md`

````markdown
# Instana Dual Export Notes

## Goal

Configure the existing OpenTelemetry Collector from the Astronomy Shop Docker Compose stack to send telemetry to both Dynatrace and IBM Instana.

Target architecture:

```text
Astronomy Shop services
    ↓
OpenTelemetry Collector
    ↓
Dynatrace + Instana
````

## Important Decision

We did not install a new OpenTelemetry Collector from Instana.

Reason:

The Astronomy Shop demo already includes an `otel-collector` container. Installing another collector would complicate the lab and create duplicate telemetry paths.

Instead, we reused the existing collector and added Instana as another OTLP exporter.

## Instana Setup

Instana provided:

* HTTP OTLP endpoint
* gRPC OTLP endpoint
* Agent key

For this lab, we used the HTTP endpoint because the existing Dynatrace exporter was already using the HTTP-style exporter.

VM-side `.env` values added:

```env
INSTANA_OTLP_ENDPOINT=https://otlp-http-blue-saas.instana.io:443
INSTANA_AGENT_KEY=***REDACTED***
```

Real values exist only on the VM and are never committed to Git.

## Environment Variable Scope

The `.env` file lives on the VM:

```text
/home/manoj/opentelemetry-demo/.env
```

The collector container receives those variables through:

```yaml
services:
  otel-collector:
    env_file:
      - .env
```

Important lesson:

Adding a value to `.env` does not automatically update a running container. The container must be recreated to reload the new environment variables.

## Dual Export Config

Final exporter design:

```text
traces  → Jaeger + debug + spanmetrics + Dynatrace + Instana
metrics → Prometheus + debug + Dynatrace + Instana
logs    → OpenSearch + debug + Dynatrace
```

Instana logs were removed because the trial/tenant returned HTTP 402 for log ingest.

## Instana Logs Finding

Initial logs pipeline included Instana:

```yaml
logs:
  exporters: [opensearch, debug, otlp_http/dynatrace, otlp_http/instana]
```

Collector returned:

```text
HTTP Status Code 402
None of the tenants are permitted to send log data
```

Decision:

Remove Instana from logs pipeline. Logs are best-effort and not a blocker for Issue #6.

Final logs pipeline:

```yaml
logs:
  exporters: [opensearch, debug, otlp_http/dynatrace]
```

## Final Pipeline Validation

Confirmed final config:

```text
traces:
  exporters: [otlp_grpc/jaeger, debug, spanmetrics, otlp_http/dynatrace, otlp_http/instana]

metrics:
  exporters: [otlp_http/prometheus, debug, otlp_http/dynatrace, otlp_http/instana]

logs:
  exporters: [opensearch, debug, otlp_http/dynatrace]
```

## Current Status

Issue #6 validation is complete:

* Services visible
* Traces visible
* Metrics visible
* Dynatrace continuity confirmed

Logs are documented as unsupported/blocked by tenant permissions.

Current validation has moved to Issue #8, the throughput-drop failure scenario using the stopped `load-generator`.

````

---

# Commands to save in the same file

```markdown
## Commands Used

### Go to demo directory

```bash
cd /home/manoj/opentelemetry-demo
````

### Add Instana values to VM-side `.env`

```bash
nano .env
```

Added:

```env
INSTANA_OTLP_ENDPOINT=https://otlp-http-blue-saas.instana.io:443
INSTANA_AGENT_KEY=<real-key-on-vm-only>
```

### Verify Instana values without exposing key

```bash
grep -E "^(INSTANA_OTLP_ENDPOINT|INSTANA_AGENT_KEY)=" .env \
  | sed 's/INSTANA_AGENT_KEY=.*/INSTANA_AGENT_KEY=***REDACTED***/'
```

### Check which env vars are inside the running collector container

```bash
docker inspect $(docker compose ps -q otel-collector) \
  --format '{{range .Config.Env}}{{println .}}{{end}}' \
  | grep -E "^(DT_|INSTANA_)" \
  | sed 's/DT_API_TOKEN=.*/DT_API_TOKEN=***REDACTED***/; s/INSTANA_AGENT_KEY=.*/INSTANA_AGENT_KEY=***REDACTED***/'
```

### Recreate collector so it reloads `.env`

```bash
docker compose up -d --force-recreate otel-collector
```

### Back up current collector config

```bash
cp src/otel-collector/otelcol-config-extras.yml \
  src/otel-collector/otelcol-config-extras.yml.before-instana.$(date +%Y%m%d-%H%M%S)
```

### Inspect logs pipeline

```bash
grep -n "logs:" -A4 src/otel-collector/otelcol-config-extras.yml
```

### Remove Instana from logs pipeline only

```bash
sed -i 's/exporters: \[opensearch, debug, otlp_http\/dynatrace, otlp_http\/instana\]/exporters: [opensearch, debug, otlp_http\/dynatrace]/' src/otel-collector/otelcol-config-extras.yml
```

### Verify final traces/metrics/logs pipelines

```bash
grep -n "otlp_http/instana\|traces:\|metrics:\|logs:" -A2 src/otel-collector/otelcol-config-extras.yml
```

### Recreate collector after config change

```bash
docker compose up -d --force-recreate otel-collector
```

### Check collector status

```bash
docker compose ps otel-collector
```

### Check recent collector logs

```bash
docker compose logs otel-collector --tail=80
```

### Search for important log patterns

```bash
docker compose logs otel-collector --tail=100 \
  | grep -iE "instana|error|fail|unauthorized|denied|402|403|401|traces|metrics"
```

## Useful Lessons

* Use `docker inspect` instead of `docker compose exec` for minimal collector images.
* Recreate containers after changing `.env`.
* HTTP 402 from Instana logs means log ingest is not permitted for the tenant.
* Remove only the failing signal from the pipeline, not the whole exporter.
* Traces and metrics are the mandatory success criteria for Issue #6.
* Logs are best-effort.

````

