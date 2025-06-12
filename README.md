# CockroachDB Self-Hosted vs Advanced Performance Comparison

---

## Objective

Compare a self-hosted CockroachDB cluster with an Advanced Cockroach Cloud cluster using the TPC-C benchmark across increasing levels of concurrency, with identical workloads, cluster configurations, and schema.

---

## Methodology

* Workload: `cockroach workload run tpcc`
* Warehouse count = Concurrency (to reduce contention)
* Duration: 10 minutes per test
* Metrics captured:

  * TPMC (newOrder throughput)
  * Efficiency (% of transactions completed without retry)
  * Latency (avg, p95, p99, max)
  * Audit check compliance

---

## Self Hosted Configuration
|Configuration|Value|
|----|-----|
|Cloud|AWS|
|Region|us-east-2|
|Nodes|3/3 Live|
|Compute|m8g.xlarge|
|Storage | gp3 600 GiB disk, 9000 IOPS, 600 Throughput|
|HAProxy|m6a.xlarge|
|App|m6a.xlarge|

## Advanced Cluster Configuration
|Configuration|Value|
|-----|------|
|Cloud|AWS|
|Plan type|Advanced|
|Region|us-east-2|
|Nodes|3/3 Live|
|Compute|4 vCPU, 16 GiB RAM|
|Storage|600 GiB disk, 9000 IOPS|

---
## 1-Hour Stability Test

| Metric        | Self-Hosted       | Advanced Cluster   |
|---------------|-------------------|---------------------|
| Concurrency   | 500               | 500                 |
| Warehouses    | 500               | 500                 |
| Duration      | 3600s (1 hour)    | 3600s (1 hour)      |
| tpmC          | 6287.4            | 6285.6              |
| Efficiency    | 97.8%             | 97.8%               |
| Avg Latency   | 55.6 ms           | 71.9 ms             |
| p95 Latency   | 67.1 ms           | 88.1 ms             |
| p99 Latency   | 134.2 ms          | 234.9 ms            |
| Max Latency   | 4563.4 ms         | 7784.6 ms           |
| Errors        | 0                 | 0                   |
| Audit Status  | ✅ PASS            | ✅ PASS              |

> Both clusters demonstrated stable, sustained throughput with excellent audit compliance. Self-hosted delivered slightly better latency at the same efficiency level.

---

## Max Sustainable Performance

| Cluster     | Max Sustainable Concurrency | Max tpmC     | Efficiency | p95 Latency | Audit Compliance |
| ----------- | --------------------------- | ------------ | ---------- | ----------- | ---------------- |
| Self-Hosted | **900**                     | **11,095.9** | 95.9%      | 1006.6 ms   | ✅ All Pass       |
| Advanced    | 850                         | 10,424.5     | 95.4%      | 1275.1 ms   | ✅ All Pass       |

---

## Head-to-Head Comparison @ 850 Concurrency

| Metric       | Self-Hosted  | Advanced Cluster | Winner      |
| ------------ | ------------ | ---------------- | ----------- |
| tpmC         | 10,479.9     | 10,424.5         | Self-Hosted |
| Efficiency   | 95.9%        | 95.4%            | Self-Hosted |
| Avg Latency  | 398.6 ms     | 507.2 ms         | Self-Hosted |
| p95 Latency  | 738.2 ms     | 1275.1 ms        | Self-Hosted |
| p99 Latency  | 8053.1 ms    | 7516.2 ms        | Advanced    |
| Max Latency  | 28.9 s       | 20.4 s           | Advanced    |
| Audit Status | ✅ All Passed | ✅ All Passed     | Tie         |

---

## Stress Point @ 950 Concurrency

| Metric       | Self-Hosted | Advanced Cluster | Winner      |
| ------------ | ----------- | ---------------- | ----------- |
| tpmC         | **8570.0**  | 6172.0           | Self-Hosted |
| Efficiency   | 70.1%       | 50.5%            | Self-Hosted |
| Avg Latency  | 9622.4 ms   | 17.1 s           | Self-Hosted |
| p95 Latency  | 24.7 s      | 28.9 s           | Self-Hosted |
| p99 Latency  | 40.8 s      | 32.2 s           | Advanced    |
| Max Latency  | 103.0 s     | 81.6 s           | Advanced    |
| Audit Status | ❌ 1 Fail    | ❌ 1 Fail         | Tie         |

> Both clusters showed signs of degradation at 950, but the self-hosted cluster sustained higher throughput and higher efficiency.

---

## Key Findings

* **Self-hosted cluster consistently delivered higher throughput and better latency under the same workloads**
* **Advanced cluster became unstable above 850 concurrency**, showing reduced efficiency and audit failures
* Both clusters showed linear scaling up to 800 concurrency
* **Self-hosted may benefit from tighter Raft locality and better control over storage/network configuration**

---

## Recommendations

* Use **850 concurrency** as the safe upper bound for Advanced Cluster
* Consider using **900–925 concurrency** on self-hosted if high throughput is required
* Monitor tail latency and retries closely above 900 on either cluster
* Consider additional tuning in Advanced Cluster: leaseholder placement, compactions, and range splits


