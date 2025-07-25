#!/usr/bin/env bash

set -euo pipefail

: > benchmark.txt

for day in $(seq -w 1 25); do
  for release in Debug ReleaseSafe ReleaseFast ReleaseSmall; do
    binary="./zig-out/bin/bench-day${day}-${release}"
    for i in {0..4}; do
      $binary 2>/dev/null
    done

    # Append the output on the 5th run.
    $binary 2>> benchmark.txt
  done
done
