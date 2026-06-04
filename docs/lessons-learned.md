
# Note 2: General Linux, jq, SSH/SCP Learnings

## 1. Command continuation differs by shell

Linux/bash:

```bash
command \
  --flag value \
  --flag2 value
```

PowerShell:

```powershell
command `
  --flag value `
  --flag2 value
```

Learning:

```text
Backslash \ is for Linux/bash.
Backtick ` is for PowerShell.
Do not mix them.
```

---

## 2. Redirect output to a file

```bash
command > output.txt
```

Purpose:

```text
Saves command output into a file instead of printing it on screen.
```

Example:

```bash
curl -sS "$DT_ENV_URL/api/v2/settings/objects?schemaIds=builtin:davis.anomaly-detectors" \
  -H "Authorization: Api-Token $DT_CONFIG_TOKEN" \
  | jq . > dynatrace-export/api-exports/davis-anomaly-detectors.json
```

---

## 3. Pipe output into another command

```bash
command1 | command2
```

Purpose:

```text
Sends output from command1 into command2.
```

Example:

```bash
curl -sS "$URL" | jq .
```

Meaning:

```text
Get JSON from API, then format it with jq.
```

---

## 4. jq pretty print JSON

```bash
jq . file.json
```

Purpose:

```text
Formats JSON so it is readable.
```

---

## 5. jq extract specific fields

API export:

```bash
jq -r '.items[] | [.objectId, .value.title, .value.enabled] | @tsv' file.json
```

Monaco export:

```bash
jq -r '.title, .enabled' file.json
```

Learning:

```text
Same data can have different JSON structure depending on export method.
Always inspect keys first.
```

---

## 6. jq inspect keys

```bash
jq 'keys' file.json
```

Purpose:

```text
Shows top-level fields in a JSON file.
```

This helped us realize Monaco used:

```text
.title
.enabled
```

instead of:

```text
.value.title
.value.enabled
```

---

## 7. Check if command succeeded

```bash
echo $?
```

Purpose:

```text
Shows exit code of previous command.
0 = success
non-zero = error
```

---

## 8. List files with details

```bash
ls -lh dynatrace-export/api-exports/
```

Purpose:

```text
Shows file sizes and confirms export files exist.
```

Useful flags:

```text
-l = long listing
-h = human-readable size
```

---

## 9. Find files recursively

```bash
find dynatrace-export/monaco -type f
```

Purpose:

```text
Lists all files under a folder.
```

Limit output:

```bash
find dynatrace-export/monaco -type f | head -20
```

---

## 10. Search inside files

```bash
grep -RniE "MVP|Frontend|query|title" dynatrace-export/monaco/
```

Purpose:

```text
Searches text inside many files.
```

Very useful for:

```text
finding alert names
finding DQL query expressions
finding event names
finding config references
```

---

## 11. Copy files from VM to local Windows machine

Run this from **local PowerShell**, not inside PuTTY:

```powershell
gcloud compute scp --recurse `
  --project=project-2e1b7100-bf26-4dcf-b0e `
  --zone=us-central1-a `
  otel-mvp-vm:/home/manoj/dynatrace-export/api-exports `
  "C:\Users\manoj\OneDrive\Desktop\D_to_I\configs\dynatrace\"
```

Copy Monaco export:

```powershell
gcloud compute scp --recurse `
  --project=project-2e1b7100-bf26-4dcf-b0e `
  --zone=us-central1-a `
  otel-mvp-vm:/home/manoj/dynatrace-export/monaco `
  "C:\Users\manoj\OneDrive\Desktop\D_to_I\configs\dynatrace\exported\"
```

Learning:

```text
Use full VM path:
/home/manoj/dynatrace-export/...

Avoid ~ in gcloud scp remote paths from PowerShell.
```

---

## 12. PuTTY vs local PowerShell

Use PuTTY/SSH for commands **inside the VM**:

```bash
ls
cat
jq
curl
monaco
docker compose
```

Use local PowerShell for commands that copy files **between VM and Windows**:

```powershell
gcloud compute scp
```

Learning:

```text
The VM cannot directly understand Windows paths like C:\Users\...
Run Windows file-copy commands from Windows PowerShell.
```

---

## 13. Useful mental model

```text
curl     = call API
jq       = read/filter JSON
grep     = search text
find     = locate files
cat      = print file
ls       = list files
monaco   = export Dynatrace config as code
scp      = copy files between machines
```

## 14. Biggest practical lessons

```text
1. Never paste real tokens into notes or Git.
2. Use read -rsp for sensitive token input.
3. Always inspect JSON structure before writing jq filters.
4. API export and Monaco export can represent the same rule differently.
5. Run Linux commands inside the VM.
6. Run Windows file-copy commands from local PowerShell.
7. Use full remote paths with gcloud scp.
8. Save both raw exports and readable notes because migration work needs evidence.
```

---

## 15. Dual-export fan-out pattern (Issue #6)

```text
The OpenTelemetry Collector supports multiple exporters in a single pipeline.
This means one collector can send the same traces, metrics, and logs to
both Dynatrace and Instana simultaneously.
```

Key concept:

```yaml
service:
  pipelines:
    traces:
      exporters: [otlp_grpc/jaeger, debug, spanmetrics, otlp_http/dynatrace, otlp_http/instana]
```

This is called a **fan-out** pattern. Each exporter operates independently — if one fails, the others continue.

Learning:

```text
Fan-out is the simplest way to compare two observability platforms.
No duplicate collectors, no proxy, no routing rules needed.
The demo's extras config overlay makes this easy to toggle.
```

Important:

```text
Use the currently working Dynatrace collector config as the base.
Do not replace it with a simplified config that removes the demo exporters.

