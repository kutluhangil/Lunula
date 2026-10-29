#!/usr/bin/env bash
# Samples the running Lunula with top(1): median CPU %, median idle wakeups per second, last memory.
# Usage: Scripts/perf/measure-idle.sh [--seconds N] [--assert-idle]
# Exit: 0 ok, 1 budget exceeded (--assert-idle: CPU median > 0.1 or wakeups median > 1), 2 not running.
set -euo pipefail

seconds=60
assert_idle=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --seconds) seconds="$2"; shift 2 ;;
        --assert-idle) assert_idle=true; shift ;;
        *) echo "usage: $0 [--seconds N] [--assert-idle]" >&2; exit 64 ;;
    esac
done

pid=$(pgrep -x Lunula | head -1 || true)
if [[ -z "$pid" ]]; then
    echo "Lunula is not running"
    exit 2
fi

# top prints cumulative IDLEW; the first sample has no CPU interval, so it only seeds the wakeup delta.
result=$(top -l $((seconds + 1)) -s 1 -pid "$pid" -stats pid,cpu,idlew,mem | awk -v pid="$pid" '
    $1 == pid { n++; cpu[n] = $2; w[n] = $3; mem = $4 }
    function median(a, k,   i, j, t) {
        for (i = 1; i <= k; i++) for (j = i + 1; j <= k; j++) if (a[j] < a[i]) { t = a[i]; a[i] = a[j]; a[j] = t }
        return (k % 2) ? a[(k + 1) / 2] : (a[k / 2] + a[k / 2 + 1]) / 2
    }
    END {
        if (n < 2) { print "error"; exit }
        for (i = 2; i <= n; i++) { c[i - 1] = cpu[i]; d[i - 1] = w[i] - w[i - 1] }
        printf "cpu_median=%.2f idlew_median=%g mem=%s\n", median(c, n - 1), median(d, n - 1), mem
    }')

echo "$result"
if [[ "$result" == error ]]; then exit 2; fi
if $assert_idle; then
    awk -v r="$result" 'BEGIN {
        split(r, f, /[ =]/); cpu = f[2]; wake = f[4]
        exit (cpu > 0.1 || wake > 1) ? 1 : 0
    }'
fi
