#!/usr/bin/env python3
"""Parse benchmark output and update BENCHMARK_RESULTS.md with response times table."""

import re
import sys

def main():
    raw_file = sys.argv[1]
    results_file = sys.argv[2]
    num_runs = sys.argv[3]

    img_order = ['$_57.PNG', '988f1391aa41b758467483b1db28309b0610a04e.jpg', 'Couv_163996.jpg', 's-l1200.jpg']
    img_short = {'$_57.PNG': '$_57.PNG', '988f1391aa41b758467483b1db28309b0610a04e.jpg': '988f13...jpg',
                 'Couv_163996.jpg': 'Couv_163996.jpg', 's-l1200.jpg': 's-l1200.jpg'}

    data = {}
    configs = []
    try:
        with open(raw_file) as f:
            for line in f:
                if not line.strip().startswith('BENCHMARK_LINE|'):
                    continue
                parts = line.strip().split('|', 4)
                if len(parts) >= 5:
                    _, config, image, ms, _ = parts[0], parts[1], parts[2], parts[3], parts[4]
                    if config not in configs:
                        configs.append(config)
                    data[(config, image)] = int(ms)
    except FileNotFoundError:
        configs = []
        data = {}

    report = []
    report.append(f"## Response Times (avg of {num_runs} runs per image)")
    report.append("")
    report.append("| Configuration | $_57.PNG | 988f13...jpg | Couv_163996.jpg | s-l1200.jpg | Total |")
    report.append("|---------------|----------|---------------|-----------------|-------------|-------|")

    for config in configs:
        cells = [f"**{config}**"]
        total = 0
        for img in img_order:
            ms = data.get((config, img))
            if ms is not None:
                cells.append(str(ms))
                total += ms
            else:
                cells.append("—")
        cells.append(str(total))
        report.append("| " + " | ".join(cells) + " |")

    report_text = "\n".join(report)
    print(report_text)
    print()

    try:
        with open(results_file) as f:
            content = f.read()
    except FileNotFoundError:
        content = ""

    if "## Response Times" in content:
        content = re.sub(
            r'## Response Times.*?(?=\n## |\Z)',
            report_text + "\n\n",
            content,
            count=1,
            flags=re.DOTALL
        )
    else:
        content = content.replace("## Findings", report_text + "\n\n## Findings")

    with open(results_file, 'w') as f:
        f.write(content)
    print(f"Updated {results_file}")

if __name__ == "__main__":
    main()
