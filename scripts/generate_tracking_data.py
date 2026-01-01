import argparse
import json
import random
import time
import calendar
from datetime import datetime, date, timedelta
from pathlib import Path

def load_json(p):
    with open(p, "r", encoding="utf-8") as f:
        return json.load(f)

def save_json(p, data):
    with open(p, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

def month_days(y, m):
    n = calendar.monthrange(y, m)[1]
    return [date(y, m, d) for d in range(1, n + 1)]

def is_weekend(d):
    return d.weekday() >= 5

def fmt_iso(dt):
    ms = int(dt.microsecond / 1000)
    return dt.strftime("%Y-%m-%dT%H:%M:%S") + "." + f"{ms:03d}"

def fmt_midnight_iso(d):
    return datetime(d.year, d.month, d.day).strftime("%Y-%m-%dT00:00:00.000")

def jittered_durations(total_ms, count, cap_ms=69 * 60 * 1000):
    if count <= 0 or total_ms <= 0:
        return []
    base = total_ms / count
    base = min(base, cap_ms)
    res = []
    for _ in range(count):
        j = random.uniform(0.9, 1.1)
        v = int(max(1, base * j))
        v = min(v, cap_ms)
        res.append(v)
    s = sum(res)
    target = int(total_ms)
    if s < target:
        diff = target - s
        i = 0
        while diff > 0 and i < len(res) * 4:
            k = i % len(res)
            room = cap_ms - res[k]
            if room > 0:
                add = min(room, diff, int(base * 0.1) or 1)
                res[k] += add
                diff -= add
            i += 1
        # if diff remains, target is infeasible under cap; leave as is
    elif s > target:
        diff = s - target
        i = len(res) - 1
        while diff > 0 and i >= 0:
            dec = min(res[i] - 1, diff)
            res[i] -= dec
            diff -= dec
            i -= 1
    return res

def allocate_sessions(count, days, weekday_cap=2, weekend_cap=3, weekday_weight=1, weekend_weight=2, shuffle=True,
                      min_weekend_per_day=0, weekend_cap_min=None, weekend_cap_max=None):
    if count <= 0:
        return {d: 0 for d in days}
    weights = [weekend_weight if is_weekend(d) else weekday_weight for d in days]
    tw = sum(weights)
    ideal = [w * count / tw for w in weights]
    caps = []
    for d in days:
        if is_weekend(d):
            if weekend_cap_min is not None and weekend_cap_max is not None:
                cap = random.randint(int(weekend_cap_min), int(weekend_cap_max))
            else:
                cap = weekend_cap
            caps.append(cap)
        else:
            caps.append(weekday_cap)
    alloc = [min(caps[i], int(ideal[i])) for i in range(len(days))]
    remain = count - sum(alloc)
    frac = [(ideal[i] - int(ideal[i]), i) for i in range(len(days))]
    frac.sort(reverse=True)
    idx_cycle = [i for _, i in frac]
    if shuffle:
        random.shuffle(idx_cycle)
    k = 0
    while remain > 0 and k < len(idx_cycle) * 10:
        i = idx_cycle[k % len(idx_cycle)]
        if alloc[i] < caps[i]:
            alloc[i] += 1
            remain -= 1
        k += 1
    if remain > 0:
        order = list(range(len(days)))
        if shuffle:
            random.shuffle(order)
        i = 0
        while remain > 0 and i < len(order) * 10:
            j = order[i % len(order)]
            if alloc[j] < caps[j]:
                alloc[j] += 1
                remain -= 1
            i += 1
    if min_weekend_per_day and min_weekend_per_day > 0:
        for i, d in enumerate(days):
            if is_weekend(d) and alloc[i] > 0:
                target = min(caps[i], max(alloc[i], int(min_weekend_per_day)))
                delta = target - alloc[i]
                if delta > 0:
                    alloc[i] = target
    total = sum(alloc)
    if total > count:
        order = sorted(range(len(days)), key=lambda i: (not is_weekend(days[i]), alloc[i]), reverse=True)
        idx = 0
        while total > count and idx < len(order) * 5:
            i = order[idx % len(order)]
            min_allowed = min_weekend_per_day if is_weekend(days[i]) and alloc[i] > 0 else 0
            if alloc[i] > min_allowed:
                alloc[i] -= 1
                total -= 1
            idx += 1
    return {days[i]: alloc[i] for i in range(len(days))}

def rebalance_alloc(alloc_map, days, weekday_cap, weekend_cap, max_weekend_ratio=0.6):
    total = sum(alloc_map.values())
    if total == 0:
        return alloc_map
    weekend_idx = [i for i, d in enumerate(days) if is_weekend(d)]
    weekday_idx = [i for i, d in enumerate(days) if not is_weekend(d)]
    weekend_total = sum(alloc_map[days[i]] for i in weekend_idx)
    limit = int(total * max_weekend_ratio)
    if weekend_total <= limit:
        return alloc_map
    caps = [weekend_cap if is_weekend(d) else weekday_cap for d in days]
    while weekend_total > limit:
        w_candidates = sorted(weekend_idx, key=lambda i: alloc_map[days[i]], reverse=True)
        moved = False
        for wi in w_candidates:
            if alloc_map[days[wi]] <= 0:
                continue
            for di in weekday_idx:
                if alloc_map[days[di]] < caps[di]:
                    alloc_map[days[wi]] -= 1
                    alloc_map[days[di]] += 1
                    weekend_total -= 1
                    moved = True
                    break
            if moved:
                break
        if not moved:
            break
    return alloc_map

def gen_day_times(d, n):
    ts = []
    if n <= 0:
        return ts
    if is_weekend(d):
        allowed_hours = list(range(9, 24))
        span = len(allowed_hours)
        for i in range(n):
            idx = int((i + 1) * span / (n + 1)) - 1
            idx = max(0, min(span - 1, idx))
            h = allowed_hours[idx]
            m = random.randint(0, 59)
            s = random.randint(0, 59)
            ms = random.randint(0, 999)
            ts.append(datetime(d.year, d.month, d.day, h, m, s, ms * 1000))
    else:
        midday_hours = [12, 13]
        evening_hours = [18, 19, 20, 21, 22, 23]
        use_midday = min(n, len(midday_hours))
        use_evening = n - use_midday
        for i in range(use_midday):
            h = midday_hours[i % len(midday_hours)]
            m = random.randint(0, 59)
            s = random.randint(0, 59)
            ms = random.randint(0, 999)
            ts.append(datetime(d.year, d.month, d.day, h, m, s, ms * 1000))
        for i in range(use_evening):
            h = evening_hours[i % len(evening_hours)]
            m = random.randint(0, 59)
            s = random.randint(0, 59)
            ms = random.randint(0, 999)
            ts.append(datetime(d.year, d.month, d.day, h, m, s, ms * 1000))
    return ts

def parse_month_key(k):
    dt = datetime.strptime(k, "%Y-%m")
    return dt.year, dt.month

def build_aggregate_map(agg, source_habits):
    by_id = {h["id"]: h for h in source_habits}
    name_to_id = {h["name"]: h["id"] for h in source_habits}
    m = {}
    if isinstance(agg, dict) and "habits" in agg and isinstance(agg["habits"], list):
        for item in agg["habits"]:
            hid = item.get("id")
            if not hid:
                n = item.get("name")
                hid = name_to_id.get(n)
            if not hid or hid not in by_id:
                continue
            months = item.get("months", {})
            m[hid] = months
    elif isinstance(agg, dict):
        for k, v in agg.items():
            hid = k if k in by_id else name_to_id.get(k)
            if not hid:
                continue
            m[hid] = v
    return m

def month_key_from_ts(s):
    return s[:7]

def summarize_generated(h):
    sums = {}
    if h.get("trackTime", False):
        for k, arr in h.get("trackingDurations", {}).items():
            mk = month_key_from_ts(k)
            v = int(arr[0]) if arr else 0
            if mk not in sums:
                sums[mk] = {"count": 0, "duration_ms": 0}
            sums[mk]["count"] += 1
            sums[mk]["duration_ms"] += v
    else:
        for k in h.get("dailyCompletionStatus", {}).keys():
            mk = month_key_from_ts(k)
            if mk not in sums:
                sums[mk] = {"count": 0}
            sums[mk]["count"] += 1
    return sums

def verify_data(data, agg_map, tolerance_ms=0):
    report = []
    for h in data.get("habits", []):
        hid = h.get("id")
        g = summarize_generated(h)
        months = agg_map.get(hid, {})
        for mk, mv in months.items():
            ac = int(mv.get("count", 0))
            ad = mv.get("duration_ms")
            gc = int(g.get(mk, {}).get("count", 0))
            gd = g.get(mk, {}).get("duration_ms")
            if gd is None:
                gd = 0
            okc = (gc == ac)
            okd = True
            if ad is not None:
                cap_ms = 69 * 60 * 1000
                effective_expected = min(int(ad), ac * cap_ms)
                okd = abs(int(gd) - int(effective_expected)) <= int(tolerance_ms)
            elif ad is not None:
                okd = False
            status = okc and okd
            if not status:
                report.append({
                    "habit": h.get("name"),
                    "month": mk,
                    "expected_count": ac,
                    "actual_count": gc,
                    "expected_duration_ms": ad,
                    "actual_duration_ms": gd
                })
    return report

def process(source_path, aggregate_path, outdir=None, tolerance_ms=0, strict=False,
            weekday_cap=2, weekend_cap=3, weekday_weight=1, weekend_weight=2,
            max_weekend_ratio=0.6, shuffle_allocation=True,
            min_weekend_per_day=0, weekend_cap_min=None, weekend_cap_max=None):
    data = load_json(source_path)
    habits = data.get("habits", [])
    aggregates = load_json(aggregate_path)
    agg_map = build_aggregate_map(aggregates, habits)
    for h in habits:
        h["trackingDurations"] = {}
        h["dailyCompletionStatus"] = {}
        months = agg_map.get(h["id"], {})
        td = {}
        dcs = {}
        for mk, mv in months.items():
            y, m = parse_month_key(mk)
            cnt = int(mv.get("count", 0))
            total_ms = int(mv.get("duration_ms", 0))
            days = month_days(y, m)
            if h.get("trackTime", False):
                alloc = allocate_sessions(cnt, days, weekday_cap=weekday_cap, weekend_cap=weekend_cap,
                                          weekday_weight=weekday_weight, weekend_weight=weekend_weight,
                                          shuffle=shuffle_allocation,
                                          min_weekend_per_day=min_weekend_per_day,
                                          weekend_cap_min=weekend_cap_min,
                                          weekend_cap_max=weekend_cap_max)
                alloc = rebalance_alloc(alloc, days, weekday_cap, weekend_cap, max_weekend_ratio=max_weekend_ratio)
            else:
                alloc = allocate_sessions(cnt, days, weekday_cap=1, weekend_cap=1,
                                          weekday_weight=weekday_weight, weekend_weight=weekend_weight,
                                          shuffle=shuffle_allocation,
                                          min_weekend_per_day=0,
                                          weekend_cap_min=None,
                                          weekend_cap_max=None)
            per_day = []
            for d, n in alloc.items():
                if n > 0:
                    per_day.append((d, n))
            per_day.sort(key=lambda x: x[0])
            if h.get("trackTime", False):
                durations = jittered_durations(total_ms, cnt)
                di = 0
                for d, n in per_day:
                    times = gen_day_times(d, n)
                    if n > 0:
                        dcs[fmt_midnight_iso(d)] = True
                    for t in times:
                        if di < len(durations):
                            k = fmt_iso(t)
                            td[k] = [int(durations[di])]
                            di += 1
            else:
                for d, n in per_day:
                    if n > 0:
                        dcs[fmt_midnight_iso(d)] = True
        h["trackingDurations"] = td
        h["dailyCompletionStatus"] = dcs
    ts = str(int(time.time() * 1000))
    src = Path(source_path)
    target_dir = Path(outdir) if outdir else src.parent
    target_dir.mkdir(parents=True, exist_ok=True)
    out_path = target_dir / f"contrail_backup_{ts}.json"
    save_json(out_path, data)
    mismatches = verify_data(data, agg_map, tolerance_ms=tolerance_ms)
    if mismatches:
        print("VERIFY_FAIL " + json.dumps(mismatches, ensure_ascii=False))
        if strict:
            raise SystemExit(1)
    else:
        print("VERIFY_OK")
    print(str(out_path))

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--source", required=True)
    p.add_argument("--aggregates", required=True)
    p.add_argument("--outdir", default=None)
    p.add_argument("--tolerance_ms", type=int, default=0)
    p.add_argument("--strict", action="store_true")
    p.add_argument("--weekday_cap", type=int, default=2)
    p.add_argument("--weekend_cap", type=int, default=3)
    p.add_argument("--weekday_weight", type=int, default=1)
    p.add_argument("--weekend_weight", type=int, default=2)
    p.add_argument("--max_weekend_ratio", type=float, default=0.6)
    p.add_argument("--no_shuffle_allocation", action="store_true")
    p.add_argument("--min_weekend_per_day", type=int, default=0)
    p.add_argument("--weekend_cap_min", type=int, default=None)
    p.add_argument("--weekend_cap_max", type=int, default=None)
    args = p.parse_args()
    process(args.source, args.aggregates, args.outdir,
            tolerance_ms=args.tolerance_ms, strict=args.strict,
            weekday_cap=args.weekday_cap, weekend_cap=args.weekend_cap,
            weekday_weight=args.weekday_weight, weekend_weight=args.weekend_weight,
            max_weekend_ratio=args.max_weekend_ratio,
            shuffle_allocation=(not args.no_shuffle_allocation),
            min_weekend_per_day=args.min_weekend_per_day,
            weekend_cap_min=args.weekend_cap_min,
            weekend_cap_max=args.weekend_cap_max)

if __name__ == "__main__":
    main()
