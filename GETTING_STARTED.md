---
title: Getting Started with RagMetrics Content Verification
---

# 📄 Getting an API Key from RagMetrics

1. **Visit the RagMetrics portal**
   - Open your browser and go to <https://ragmetrics.ai>.  If you do not have an account, click **Sign Up** and complete the registration flow.
2. **Navigate to the API section**
   - After logging in get your RagMetrics API Key → **Keys** → **API Keys** 
3. **Create a new key**
   - Press **Generate API Key**.
   - The portal will display a token that looks like `xxxxxxxxxxxxxxxxxxxx`.
4. **Copy the key securely**
   - **Important:** You will see the key only once.  Copy it to a password manager or a secure notes file.
   - Do **not** commit the key to source control.
5. **Set the environment variable**
   ```bash
   export RAGMETRICS_API_KEY="<your‑api‑key>"
   ```
   - Add the line to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) so it is available for every session.
   - For CI/CD pipelines, store the key in the secret manager and inject it as `RAGMETRICS_API_KEY` at runtime.

# 🎯 Using the Skill
The skill lives in `~/hermes/09-SkillsRepo/ragmetrics-content-verification/`.  The primary entry point is the helper script **`ragmetrics_verify.sh`**.

## 1. Install dependencies
```bash
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y curl jq
# macOS (Homebrew)
brew install curl jq
```

## 2. Prepare a payload file (`payload.json`)
```json
{
  "question": "Summarize the water cycle.",
  "answer": "Water evaporates from the surface, forms clouds, then falls as precipitation.",
  "ground_truth": "The water cycle involves evaporation, condensation, and precipitation.",
  "context": "Chapter 3 of Earth Science textbook",
  "type": "C",
  "criteria": ["Accuracy", "Completeness"],
  "model": "gpt-4o-mini"   # name will be mapped to a numeric ID
}
```

## 3. Run the verification
```bash
# Direct mode (no Evaluation Group needed)
./ragmetrics_verify.sh payload.json
```
If you need to use the **legacy monitoring** endpoint (batch mode), set the group ID first:
```bash
export RAGMETRICS_EVAL_GROUP_ID="<your‑group‑id>"
./ragmetrics_verify.sh --legacy payload.json
```

The script prints a JSON response with scores, token usage and a `run_id` you can store for later analysis.

# 🔧 Tips & Common Pitfalls
- **Rate limits:** free tier = 30 requests/min. Add a short `sleep` or exponential back‑off on HTTP 429.
- **Model mapping:** the script contains a `MODEL_MAP` associative array. Extend it if you need a model not listed.
- **Never expose the key:** keep it in environment variables or secret stores; never hard‑code it in a file.
- **Batch payloads:** for legacy mode wrap individual records in an `inputs` array as described in the README.

# 📚 Further Reading
- RagMetrics API documentation: <https://ragmetrics.ai/docs/api>
- Full skill README: `README.md` in the same folder.

---

*Created by the Jorma orchestrator (⚽)*