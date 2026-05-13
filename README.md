# RagMetrics Content Verification Skill – Quick Human Guide

## What this skill does
Provides a simple Bash wrapper (`ragmetrics_verify.sh`) that sends a JSON payload to the RagMetrics live‑evaluation API and returns a nicely formatted JSON result. It can be invoked directly from the command line or through AI agents such as **Claude**, **OpenClaw**, and **Manus**.

## Prerequisites
1. **RagMetrics.ai account** – sign up at https://ragmetrics.ai.
2. **Judge model API key** – configure the LLM (e.g., Claude, OpenAI) you want to use as the evaluation judge inside the RagMetrics dashboard.
3. **RagMetrics API key** – generate this from your account settings; it authorises API calls.
4. **Evaluation Group** – create one on the Monitoring page and select the criteria you need (privacy, accuracy, relevance, etc.). Note the generated **Evaluation Group ID**.
5. **Environment variables** – export the following in the shell (or via your CI / secret manager):
   ```bash
   export RAGMETRICS_API_KEY="<your‑ragmetrics‑api‑key>"
   export RAGMETRICS_EVAL_GROUP_ID="<your‑evaluation‑group‑id>"
   ```
6. **System tools** – `curl` (standard) and `jq` for JSON pretty‑printing. Install `jq` if missing (`apt-get install jq` or `brew install jq`).

## Installation steps
1. **Copy the skill folder** to your project (already placed at `~/hermes/09‑SkillsRepo/ragmetrics-content-verification`).
2. **Make the wrapper executable**:
   ```bash
   cd ~/hermes/09‑SkillsRepo/ragmetrics-content-verification
   chmod +x ragmetrics_verify.sh
   ```
3. **Verify the environment** – ensure the two environment variables above are set in the same shell where you will run the script.

## How to run the skill

### Legacy Monitoring API (Evaluation Group)

The wrapper also supports the **legacy monitoring** endpoint that uses a pre‑configured Evaluation Group. This call requires the environment variable `RAGMETRICS_EVAL_GROUP_ID` to be set and sends the payload to:

```
POST https://api.ragmetrics.ai/v1/evaluations/groups/${RAGMETRICS_EVAL_GROUP_ID}/run
```

**Request body** (same as in `payload.json` but wrapped under an `inputs` array):
```json
{
  "inputs": [
    {
      "question": "Your question",
      "answer": "Model answer",
      "ground_truth": "Expected answer",
      "context": "Optional context",
      "type": "C",
      "criteria": ["Accuracy", "Completeness"],
      "model": 1202
    }
  ]
}
```

The response contains the evaluated metrics for each input and a `run_id` that can be used to retrieve the run later (via the same endpoint).

---

### Direct Evaluation API

The **Direct Evaluation API** allows you to submit a single question‑answer pair for immediate scoring without an Evaluation Group. The skill automatically converts a model name (e.g., `gpt-4o-mini`) to its numeric ID before calling this endpoint.

**Endpoint**
```
POST https://api.ragmetrics.ai/v2/evaluate-direct/
```

**Authentication** – use the API token method (recommended):
```
Authorization: Token <your_api_token>
```

**Request body** (as used in `payload.json`):
```json
{
  "question": "Summarize the water cycle.",
  "answer": "Water evaporates from the surface, forms clouds, then falls as precipitation.",
  "ground_truth": "The water cycle involves evaporation, condensation, and precipitation.",
  "context": "Chapter 3 of Earth Science textbook",
  "type": "C",
  "criteria": ["Accuracy", "Completeness"],
  "model": 1202
}
```

The response is returned synchronously, e.g.:
```json
{
  "status": "SUCCESS",
  "message": "Evaluation completed successfully.",
  "run_id": 123,
  "single_record_id": 456,
  "results": [
    {
      "criteria": "Accuracy",
      "score": 4,
      "reason": "The answer is factually correct and matches the ground truth."
    }
  ],
  "tokens_consumed": {
    "input_tokens": 450,
    "output_tokens": 120
  }
}
```

Both methods ultimately return the same result structure; the direct API simply bypasses the need for an Evaluation Group.

## Using the skill with AI agents
- **Claude (Claude Code)**: In a Claude session, type `!./ragmetrics_verify.sh <payload>` – Claude will run the script, capture the output, and you can ask it to summarise the scores.
- **OpenClaw**: Use the same `!` operator, e.g., `! ./ragmetrics_verify.sh <payload>`. OpenClaw will receive the JSON output for further reasoning.
- **Manus**: Add a step to your workflow YAML:
  ```yaml
  run: ./ragmetrics_verify.sh <payload>
  ```
  Make sure the workflow environment includes the `RAGMETRICS_API_KEY` and `RAGMETRICS_EVAL_GROUP_ID` variables (Manus can load them from a `.env` file or secret store).

1. Prepare a payload JSON file (e.g., `payload.json`) following the schema described in `SKILL.md`:
   ```json
   {
     "inputs": [
       {"question": "What is the capital of France?", "answer": "Paris"}
     ]
   }
   ```
2. Execute the wrapper:
   ```bash
   ./ragmetrics_verify.sh payload.json
   ```
   The command prints a formatted JSON response with metric scores.

## Using the skill with AI agents
- **Claude (Claude Code)**: In a Claude session, type `!./ragmetrics_verify.sh <payload>` – Claude will run the script, capture the output, and you can ask it to summarise the scores.
- **OpenClaw**: Use the same `!` operator, e.g., `! ./ragmetrics_verify.sh <payload>`. OpenClaw will receive the JSON output for further reasoning.
- **Manus**: Add a step to your workflow YAML:
  ```yaml
  run: ./ragmetrics_verify.sh <payload>
  ```
  Make sure the workflow environment includes the `RAGMETRICS_API_KEY` and `RAGMETRICS_EVAL_GROUP_ID` variables (Manus can load them from a `.env` file or secret store).

## Tips & best practices
- Keep the API key out of version‑controlled files; use environment variables or a secret manager.
- Respect the free‑tier rate limit (30 requests/min); add a short sleep or exponential back‑off if you hit HTTP 429.
- Split large payloads – the API caps at ~2 MiB per request.
- Review the metric list in your Evaluation Group to ensure it matches the quality criteria you care about.

---

*This README is intended for humans setting up the skill. Detailed technical usage, payload schema, and agent‑specific snippets are documented in the accompanying `SKILL.md`.*
