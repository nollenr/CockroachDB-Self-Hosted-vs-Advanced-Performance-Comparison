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

## Self Hosted AWS Configuration
|Configuration|Value|
|----|-----|
|Cloud|AWS|
|Region|us-east-2|
|Nodes|3/3 Live|
|Compute|m8g.xlarge|
|Storage | gp3 600 GiB disk, 9000 IOPS, 600 Throughput|
|HAProxy|m6a.xlarge|
|App|m6a.xlarge|

## Advanced AWS Cluster Configuration
|Configuration|Value|
|-----|------|
|Cloud|AWS|
|Plan type|Advanced|
|Region|us-east-2|
|Nodes|3/3 Live|
|Compute|4 vCPU, 16 GiB RAM|
|Storage|600 GiB disk, 9000 IOPS|

## Advanced Azure Cluster Configuration
|Configuration|Value|
|-----|------|
|Cloud|Azure|
|Plan type|Advanced|
|Region|us-westus2|
|Nodes|3/3 Live|
|Compute|4 vCPU, 16 GiB RAM|
|Storage|512 GiB disk, ? IOPS|
---
## 1-Hour Stability Test

| Metric           | Self-Hosted AWS | Advanced Cluster AWS | Advanced Cluster Azure | Notable Insights                                                    |
| ---------------- | --------------- | -------------------- | ---------------------- | ------------------------------------------------------------------- |
| **Concurrency**  | 500             | 500                  | 500                    | Identical configuration across all environments.                    |
| **Warehouses**   | 500             | 500                  | 500                    | Benchmark load was evenly matched.                                  |
| **Duration**     | 3600s (1h)      | 3600s (1h)           | 3600s (1h)             | Full 1-hour sustained test on all setups.                           |
| **tpmC**         | 6287.4          | 6285.6               | 6265.5                 | <1% variance; throughput was nearly identical.                      |
| **Efficiency**   | 97.8%           | 97.8%                | 97.4%                  | Slight dip in Azure, but all clusters were highly efficient.        |
| **Avg Latency**  | 55.6 ms         | 71.9 ms              | 125.4 ms               | Self-hosted shows best average latency; Azure significantly higher. |
| **p95 Latency**  | 67.1 ms         | 88.1 ms              | 285.2 ms               | Tail latency on Azure was \~4× worse than self-hosted.              |
| **p99 Latency**  | 134.2 ms        | 234.9 ms             | 838.9 ms               | Extreme tail latency on Azure; 6× higher than self-hosted.          |
| **Max Latency**  | 4563.4 ms       | 7784.6 ms            | 10737.4 ms             | Azure had highest outlier latency by a large margin.                |
| **Errors**       | 0               | 0                    | 0                      | All tests ran error-free—no dropped or failed transactions.         |
| **Audit Status** | ✅ PASS          | ✅ PASS               | ✅ PASS                 | Strong transactional correctness on all clusters.                   |


Self-Hosted AWS is the latency leader at all percentiles with near-identical throughput to managed options.

Advanced Cluster AWS offers a solid balance—latency is moderately higher, but still within acceptable limits.

Advanced Cluster Azure delivers strong throughput and reliability but suffers from notable tail and outlier latency, potentially due to infrastructure or network effects in the Azure environment.

---

## Max Sustainable Performance

| Cluster     | Max Sustainable Concurrency | Max tpmC     | Efficiency | p95 Latency | Audit Compliance |
| ----------- | --------------------------- | ------------ | ---------- | ----------- | ---------------- |
| Self-Hosted | **900**                     | **11,095.9** | 95.9%      | 1006.6 ms   | ✅ All Pass       |
| Advanced    | 850                         | 10,424.5     | 95.4%      | 1275.1 ms   | ✅ All Pass       |

---

## Head-to-Head Comparison @ 850 Concurrency

| Metric           | Self-Hosted  | Advanced Cluster AWS | Advanced Cluster Azure | Winner            | Notable Insights                                                                               |
| ---------------- | ------------ | -------------------- | ---------------------- | ----------------- | ---------------------------------------------------------------------------------------------- |
| **tpmC**         | 10,479.9     | 10,424.5             | 4577.8                 | Self-Hosted       | Azure delivered less than half the throughput of the other two setups.                         |
| **Efficiency**   | 95.9%        | 95.4%                | 41.9%                  | Self-Hosted       | Azure's efficiency plummeted—potential signs of severe queuing, saturation, or node imbalance. |
| **Avg Latency**  | 398.6 ms     | 507.2 ms             | 28,032.8 ms            | Self-Hosted       | Azure’s average latency was **\~70× higher**, indicating deep systemic delay.                  |
| **p95 Latency**  | 738.2 ms     | 1275.1 ms            | 36,507.2 ms            | Self-Hosted       | Azure’s p95 latency = **\~29× higher** than self-hosted.                                       |
| **p99 Latency**  | 8053.1 ms    | 7516.2 ms            | 49,392.1 ms            | Advanced AWS      | AWS Advanced handles tail better than Self-Hosted here; Azure is far behind.                   |
| **Max Latency**  | 28.9 s       | 20.4 s               | 103.1 s                | Advanced AWS      | Azure hits 100+ second outliers—by far the worst spike behavior.                               |
| **Audit Status** | ✅ All Passed | ✅ All Passed         | ❌ Partial / Fails      | Self-Hosted / AWS | Azure failed at least one audit check and skipped others due to insufficient valid data.       |

At 850 concurrency, Azure Advanced Cluster is not production-ready without tuning or infrastructure changes. Meanwhile, Self-Hosted remains the strongest performer, especially for latency-sensitive workloads, while Advanced AWS provides a solid managed alternative with good tail behavior.

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


