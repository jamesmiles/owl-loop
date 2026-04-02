#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORT_DIR="$SCRIPT_DIR/report"
HEADER="$SCRIPT_DIR/header.md"
FOOTER_TEMPLATE="$SCRIPT_DIR/footer.md"

mkdir -p "$REPORT_DIR"

# Collect owl test files in natural sort order
OWL_FILES=($(ls "$SCRIPT_DIR"/owl-*.md 2>/dev/null | sort -V))

if [[ ${#OWL_FILES[@]} -eq 0 ]]; then
  echo "No owl-*.md test files found in $SCRIPT_DIR"
  exit 1
fi

echo "=== Owl Loop Test Runner ==="
echo "Found ${#OWL_FILES[@]} test(s)"
echo ""

for owl_file in "${OWL_FILES[@]}"; do
  test_name="$(basename "$owl_file" .md)"
  output_file="$REPORT_DIR/${test_name}-output.json"

  echo "--- Running: $test_name ---"

  # Build the prompt: header + test file + footer (with output path substituted)
  footer_content="$(sed "s|{{OUTPUT_PATH}}|$output_file|g" "$FOOTER_TEMPLATE")"
  prompt="$(cat "$HEADER")

$(cat "$owl_file")

$footer_content"

  # Launch Claude in non-interactive mode
  claude --dangerously-skip-permissions -p "$prompt" --output-format text

  # Check if output was produced
  if [[ -f "$output_file" ]]; then
    echo "✓ $test_name — result written to $output_file"
  else
    echo "✗ $test_name — no output file produced, creating failure record"
    cat > "$output_file" <<EOF
{
  "test": "$test_name",
  "score": 0,
  "errors": ["Agent did not produce an output file"],
  "difficulties": []
}
EOF
  fi

  echo ""
done

# --- Aggregate Report ---
echo "=== Aggregate Report ==="
echo ""

total_score=0
test_count=0
all_errors=()
all_difficulties=()

for owl_file in "${OWL_FILES[@]}"; do
  test_name="$(basename "$owl_file" .md)"
  output_file="$REPORT_DIR/${test_name}-output.json"

  if [[ ! -f "$output_file" ]]; then
    continue
  fi

  score=$(jq -r '.score // 0' "$output_file" 2>/dev/null || echo 0)
  total_score=$((total_score + score))
  test_count=$((test_count + 1))

  # Collect errors with test name prefix
  while IFS= read -r err; do
    [[ -n "$err" ]] && all_errors+=("[$test_name] $err")
  done < <(jq -r '.errors[]? // empty' "$output_file" 2>/dev/null)

  # Collect difficulties with test name prefix
  while IFS= read -r diff; do
    [[ -n "$diff" ]] && all_difficulties+=("[$test_name] $diff")
  done < <(jq -r '.difficulties[]? // empty' "$output_file" 2>/dev/null)

  echo "  $test_name: score=$score/10"
done

echo ""

if [[ $test_count -gt 0 ]]; then
  avg=$(echo "scale=1; $total_score / $test_count" | bc)
  echo "Average score: $avg / 10  ($test_count test(s))"
else
  echo "No test results to aggregate."
fi

if [[ ${#all_errors[@]} -gt 0 ]]; then
  echo ""
  echo "Errors:"
  for e in "${all_errors[@]}"; do
    echo "  - $e"
  done
fi

if [[ ${#all_difficulties[@]} -gt 0 ]]; then
  echo ""
  echo "Difficulties:"
  for d in "${all_difficulties[@]}"; do
    echo "  - $d"
  done
fi

echo ""
echo "=== Done ==="
