#!/usr/bin/env bash
set -euo pipefail

# Require API key
if [[ -z "${RAGMETRICS_API_KEY:-}" ]]; then
  echo "Error: RAGMETRICS_API_KEY must be set in the environment." >&2
  exit 1
fi

# Determine mode: legacy (requires group ID) or direct (default)
MODE="direct"
PAYLOAD="${1:-payload.json}"
if [[ "${1:-}" == "--legacy" ]]; then
  MODE="legacy"
  PAYLOAD="${2:-payload.json}"
fi

if [[ ! -f "$PAYLOAD" ]]; then
  echo "Error: Payload file '$PAYLOAD' not found." >&2
  exit 1
fi

# Model name to numeric ID map (partial, extend as needed)
declare -A MODEL_MAP=(
  ["gpt-4o"]=2
  ["gpt-4o-mini"]=1202
  ["mistral-small-latest"]=1210
  ["mistral-large-latest"]=1212
  ["Azure gpt-4o"]=1214
  ["microsoft/Phi-3-mini-4k-instruct"]=1243
  ["meta-llama/Llama-3.2-3B-Instruct"]=1244
  ["meta-llama/Llama-3.2-1B-Instruct"]=1245
  ["Azure gpt-4o-mini"]=1283
  ["deepseek-chat"]=1417
  ["deepseek-reasoner"]=1418
  ["granite-3-8b-instruct"]=1419
  ["granite-guardian-3-8b"]=1420
  ["granite-34b-code-instruct"]=1421
  ["granite-20b-code-base-sql-gen"]=1422
  ["o3-mini"]=1423
  ["gemini-2.5-flash-lite"]=1425
  ["gemini-3-flash-preview"]=1426
  ["gemini-2.5-flash"]=1480
  ["llama-3.3-70b-versatile"]=1481
  ["deepseek/deepseek-r1:free"]=1484
  ["google/gemma-3-4b-it:free"]=1485
  ["Azure o3-mini"]=1486
  ["qwen-qwq-32b"]=1555
  ["deepseek-r1-distill-llama-70b"]=1556
  ["claude-sonnet-4-6"]=1558
  ["claude-opus-4-6"]=1559
  ["gemini-2.5-pro"]=1560
  ["claude-haiku-4-5-20251001"]=1561
)

# If in direct mode, replace model name with numeric ID before sending
if [[ "$MODE" == "direct" ]]; then
  # Extract model name from payload
  model_name=$(jq -r '.model' "$PAYLOAD")
  # Lookup numeric ID; fallback to original value if not found
  model_id=${MODEL_MAP[$model_name]:-$model_name}
  # Replace model field with numeric ID
  TMP=$(mktemp)
  jq ".model = $model_id" "$PAYLOAD" > "$TMP"
  mv "$TMP" "$PAYLOAD"
  URL="https://api.ragmetrics.ai/v2/evaluate-direct/"
  curl -s -X POST "$URL" \
    -H "Authorization: Token ${RAGMETRICS_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "@${PAYLOAD}" | jq '.'
  exit 0
else
  if [[ -z "${RAGMETRICS_EVAL_GROUP_ID:-}" ]]; then
    echo "Error: RAGMETRICS_EVAL_GROUP_ID must be set for legacy mode." >&2
    exit 1
  fi
  URL="https://api.ragmetrics.ai/v1/evaluations/groups/${RAGMETRICS_EVAL_GROUP_ID}/run"
  curl -s -X POST "$URL" \
    -H "Authorization: Bearer ${RAGMETRICS_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "@${PAYLOAD}" | jq '.'
fi