#!/usr/bin/env python3
"""Parse k6 NDJSON output files and produce README.md + results.png."""

import json
import math
import os
import sys
from collections import defaultdict
from datetime import datetime

try:
    import numpy as np
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
except ImportError:
    print("Missing dependencies. Run: pip install -r requirements.txt")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(SCRIPT_DIR, "results")
README_PATH = os.path.join(SCRIPT_DIR, "README.md")
GRAPH_PATH = os.path.join(SCRIPT_DIR, "results.png")
CI_Z = 1.96  # 95% confidence interval

CONTAINER_DESCRIPTIONS = {
    "pastec": "Original upstream pastec (Ubuntu 17.04, OpenCV 3). Baseline reference.",
    "pastec-improved": "Fork with a reduced RANSAC reranking pool and tighter match-distance threshold, cutting the expensive geometric verification step.",
    "pastec-o3": "Original upstream code recompiled with `-O3` and `-march=native` to isolate the compiler-optimisation gain.",
    "kp1000-flann200": "Our optimisation: keypoints halved (2000→1000), reducing ORB extraction and FLANN lookups proportionally; FLANN vocabulary-search depth cut 10× (SearchParams 2000→200). Both applied together on Ubuntu 22.04 / OpenCV 4.",
}


def parse_ndjson(filepath):
    """Return {image_label: [duration_ms, ...]} from a k6 NDJSON file."""
    data = defaultdict(list)
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if obj.get("type") == "Point" and obj.get("metric") == "http_req_duration":
                tags = obj["data"].get("tags", {})
                image = tags.get("image", "unknown")
                data[image].append(obj["data"]["value"])
    return dict(data)


def stats(values):
    arr = np.array(values, dtype=float)
    n = len(arr)
    mean = float(np.mean(arr))
    median = float(np.median(arr))
    std = float(np.std(arr, ddof=1)) if n > 1 else 0.0
    p95 = float(np.percentile(arr, 95))
    ci = CI_Z * std / math.sqrt(n) if n > 0 else 0.0
    return {"mean": mean, "median": median, "std": std, "p95": p95, "ci": ci, "n": n, "arr": arr}


