# Reverse Image Search Benchmark Results

**Dataset:** ALJM 11 dataset (4 images)  
**Index:** 159,381 images

## Expected Results by File

| File | Expected |
|------|----------|
| $_57.PNG | empty |
| 988f1391...jpg | top = 128181 |
| Couv_163996.jpg | top 2 = [43760, 128181] |
| s-l1200.jpg | top = 128181 |

## Results Summary

| Configuration | $_57.PNG | 988f13...jpg | Couv_163996.jpg | s-l1200.jpg | Pass rate |
|---------------|----------|--------------|-----------------|-------------|-----------|
| **Baseline** (Docker) | ✓ empty | ✓ 128181 | ✓ 43760,128181 | ✓ 128181 | **4/4** |
| **Distance threshold 80** | ✓ empty | ✓ 128181 | ✓ 43760,128181 | ✓ 128181 | **4/4** |

## Response Times (avg of 3 runs per image)

| Configuration | $_57.PNG | 988f13...jpg | Couv_163996.jpg | s-l1200.jpg | Total |
|---------------|----------|---------------|-----------------|-------------|-------|
| **Baseline** | 4204 | 3235 | 2307 | 3546 | 13292 |
| **Distance threshold 80** | 524 | 346 | 256 | 333 | 1459 |


## Findings

1. **Descriptor distance threshold (80):** Maintains full accuracy. Filters weak matches without hurting recall.

2. **Ratio test (0.8):** Too aggressive—reduced visual words from ~795 to 17–32, causing all queries to return empty (RANSAC needs ≥12 inliers).

3. **Homography (perspective):** No change in ranking vs rigid transform.

## Running the Benchmark

```bash
# Run all configurations and update this report (baseline + local build):
./run_benchmark_all.sh

# Single configuration (5 runs per image, Docker on :4212):
./benchmark_search.sh

# Fewer runs:
BENCHMARK_RUNS=3 ./run_benchmark_all.sh
```

Response times are averaged over `BENCHMARK_RUNS` (default 5) curl requests per image.

## Implemented Improvements (in codebase)

- **Distance threshold:** `src/orb/orbsearcher.cpp` — reject matches with Hamming distance > 80
- **Build fixes:** CMake 3.5, OpenCV IMREAD_GRAYSCALE, libmicrohttpd MHD_Result, jsoncpp Find module