Preserve:
  traces:  otlp_grpc/jaeger, debug, spanmetrics
  metrics: otlp_http/prometheus, debug
  logs:    opensearch, debug
```

---

## 16. Instana OTLP authentication model

```text
Instana uses a custom HTTP header for OTLP authentication:
  x-instana-key: <agent-key>

Dynatrace uses a standard Authorization header:
  Authorization: Api-Token <token>

Each backend has its own auth model. Always check the vendor's
OTLP ingestion docs for the correct header name and format.
```

---

## 17. gRPC vs HTTP OTLP export

```text
The OTel Collector supports two OTLP exporter types:
  otlp     = gRPC (typically port 4317)
  otlp_http = HTTP (typically port 4318) in this demo config

Choose based on the backend's endpoint format.
If the endpoint URL includes :4317, use otlp.
If it includes :4318 or /v1/traces, use otlp_http.
Using the wrong type causes connection errors.
```

---

## 18. Environment variable scope reminder

```text
Adding a variable to the VM-side .env file is not enough.
The Docker container must also receive it.

The docker-compose.override.yml must include:
  services:
    otel-collector:
      env_file:
        - .env

Without this, the collector sees unset environment variables
and fails to start — even though the .env file exists on the VM.

This was first learned in Issue #4 (Dynatrace) and applies
equally to Issue #6 (Instana dual-export).
```

Validation command:

```bash
docker inspect otel-collector --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -E 'DT_ENDPOINT|INSTANA_OTLP_ENDPOINT|INSTANA_AGENT_KEY'
```

Learning:

```text
Use docker inspect for environment validation.
Do not rely on docker compose exec otel-collector env because the
collector image may not include shell or env utilities.
Do not commit command output if it exposes real endpoints or keys.
```

---

## 19. Trial expiry and tenant rehydration

```text
SaaS observability trials can expire before a lab is finished.
When that happens, the project needs tenant rehydration before validation can continue.
```

In this MVP, the original Dynatrace trial expired before Issue #8 was complete.

Rehydration meant:

```text
1. Create a new Dynatrace tenant.
2. Update VM-side Dynatrace ingest settings only.
3. Recreate the collector so it loads the new ingest token and endpoint.
4. Confirm telemetry reaches the new tenant.
5. Recreate the 3 MVP Dynatrace rules.
```

Learning:

```text
Do not store the new endpoint, ingest token, or config token in the repo.
Document the process and evidence, not the secrets.
```

---

## 20. Dynatrace ingest token vs Monaco config token

```text
Dynatrace ingest and Dynatrace configuration automation use different token purposes.
```

For this lab:

```text
DT_API_TOKEN / ingest token:
  Used by the OpenTelemetry Collector to send telemetry.

Dynatrace config token:
  Used by API or Monaco workflows to read or manage settings.
```

Learning:

```text
A working telemetry ingest token does not imply Monaco or Settings API access.
Keep the token purpose clear when troubleshooting.
```

---

## 21. Monaco dry-run does not guarantee live deploy

```text
monaco deploy --dry-run validates structure and planned changes.
It does not guarantee the real deploy path will be accepted by the tenant.
```

In this MVP:

```text
monaco deploy --dry-run manifest.yaml
  passed

monaco deploy manifest.yaml
  failed for builtin:davis.anomaly-detectors
```

The failure included:

```text
Could not do validation as request was not done using oAuth.
```

Learning:

```text
Exportability does not always equal redeployability.
Some Dynatrace Davis anomaly detector deploy paths may require OAuth validation.
```

---

## 22. Manual rebuild can be the right MVP fallback

```text
For a small MVP rule set, manual rebuild is acceptable when automation is blocked.
```

In this lab, the 3 Dynatrace rules were manually recreated in the new tenant after Monaco real deploy failed.

Learning:

```text
Do not let config-as-code tooling block the MVP when the rule set is small,
the mapping is understood, and screenshots can prove the rebuilt rules.
Document the automation limitation and continue with validated manual recreation.
```

---

## 23. Alert parity requires threshold and behavior validation

Alert migration is not just copying thresholds.

Instana used `Calls < 1`, while Dynatrace required `request_rate < 300` for the equivalent frontend throughput-drop behavior. The intent was the same, but each platform represented throughput using a different scale and alert evaluation model.

Repeated tests showed alert creation behavior can differ because tools may evaluate persistence, missing data, repeated violations, and deduplication differently.

Final migration validation should compare user-facing alert intent and operational outcome, not just metric names and threshold values.

---

## 24. Manual rebuild is useful for discovery but not scalable

Manually rebuilding 3 Instana Smart Alerts was acceptable for the MVP because it exposed the real mapping decisions:

```text
latency -> slowness
failure rate -> erroneous calls
throughput drop -> calls / throughput
```

That approach does not scale to 100+ rules.

Learning:

```text
Use manual rebuild to learn the mapping model.
Use automation to produce reviewable migration outputs once the pattern is understood.
```

---

## 25. Exported rules need translation, not direct import

Dynatrace API and Monaco exports are useful source artifacts, but they are not directly importable Instana configs.

The migration workflow needs to:

```text
parse exports
normalize rule data
classify alert intent
map to Instana candidates
flag confidence and review needs
generate reviewable outputs
```

Learning:

```text
There is no simple "Dynatrace export -> Instana import" path for these rules.
The useful automation target is a semi-automated translation workflow.
```
