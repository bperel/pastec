#!/bin/bash
# Run benchmark for all configurations and update BENCHMARK_RESULTS.md with timing report.

set -e
cd "$(dirname "$0")"
SCRIPT_DIR="$PWD"

INDEX_PATH="${PASTEC_INDEX_PATH:-/Users/bperel/Documents/workspace/perso/dm/packages/api/pastec-index-last.dat}"
VISUAL_WORDS="${PASTEC_VISUAL_WORDS:-$SCRIPT_DIR/data/visualWordsORB.dat}"
NUM_RUNS=${BENCHMARK_RUNS:-5}
RESULTS_FILE="$SCRIPT_DIR/BENCHMARK_RESULTS.md"
RAW_RESULTS=$(mktemp)
trap "rm -f $RAW_RESULTS" EXIT

echo "=== Running benchmarks for all configurations ==="
echo ""

# 1. Baseline (Docker on 4212)
echo "--- Baseline (Docker :4212) ---"
CONFIG_NAME="Baseline" BENCHMARK_RUNS="$NUM_RUNS" ./benchmark_search.sh 2>/dev/null | tee /dev/stderr | grep "^BENCHMARK_LINE|" >> "$RAW_RESULTS"
echo ""

# 2. Distance threshold 80 (local build on 4214)
echo "--- Distance threshold 80 (local :4214) ---"
pkill -f "pastec -p 4214" 2>/dev/null || true
sleep 2

if [[ -f "$INDEX_PATH" && -f "$VISUAL_WORDS" ]]; then
    ./build/pastec -p 4214 -i "$INDEX_PATH" "$VISUAL_WORDS" 2>/dev/null &
    PASTEC_PID=$!
    echo "Waiting for Pastec to load (75s)..."
    sleep 75

    PASTEC_URL=http://localhost:4214 CONFIG_NAME="Distance threshold 80" BENCHMARK_RUNS="$NUM_RUNS" ./benchmark_search.sh 2>/dev/null | tee /dev/stderr | grep "^BENCHMARK_LINE|" >> "$RAW_RESULTS"

    kill $PASTEC_PID 2>/dev/null || true
else
    echo "Skipping local build (index or visual words not found)"
fi
echo ""

# Generate report and update BENCHMARK_RESULTS.md
python3 "$SCRIPT_DIR/benchmark_report.py" "$RAW_RESULTS" "$RESULTS_FILE" "$NUM_RUNS"
