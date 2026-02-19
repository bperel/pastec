#!/bin/bash
# Benchmark reverse image search on ALJM 11 dataset.
# Expected by file:
#   $_57.PNG:           empty results
#   Couv_163996.jpg:    top 2 = [43760, 128181]
#   988f1391...jpg, s-l1200.jpg: top = 128181

DATASET="/Users/bperel/Desktop/ALJM 11 dataset"
BASE_URL="${PASTEC_URL:-http://localhost:4212}"
URL="${BASE_URL%/}/index/searcher"
NUM_RUNS=${BENCHMARK_RUNS:-5}

echo "=== Pastec Reverse Image Search Benchmark ==="
echo "URL: $URL"
echo "Runs per image: $NUM_RUNS"
echo ""

pass=0
fail=0
resp_file=$(mktemp)
times_file=$(mktemp)
times_summary=""
trap "rm -f $resp_file $times_file" EXIT

for f in "$DATASET"/*; do
    if [ ! -f "$f" ]; then continue; fi
    name=$(basename "$f")
    echo "--- $name ---"

    > "$times_file"
    for i in $(seq 1 "$NUM_RUNS"); do
        curl -s -o "$resp_file" -w "%{time_total}\n" \
            -X POST \
            -H "Content-Type: application/octet-stream" \
            --data-binary @"$f" \
            "$URL" >> "$times_file"
    done

    result=$(cat "$resp_file" | python3 -c "
import sys, json, os
name = os.path.basename(r'''$f'''.replace('\\\\', '/'))
try:
    d = json.load(sys.stdin)
    ids = d.get('image_ids', [])
    ids_str = ','.join(map(str, ids)) if ids else 'empty'
    if name.endswith('57.PNG'):
        ok = len(ids) == 0
        expected = 'empty'
    elif name == 'Couv_163996.jpg':
        ok = len(ids) >= 2 and ids[0] == 43760 and ids[1] == 128181
        expected = '43760,128181'
    else:
        ok = ids and ids[0] == 128181
        expected = '128181'
    print('PASS' if ok else 'FAIL', ids_str, expected)
except Exception as e:
    print('FAIL', 'PARSE_ERROR', '?')
" 2>/dev/null)

    avg_ms=$(awk '{sum+=$1; n++} END {if(n>0) printf "%.0f", sum/n*1000; else print 0}' "$times_file")

    status=$(echo "$result" | cut -d' ' -f1)
    got=$(echo "$result" | cut -d' ' -f2)
    expected=$(echo "$result" | cut -d' ' -f3-)

    if [[ "$status" == "PASS" ]]; then
        echo "  PASS (got: $got, expected: $expected) — avg ${avg_ms}ms"
        ((pass++))
    else
        echo "  FAIL (got: $got, expected: $expected) — avg ${avg_ms}ms"
        ((fail++))
    fi
    times_summary="${times_summary}${name}: ${avg_ms}ms  "
    [[ -n "$CONFIG_NAME" ]] && echo "BENCHMARK_LINE|$CONFIG_NAME|$name|$avg_ms|$status"
done

echo ""
echo "=== Summary: $pass passed, $fail failed ==="
echo "Response times (avg of ${NUM_RUNS} runs): $times_summary"
