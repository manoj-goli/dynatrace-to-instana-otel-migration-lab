# Note 1: Dynatrace API + Monaco Export Commands

## 1. Set Dynatrace environment variables

```bash
export DT_ENV_ID="kdb75523"
export DT_ENV_URL="https://${DT_ENV_ID}.live.dynatrace.com"
```

Purpose:

```text
Stores Dynatrace environment ID and URL so we do not repeat them in every command.
```

---

## 2. Read token securely from terminal

```bash
read -rsp "Paste Dynatrace config export token: " DT_CONFIG_TOKEN
echo
export DT_CONFIG_TOKEN
```

Purpose:

```text
Prompts for token without showing it on screen.
-r = raw input
-s = silent, hides input
-p = prompt text
```

Sanity check without exposing token:

```bash
echo "${DT_CONFIG_TOKEN:+DT_CONFIG_TOKEN is set}"
```

Expected:

```text
DT_CONFIG_TOKEN is set
```

---

## 3. Create export folders

```bash
mkdir -p dynatrace-export/api-exports
mkdir -p dynatrace-export/monaco
```

Purpose:

```text
Creates folders safely. No error if they already exist.
```

---

## 4. Install jq

```bash
sudo apt-get update
sudo apt-get install -y jq
```

Purpose:

```text
jq is used to format, inspect, and extract values from JSON.
```

---

## 5. Export Dynatrace schema using Settings API

```bash
curl -sS "$DT_ENV_URL/api/v2/settings/schemas/builtin:davis.anomaly-detectors" \
  -H "Authorization: Api-Token $DT_CONFIG_TOKEN" \
  | jq . > dynatrace-export/api-exports/davis-anomaly-detectors-schema.json
```

Purpose:

```text
Downloads the schema definition for Dynatrace custom alerts.
```

Important parts:

```text
curl -sS      = silent but still show errors
-H           = add HTTP header
| jq .       = pretty print JSON
> file.json  = save output to file
```

---

## 6. Export Dynatrace custom alerts using Settings API

```bash
curl -sS "$DT_ENV_URL/api/v2/settings/objects?schemaIds=builtin:davis.anomaly-detectors&fields=objectId,schemaId,scope,value,updateToken" \
  -H "Authorization: Api-Token $DT_CONFIG_TOKEN" \
  | jq . > dynatrace-export/api-exports/davis-anomaly-detectors.json
```

Purpose:

```text
Exports the 3 MVP custom alerts from Dynatrace.
```

---

## 7. Check exported alert names from API export

```bash
jq -r '.items[] | [.objectId, .value.title, .value.enabled] | @tsv' \
  dynatrace-export/api-exports/davis-anomaly-detectors.json
```

Purpose:

```text
Lists object ID, title, and enabled status for each exported alert.
```

Key learning:

```text
API export structure:
.items[].value.title
.items[].value.enabled
```

---

## 8. Export classic metric events for comparison

```bash
curl -sS "$DT_ENV_URL/api/v2/settings/objects?schemaIds=builtin:anomaly-detection.metric-events&fields=objectId,schemaId,scope,value,updateToken" \
  -H "Authorization: Api-Token $DT_CONFIG_TOKEN" \
  | jq . > dynatrace-export/api-exports/metric-events.json
```

Purpose:

```text
Checks whether alerts are stored as old-style metric events.
```

Learning:

```text
Our new Dynatrace custom alerts were under:
builtin:davis.anomaly-detectors

Not under:
builtin:anomaly-detection.metric-events
```

---

## 9. Check item counts

```bash
jq '.items | length' dynatrace-export/api-exports/davis-anomaly-detectors.json
jq '.items | length' dynatrace-export/api-exports/metric-events.json
```

Purpose:

```text
Counts how many objects were exported.
```

---

## 10. Install Monaco

```bash
curl -L https://github.com/Dynatrace/dynatrace-configuration-as-code/releases/latest/download/monaco-linux-amd64 -o monaco-linux-amd64
chmod +x monaco-linux-amd64
sudo mv monaco-linux-amd64 /usr/local/bin/monaco
monaco version
```

Purpose:

```text
Downloads, makes executable, installs, and verifies Monaco CLI.
```

Important parts:

```text
curl -L     = follow redirects
chmod +x   = make file executable
sudo mv    = move binary into system PATH
```

---

## 11. Monaco download command

```bash
monaco download \
  --url "https://kdb75523.live.dynatrace.com" \
  --token DT_CONFIG_TOKEN \
  --settings-schema builtin:davis.anomaly-detectors \
  --output-folder dynatrace-export/monaco \
  --project dynatrace-mvp-alerts
```

Purpose:

```text
Downloads Dynatrace custom alerts as Monaco configuration files.
```

Important learning:

```text
--token DT_CONFIG_TOKEN means:
Use the environment variable named DT_CONFIG_TOKEN.

It does NOT mean:
Use the literal token value directly.
```

---

## 12. Inspect Monaco-exported files

```bash
find dynatrace-export/monaco -type f | head -20
```

Purpose:

```text
Shows the first 20 files created by Monaco.
```

---

## 13. Check JSON keys in Monaco files

```bash
for f in dynatrace-export/monaco/dynatrace-mvp-alerts/builtindavis.anomaly-detectors/*.json; do
  echo "---- $f ----"
  jq 'keys' "$f"
done
```

Purpose:

```text
Shows the top-level structure of each Monaco JSON file.
```

Learning:

```text
Monaco structure:
.title
.enabled
.source
.analyzer
.eventTemplate

API structure:
.items[].value.title
.items[].value.enabled
```

---

## 14. Search Monaco export content

```bash
grep -RniE "MVP|Frontend|Latency|Failure|Throughput|enabled|title|event|query" \
  dynatrace-export/monaco/dynatrace-mvp-alerts/builtindavis.anomaly-detectors/
```

Purpose:

```text
Searches all exported files for rule names, queries, and event fields.
```

Important flags:

```text
-R = recursive
-n = show line numbers
-i = case insensitive
-E = extended regex
```

---

## 15. Inspect Monaco config mapping

```bash
cat dynatrace-export/monaco/dynatrace-mvp-alerts/builtindavis.anomaly-detectors/config.yaml
```

Purpose:

```text
Shows how Monaco maps config IDs to JSON template files and schema metadata.
```
