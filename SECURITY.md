# Security

This repository must not contain credentials, tokens, private keys, or environment-specific secrets.

## Secrets Handling

- Never commit API tokens.
- Never commit `.env` files.
- Use `.env.example` only for placeholder variable names.
- Store real values locally or in an approved secret manager.

## Network Exposure

- Prefer SSH tunneling for access to internal services.
- Do not expose OTLP ports `4317` or `4318` publicly.
- Do not expose unnecessary ports from the GCP VM.
