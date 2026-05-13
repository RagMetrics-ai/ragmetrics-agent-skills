---
name: ragmetrics-content-verification
title: RagMetrics Content Verification
description: Workflow to verify LLM-generated content using RagMetrics live evaluation API.
author: Jorma
version: 1.0
---

# Purpose
This skill provides a reusable workflow to evaluate and verify textual content (e.g., RAG answers, summaries) using the RagMetrics live evaluation service. It abstracts the API interaction, handling authentication, request construction, and result parsing.

# Prerequisites
- A valid **RagMetrics API Key** with access to the evaluation service.
- The **Evaluation Group ID** that contains the desired metric set just for  (e.g., `qa`, `summarization`).
- `curl` installed (standard on Linux/macOS) and `jq` for JSON parsing (install via `apt-get install jq` or `brew install jq`).
- (Optional) **OpenClaw** or **Claude** CLI installed if you want to invoke the skill from those agents.

## Quick Guide to Set Up RagMetrics Evaluation
1. **Create an account** on **RagMetrics.ai**.
2. **Configure the LLM API Key** for the judge model you intend to use (e.g., Claude, OpenAI, etc.) in the RagMetrics dashboard.
3. **Generate a RagMetrics API Key** from the account settings – this key authorizes calls to the evaluation endpoint.
4. **Create an Evaluation Group** on the Monitoring page and select the desired criteria (privacy, accuracy, relevance, etc.).
5. **Pass the RagMetrics API Key and the Evaluation Group ID** to the skill (set `RAGMETRICS_API_KEY` and `RAGMETRICS_EVAL_GROUP_ID` environment variables) before invoking the verification script.

# Configuration
Set environment variables in your shell or CI environment before using the skill:
```
export RAGMETRICS_API_KEY="<your-api-key>"
export RAGMETRICS_EVAL_GROUP_ID="<your-group-id>"
```
These variables are read by the helper script to avoid hard‑coding secrets.

# Usage
## 1. Prepare the payload
Create a JSON file (e.g., `payload.json`) with the following structure:
```json
{
  "inputs": [
    {
      "question": "<your query>",
      "answer": "<model output to verify>"
    }
    // you can include multiple entries
  ]
}
```
## 2. Run the verification command directly
```bash
curl -s -X POST "https://api.ragmetrics.ai/v1/evaluations/groups/${RAGMETRICS_EVAL_GROUP_ID}/run" \
  -H "Authorization: Bearer ${RAGMETRICS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d @payload.json | jq '.'
```
## 3. Using the provided Bash wrapper
Save `ragmetrics_verify.sh` in your project utils folder and make it executable:
```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${RAGMETRICS_API_KEY:-}" || -z "${RAGMETRICS_EVAL_GROUP_ID:-}" ]]; then
  echo "Error: RAGMETRICS_API_KEY and RAGMETRICS_EVAL_GROUP_ID must be set in the environment." >&2
  exit 1
fi

payload_file="${1:-payload.json}"

curl -s -X POST "https://api.ragmetrics.ai/v1/evaluations/groups/${RAGMETRICS_EVAL_GROUP_ID}/run" \
  -H "Authorization: Bearer ${RAGMETRICS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "@${payload_file}" | jq '.'
```
Usage:
```bash
./ragmetrics_verify.sh my_payload.json
```
## 4. Interpreting results
Typical fields in the response:
- `id` – identifier of the submitted item.
- `metrics` – map of metric names to numeric scores (0‑1, higher is better).
- `details` – optional verbose breakdown per metric.
You can pipe the output to a file for later analysis:
```bash
... | tee evaluation_results.json
```

# Using the Skill with OpenClaw
OpenClaw can invoke any shell script via its `!` operator. Assuming `ragmetrics_verify.sh` is in your working directory:
```bash
! ./ragmetrics_verify.sh payload.json
```
OpenClaw will capture the stdout, which includes the pretty‑printed JSON from `jq`. You can then feed the result back into the OpenClaw reasoning loop.

# Using the Skill with Claude (Claude Code)

Claude Code can run the same Bash wrapper. In a Claude session, you can request:
```
Run the verification:
!./ragmetrics_verify.sh payload.json
```
Claude will execute the command, display the JSON output, and you can ask Claude to summarize the scores or highlight any failing criteria.

# Using the Skill with Manus

Manus can invoke external commands through its `run` directive (or similar command‑execution feature). Ensure the environment variables `RAGMETRICS_API_KEY` and `RAGMETRICS_EVAL_GROUP_ID` are exported in the Manus runtime (e.g., via a `.env` file or the `env:` block). Then call the Bash wrapper just as you would in a regular shell:
```yaml
run: ./ragmetrics_verify.sh payload.json
```
Manus will capture the stdout, which includes the formatted JSON from `jq`. You can then pass the resulting JSON to subsequent Manus steps for further processing or decision‑making. Remember to keep the API key out of version‑controlled files; use Manus’s secret‑management features to inject it securely.

# Pitfalls & Tips
- **Rate limits** – 30 requests per minute on the free tier; implement exponential back‑off on `429`.
- **Metric mismatch** – Ensure the evaluation group you reference contains metrics appropriate for your task (e.g., `privacy`, `accuracy`).
- **Payload size** – API caps at 2 MiB; split large batches.
- **Security** – Never commit the API key. Use environment variables or secret managers (Vault, GitHub Secrets).
- **OpenClaw / Claude** – Both agents need access to the same environment variables; you can export them in the session before invoking the wrapper.

# References
- RagMetrics API docs: https://ragmetrics.ai/docs/api
- JSON schema for evaluation requests (linked in docs).

# Example Quick Test
```bash
cat > payload.json <<'EOF'
{
  "inputs": [
    {"question": "What is the capital of France?", "answer": "Paris"},
    {"question": "Who wrote '1984'?", "answer": "George Orwell"}
  ]
}
EOF

./ragmetrics_verify.sh payload.json
```
You should see a JSON response with metric scores for each input.

# License
MIT – free to use, modify, and redistribute.

---

**End of Skill**