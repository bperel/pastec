import http from 'k6/http';
import { check } from 'k6';
import exec from 'k6/execution';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:4212';
const ITERATIONS_PER_IMAGE = parseInt(__ENV.ITERATIONS || '20');

// Image files are pre-downloaded by run.sh into results/ before k6 runs.
// open() resolves relative to this script file at init time.
const imageFiles = open('./results/image_files.txt')
  .split('\n')
  .map((l) => l.trim())
  .filter((l) => l.length > 0);

// Load all image binary data once at init time (ArrayBuffer).
const imageData = imageFiles.map((imageFile) => open(`./results/${imageFile}`, 'b')); // Pre-allocate array for better memory usage

export const options = {
  vus: 1,
  iterations: imageFiles.length * ITERATIONS_PER_IMAGE,
  noUsageReport: true,
};

export default () => {
  const idx = exec.scenario.iterationInTest % imageFiles.length;

  const res = http.post(
    `${BASE_URL}/index/searcher`,
    imageData[idx],
    {
      headers: { 'Content-Type': 'application/octet-stream' },
      tags: { image: `image_${idx + 1}` },
    }
  );

  const expectedIds = [
    [43760, 128181], // image_1
  ];

  const body = JSON.parse(res.body);
  const ids = body.image_ids || [];
  const checks = { 'status 200': (r) => r.status === 200 };
  if (expectedIds[idx]) {
    checks['contains expected image ids'] = () => expectedIds[idx].every((id) => ids.includes(id));
  }
  check(res, checks);
};;
