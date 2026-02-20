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
| *(run ./run_benchmark_all.sh to update)* |

## Response Times (avg of 5 runs per image)

| Configuration | $_57.PNG | 988f13...jpg | Couv_163996.jpg | s-l1200.jpg | Total |
|---------------|----------|---------------|-----------------|-------------|-------|
| *(run ./run_benchmark_all.sh to update)* |

## Findings

## Implemented Improvements

- **Distance threshold 80:** Reject matches with Hamming distance > 80
- **Rerank pool 30:** RANSAC on top 30 (was 300)
- **No-copy index:** Pass pointers to hit lists, hold read lock for full search
- **Build fixes:** CMake 3.5, OpenCV, libmicrohttpd, jsoncpp

## Running the Benchmark

```bash
# Run both (legacy :4212 and improved :4213 must be running with same index):
./run_benchmark_all.sh

# Single URL:
PASTEC_URL=http://localhost:4213 ./benchmark_search.sh

# Fewer runs:
BENCHMARK_RUNS=3 ./run_benchmark_all.sh
```
