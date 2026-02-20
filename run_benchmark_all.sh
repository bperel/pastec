#!/bin/bash
# Run benchmark against legacy (:4212) and improved (:4213) Pastec, then update BENCHMARK_RESULTS.md.
# Ensure both containers are running with the same index before running.

set -e
cd "$(dirname "$0")"
SCRIPT_DIR="$PWD"

NUM_RUNS=${BENCHMARK_RUNS:-5}
RESULTS_FILE="$SCRIPT_DIR/BENCHMARK_RESULTS.md"
RAW_RESULTS=$(mktemp)
trap "rm -f $RAW_RESULTS" EXIT

echo "=== Pastec Docker Benchmark (legacy vs improved, same index) ==="
echo ""

echo "--- Legacy (:4212) ---"
PASTEC_URL=http://localhost:4212 CONFIG_NAME="Legacy (:4212)" BENCHMARK_RUNS="$NUM_RUNS" ./benchmark_search.sh 2>/dev/null | tee /dev/stderr | grep "^BENCHMARK_LINE|" >> "$RAW_RESULTS"
echo ""

echo "--- Improved (:4213) ---"
PASTEC_URL=http://localhost:4213 CONFIG_NAME="Improved (:4213)" BENCHMARK_RUNS="$NUM_RUNS" ./benchmark_search.sh 2>/dev/null | tee /dev/stderr | grep "^BENCHMARK_LINE|" >> "$RAW_RESULTS"
echo ""

python3 "$SCRIPT_DIR/benchmark_report.py" "$RAW_RESULTS" "$RESULTS_FILE" "$NUM_RUNS"
