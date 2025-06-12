
## Testing Methodology

- ✅ With write buffering enabled
- ✅ With write buffering disabled
- ✅ Both run under identical conditions: 30 minutes, concurrency = warehouses = 800

<br>

### Test Platform
Self Hosted CockroachDB Cluster
|Configuration|Value|
|----|-----|
|Cloud|AWS|
|Region|us-east-2|
|Nodes|3/3 Live across 3 AZs|
|Compute|m8g.xlarge|
|Storage | gp3 600 GiB disk, 9000 IOPS, 600 Throughput (MiB)|
|HAProxy|m6a.xlarge|
|App|m6a.xlarge|

### Data 
```
RESTORE DATABASE tpcc FROM LATEST in 's3://nollen-bucket/workloads/backup-tpcc-25.2/?AWS_ACCESS_KEY_ID={key}&AWS_SECRET_ACCESS_KEY={secret}';
```

### Test Command
```
cockroach workload run tpcc    --warehouses=800    --duration=30m    --display-every=1m    --concurrency=800    $CRDB_SH_URL
```

## Test Results
| Metric           | **Write Buffering: Enabled** | **Write Buffering: Disabled** | Change   | Winner     |
| ---------------- | ---------------------------- | ----------------------------- | -------- | ---------- |
| **tpmC**         | 9979.6                       | 10,025.0                      | 🔻 -0.5% | 🔁 Equal   |
| **Efficiency**   | 97.0%                        | 97.4%                         | 🔻 -0.4% | 🔁 Equal   |
| **Avg Latency**  | **212.4 ms**                 | 124.4 ms                      | 🔼 +71%  | ❌ Disabled |
| **p50 Latency**  | **117.4 ms**                 | 54.5 ms                       | 🔼 +115% | ❌ Disabled |
| **p95 Latency**  | **453.0 ms**                 | 209.7 ms                      | 🔼 +116% | ❌ Disabled |
| **p99 Latency**  | **2281.7 ms**                | 1811.9 ms                     | 🔼 +26%  | ❌ Disabled |
| **Max Latency**  | **14.5s**                    | 9.7s                          | 🔼 +49%  | ❌ Disabled |
| **Errors**       | 0                            | 0                             | 🔁 Equal | 🔁 Equal   |
| **Audit Checks** | ✅ PASS                       | ✅ PASS                        | 🔁 Equal | 🔁 Equal   |

---
<br><br>
# ✅ TL;DR: Final Verdict
- ✅ Disabling write buffering resulted in the same throughput, with meaningfully better latency.

| Use case                                 | Recommendation                                      |
| ---------------------------------------- | --------------------------------------------------- |
| **Low-latency OLTP**                     | ❌ Disable write buffering                           |
| **Batch-heavy or high-write throughput** | ✅ May benefit from buffering (but not in this case) |
| **Default setting (enabled)**            | Acceptable — but adds latency                       |

# 🧠 Interpretation
- **Throughput (tpmC) and efficiency are nearly identical** between the two runs (within 1% difference).

- **Latency is consistently and significantly higher when write buffering is enabled**:

    - Average and p50 latencies are more than 2× higher
    - p95 latency is over 2× higher
    - p99 and max latencies also increased, though less dramatically

This aligns with expectations: enabling kv.raft.write_buffering.enabled may help **batching and Raft coordination**, but in this case, **no performance gain was observed**, only added latency.