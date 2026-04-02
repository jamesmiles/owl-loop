# Owl Loop

**Automated QA through agentic observation loops.**

Owl Loop is an open-source demonstration of running end-to-end UI tests using AI agents. Instead of brittle selectors and scripted assertions, an agent interacts with real applications — clicking, typing, observing screenshots — and reasons about whether each step succeeded.

## The Owl Loop

Every test step follows a four-phase subprocess:

1. **Act** — perform the action using platform tools (click, type, launch)
2. **Observe** — capture the screen and examine the result
3. **Analyse** — reason about what happened: success, failure, or unexpected state
4. **Decide** — proceed, retry (up to 3 attempts), or halt and report

This loop gives the agent resilience to timing issues, layout shifts, and minor UI changes that would break traditional automation. The agent adapts in real time rather than failing on a stale selector.

## Architecture

```
┌─────────────────────────────────────┐
│           run-tests.sh/.ps1         │  Orchestrator
├─────────────────────────────────────┤
│  header.md  +  owl-N.md  + footer.md│  Prompt assembly
├─────────────────────────────────────┤
│         Claude (non-interactive)    │  AI agent
├─────────────────────────────────────┤
│    screencapture / cliclick (mac)   │  Platform tools
│    pyautogui (windows)              │
├─────────────────────────────────────┤
│         System under test           │  Target application
└─────────────────────────────────────┘
```

**Prompt composition** — Each test run assembles a prompt from three parts:
- `header.md` — agent identity, available tools, the owl loop process, and system-under-test notes
- `owl-N.md` — test intent, preconditions, expected result, and optional step-by-step plan
- `footer.md` — output schema and scoring guide

**Test variants** — Tests can be written at two levels of specificity:
- **Prescriptive** (owl-01, owl-03) — explicit step-by-step instructions
- **Intent-only** (owl-02, owl-04) — just the goal and expected result; the agent generates its own plan

This lets you compare agent reliability with and without detailed guidance.

**Reporting** — Each agent writes a structured JSON result with a score (0–10), errors, and difficulties. The runner script aggregates these into a summary with average scores and a full issue list.

## Platform support

| Platform | Tools | Runner |
|----------|-------|--------|
| macOS | `screencapture`, `cliclick` | `run-tests.sh` |
| Windows | `pyautogui` | `run-tests.ps1` |

## Quick start

```bash
# macOS
cd macos && ./run-tests.sh

# Windows (PowerShell)
cd windows; .\run-tests.ps1
```

Requires [Claude Code](https://claude.ai/code) installed and available as `claude` on your PATH.

## Writing tests

Create a new `owl-N.md` in the platform folder:

```markdown
## System Under Test
<application name>

## Preconditions
- <setup requirements>

## Test Intent
<what to test>

## Expected Result
<what success looks like>

## Test Steps
<explicit steps, or "Generate a test plan from the above intent and execute it.">
```

The runner picks up all `owl-*.md` files automatically.

## License

MIT
