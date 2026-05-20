
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
