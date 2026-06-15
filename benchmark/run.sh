#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/results"
ITERATIONS="${ITERATIONS:-20}"

# ---- Preflight checks ----
if ! command -v k6 &>/dev/null; then
  echo "Error: k6 not found."
  echo "Install: https://k6.io/docs/get-started/installation/"
  echo "  macOS:  brew install k6"
  echo "  Linux:  sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69"
  echo "          echo 'deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main' | sudo tee /etc/apt/sources.list.d/k6.list"
  echo "          sudo apt-get update && sudo apt-get install k6"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo "Error: python3 not found."
  exit 1
fi

if ! python3 -c "import numpy, matplotlib" 2>/dev/null; then
  echo "Missing Python dependencies. Installing..."
  pip3 install -r "${SCRIPT_DIR}/requirements.txt"
fi

mkdir -p "$RESULTS_DIR"

echo "=== Pastec Benchmark ==="
echo "Iterations per image: $ITERATIONS"
echo ""

# ---- Pre-download images ----
# Images are sent as binary bytes so all container versions are supported
# and download time is excluded from the benchmark measurements.
echo "=== Downloading images ==="
rm -f "${RESULTS_DIR}/image_files.txt"
image_idx=1
while IFS= read -r url || [[ -n "${url:-}" ]]; do
  [[ -z "${url:-}" || "${url:-}" == \#* ]] && continue
  outfile="${RESULTS_DIR}/image_${image_idx}.jpg"
  echo "  image_${image_idx}: ${url}"
  curl -fsSL -o "$outfile" "$url"
  echo "image_${image_idx}.jpg" >> "${RESULTS_DIR}/image_files.txt"
  ((image_idx++))
done < "${SCRIPT_DIR}/images.txt"
echo ""

# ---- Run k6 for each container ----
while IFS=' ' read -r name port || [[ -n "${name:-}" ]]; do
  [[ -z "${name:-}" || "${name:-}" == \#* ]] && continue

  BASE_URL="http://localhost:${port}"
  OUTFILE="${RESULTS_DIR}/${name}_raw.ndjson"

  echo "--- Benchmarking: ${name} (${BASE_URL}) ---"

  (
    cd "$SCRIPT_DIR"
    BASE_URL="$BASE_URL" ITERATIONS="$ITERATIONS" \
      k6 run \
        --out "json=${OUTFILE}" \
        bench.js
  )

  echo "Saved: ${OUTFILE}"
  echo ""
done < "${SCRIPT_DIR}/containers.txt"

# ---- Generate report ----
echo "=== Generating report ==="
(cd "$SCRIPT_DIR" && python3 report.py)

echo ""
echo "Done. See benchmark/README.md and benchmark/results.png"