def main():
    # Discover result files in insertion order from containers.txt
    containers_file = os.path.join(SCRIPT_DIR, "containers.txt")
    ordered_names = []
    if os.path.exists(containers_file):
        with open(containers_file) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                name = line.split()[0]
                ordered_names.append(name)

    # Load results
    all_data = {}
    for name in ordered_names:
        path = os.path.join(RESULTS_DIR, f"{name}_raw.ndjson")
        if os.path.exists(path):
            all_data[name] = parse_ndjson(path)

    # Fall back to alphabetical if containers.txt not found
    if not all_data:
        for fname in sorted(os.listdir(RESULTS_DIR)):
            if fname.endswith("_raw.ndjson"):
                name = fname[: -len("_raw.ndjson")]
                all_data[name] = parse_ndjson(os.path.join(RESULTS_DIR, fname))

    if not all_data:
        print(f"No result files found in {RESULTS_DIR}/")
        sys.exit(1)

    container_names = list(all_data.keys())

    # Build image label list in sorted order
    all_images = sorted(
        set(img for c in all_data.values() for img in c.keys()),
        key=lambda x: int(x.split("_")[-1]) if x.split("_")[-1].isdigit() else x,
    )

    # Compute stats per container×image
    computed = {
        c: {img: stats(all_data[c][img]) for img in all_images if img in all_data[c]}
        for c in container_names
    }

    # Read image URLs to map labels to readable names
    images_file = os.path.join(SCRIPT_DIR, "images.txt")
    image_urls = []
    if os.path.exists(images_file):
        with open(images_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    image_urls.append(line)
    image_display = {
        f"image_{i+1}": f"image_{i+1}\n({url.split('/')[-1][:20]}…)" if len(url) > 40 else f"image_{i+1}"
        for i, url in enumerate(image_urls)
    }

    # ---- README ----
    first_stats = next(s for c in computed.values() for s in c.values())
    n_iter = first_stats["n"]

    lines = [
        "# Benchmark Results\n",
        f"**Date**: {datetime.now().strftime('%Y-%m-%d %H:%M')}  ",
        f"**Iterations per image**: {n_iter}  ",
        f"**Confidence interval**: 95% (z = {CI_Z})\n",
        "| Container | Image | Mean (ms) | Median (ms) | P95 (ms) | Std Dev | 95% CI (±ms) |",
        "|-----------|-------|----------:|------------:|---------:|--------:|-------------:|",
    ]
    for container in container_names:
        for image in all_images:
            if image not in computed[container]:
                continue
            s = computed[container][image]
            lines.append(
                f"| `{container}` | {image} "
                f"| {s['mean']:.1f} | {s['median']:.1f} "
                f"| {s['p95']:.1f} | {s['std']:.1f} | ±{s['ci']:.1f} |"
            )

    if any(c in CONTAINER_DESCRIPTIONS for c in container_names):
        lines += ["", "## Changesets"]
        for container in container_names:
            desc = CONTAINER_DESCRIPTIONS.get(container)
            if desc:
                lines.append(f"- **`{container}`** — {desc}")

    lines += ["", "![Response Times](results.png)"]

    with open(README_PATH, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"README written: {README_PATH}")

    # ---- Graph ----
    n_containers = len(container_names)
    n_images = len(all_images)
    colors = [plt.cm.Set2(i / max(n_containers - 1, 1)) for i in range(n_containers)]

    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    fig.suptitle("Pastec Container Benchmark — Search Response Times", fontsize=13, fontweight="bold")

    # Left: grouped bar chart with 95% CI error bars
    ax = axes[0]
    x = np.arange(n_images)
    bar_width = 0.75 / n_containers

    for i, container in enumerate(container_names):
        means, cis = [], []
        for image in all_images:
            s = computed[container].get(image)
            means.append(s["mean"] if s else 0)
            cis.append(s["ci"] if s else 0)
        offset = (i - (n_containers - 1) / 2) * bar_width
        ax.bar(
            x + offset, means, bar_width,
            label=container, color=colors[i], alpha=0.85,
            yerr=cis, error_kw={"capsize": 4, "elinewidth": 1.5},
        )

    ax.set_xlabel("Image")
    ax.set_ylabel("Response Time (ms)")
    ax.set_title("Mean ± 95% CI")
    ax.set_xticks(x)
    ax.set_xticklabels(all_images)
    ax.legend(fontsize=8)
    ax.grid(axis="y", alpha=0.3)
    ax.set_ylim(bottom=0)

    # Right: box plot showing distribution
    ax = axes[1]
    box_data, positions, box_colors_list = [], [], []
    group_centers, group_ticks = [], []

    pos = 1
    for image in all_images:
        group_start = pos
        for i, container in enumerate(container_names):
            s = computed[container].get(image)
            if s:
                box_data.append(s["arr"])
                positions.append(pos)
                box_colors_list.append(colors[i])
                pos += 1
        group_centers.append((group_start + pos - 1) / 2)
        group_ticks.append(image)
        pos += 1  # gap between image groups

    bp = ax.boxplot(
        box_data, positions=positions, patch_artist=True, widths=0.6,
        medianprops={"color": "black", "linewidth": 2},
        whiskerprops={"linewidth": 1.2},
        capprops={"linewidth": 1.2},
        flierprops={"marker": ".", "markersize": 4, "alpha": 0.5},
    )
    for patch, color in zip(bp["boxes"], box_colors_list):
        patch.set_facecolor(color)
        patch.set_alpha(0.75)

    ax.set_xticks(group_centers)
    ax.set_xticklabels(group_ticks)
    ax.set_ylabel("Response Time (ms)")
    ax.set_title("Distribution")
    ax.grid(axis="y", alpha=0.3)
    ax.set_ylim(bottom=0)

    legend_patches = [
        mpatches.Patch(color=colors[i], label=c) for i, c in enumerate(container_names)
    ]
    ax.legend(handles=legend_patches, fontsize=8)

    plt.tight_layout()
    plt.savefig(GRAPH_PATH, dpi=150, bbox_inches="tight")
    print(f"Graph written: {GRAPH_PATH}")


if __name__ == "__main__":
    main()
