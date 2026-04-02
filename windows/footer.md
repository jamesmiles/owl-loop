# Output Instructions

When you have completed the test (or cannot proceed further), write your results to:

  {{OUTPUT_PATH}}

Use **exactly** this JSON schema — no additional keys, no markdown fences, just the raw JSON object:

```
{
  "test": "<test id, e.g. t01>",
  "score": <integer 0–10>,
  "errors": ["<each functional failure or broken step>"],
  "difficulties": ["<each usability issue, confusion, or slow/unclear interaction>"]
}
```

### Scoring guide

| Score | Meaning |
|-------|---------|
| 10    | All steps passed, no issues |
| 7–9   | All steps passed with minor difficulties |
| 4–6   | Some steps failed or had significant usability issues |
| 1–3   | Most steps failed |
| 0     | Could not execute the test at all |

Write **only** the JSON object to the file (no surrounding text). After the file is written, run `/exit` to end the session — you are done.
