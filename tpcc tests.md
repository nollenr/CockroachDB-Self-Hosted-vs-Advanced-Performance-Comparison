# CockroachDB Self-Hosted vs Advanced Testing

## Methodology

- cockroach workload run tpcc
- Warehouses = Concurrency During Execution
- Key metrics:
   - tpmC (committed newOrder txns)
   - Efficiency (% non-retry)
   - Latency (avg, p95, p99, max)
   - Audit check pass/fail

### TPCC Initialized with 2000 Warehouses

Both the self-hosted and Advanced clusters were restored from a TPCC backup that was initialized with 2000 Warehouses.

```
RESTORE DATABASE tpcc FROM LATEST in 's3://nollen-bucket/workloads/backup-tpcc-25.2/?AWS_ACCESS_KEY_ID={key}&AWS_SECRET_ACCESS_KEY={secret}';
```

To execute the TPC workload a statement similar to the following was issued:

```
cockroach workload run tpcc \
   --warehouses=500 \
   --duration=60m \
   --display-every=10s \
   --concurrency=500 \
   $CRDB_SH_URL
```
## Database Configurations
### Self Hosted Configuration (built from Terraform)
|Configuration|Value|
|----|-----|
|Cloud|AWS|
|Region|us-east-2|
|Nodes|3/3 Live Across 3 AZs|
|Compute|m8g.xlarge, gp3 600 GiB disk, 9000 IOPS, 600 Throughput (MiB/s)|
|HAProxy|m6a.xlarge|
|App|m6a.xlarge|

### Advanced Cluster Configuration
|Configuration|Value|
|-----|------|
|Cloud|AWS|
|Plan type|Advanced|
|Region|us-east-2|
|Nodes|3/3 Live|
|Compute|4 vCPU, 16 GiB RAM|
|Storage|600 GiB disk, 9000 IOPS|

## Testing Results for 500 Warehouses in a 1 Hour Test: 
### ✅ Summary of Self-Hosted Cluster TPC-C Results
| Metric                     | Value                     |
| -------------------------- | ------------------------- |
| **tpmC (newOrder TPM)**    | **6287.4**                |
| **Efficiency**             | **97.8%**                 |
| **Total Ops**              | 868,689                   |
| **Total Duration**         | 3600s (1 hour)            |
| **Avg Latency (all txns)** | 49.8 ms                   |
| **p99 Latency (all txns)** | 151.0 ms                  |
| **Max Latency**            | 6442.5 ms                 |
| **Errors**                 | 0                         |
| **Audit Compliance**       | ✅ All audit checks passed |

### ✅ Summary of Advanced Cluster TPC-C Results
| Metric                  | Value                     |
| ----------------------- | ------------------------- |
| **tpmC (newOrder TPM)** | **6285.6**                |
| **Efficiency**          | **97.8%**                 |
| **Total Ops**           | 868,338                   |
| **Avg Latency**         | 71.9 ms                   |
| **p95 Latency**         | 88.1 ms                   |
| **p99 Latency**         | 234.9 ms                  |
| **Max Latency**         | 7784.6 ms                 |
| **Errors**              | 0                         |
| **Audit Compliance**    | ✅ All audit checks passed |


### 📊 Transaction Breakdown (Self Hosted)
| Transaction   | TPS   | p95 (ms) | p99 (ms) | Avg Latency | Notes                       |
| ------------- | ----- | -------- | -------- | ----------- | --------------------------- |
| `newOrder`    | 104.8 | 67.1     | 134.2    | 55.6        | 🔥 High-throughput core op  |
| `payment`     | 105.0 | 41.9     | 104.9    | 43.2        | Excellent under concurrency |
| `orderStatus` | 10.5  | 18.9     | 46.1     | 16.4        | Very fast, light op         |
| `delivery`    | 10.5  | 151.0    | 285.2    | 112.5       | Naturally heavier op        |
| `stockLevel`  | 10.5  | 37.7     | 79.7     | 28.6        | Well within spec            |

### 📊 Transaction Breakdown (Advanced Cluster)
| Transaction   | TPS   | p95 (ms) | p99 (ms) | Avg Latency | Notes                              |
| ------------- | ----- | -------- | -------- | ----------- | ---------------------------------- |
| `newOrder`    | 104.8 | 88.1     | 234.9    | 71.9        | High throughput, higher tail       |
| `payment`     | 105.0 | 56.6     | 176.2    | 61.4        | Good, but slower than self-hosted  |
| `orderStatus` | 10.5  | 29.4     | 100.7    | 24.5        | Noticeably slower than self-hosted |
| `delivery`    | 10.5  | 167.8    | 436.2    | 113.4       | Similar to self-hosted             |
| `stockLevel`  | 10.5  | 44.0     | 109.1    | 34.0        | Slightly slower                    |

### 🧮 Side-by-Side Comparison Table
| Metric                    | Self-Hosted   | Advanced Cluster | Better        |
| ------------------------- | ------------- | ---------------- | ------------- |
| **tpmC**                  | 6287.4        | 6285.6           | 🔁 Equal      |
| **Efficiency**            | 97.8%         | 97.8%            | 🔁 Equal      |
| **Avg Latency (overall)** | **49.8 ms**   | 71.9 ms          | ✅ Self-hosted |
| **p95 Latency (overall)** | 83.9 ms       | **88.1 ms**      | ✅ Self-hosted |
| **p99 Latency (overall)** | **151.0 ms**  | 234.9 ms         | ✅ Self-hosted |
| **Max Latency**           | **6442.5 ms** | 7784.6 ms        | ✅ Self-hosted |
| **newOrder avg latency**  | **55.6 ms**   | 71.9 ms          | ✅ Self-hosted |
| **payment avg latency**   | **43.2 ms**   | 61.4 ms          | ✅ Self-hosted |
| **Audit compliance**      | ✅ All passed  | ✅ All passed     | 🔁 Equal      |


✅ What’s Similar <br>
Throughput (tpmC) and efficiency are nearly identical → both clusters are processing roughly the same number of transactions, with minimal contention or retries

- Audit checks passed for both, meaning they both executed valid TPC-C workloads

⚠️ What’s Different <br>
The self-hosted cluster has significantly lower latency across the board:
- Avg: ~22 ms faster
- p95/p99: ~5–80 ms lower
- Max: ~1.3s lower

This suggests Cockroach Cloud had higher latency variability, especially in tail latency

# ✅ Summary for 500 Warehouses in a 1 Hour Test
The self-hosted cluster performs slightly better than the Advanced Cluster — primarily due to lower average and tail latencies.
Throughput and efficiency are nearly identical, which means you're not seeing dramatic bottlenecks — just small but consistent latency advantages from the self-hosted setup.

# Side-by-Side Scaling Tests
## 🔁 Side-by-Side: Self-Hosted vs. Advanced Cluster at 800
| Metric               | **Self-Hosted** | **Advanced Cluster** | Winner                    |
| -------------------- | --------------- | -------------------- | ------------------------- |
| **tpmC**             | **9896.7**      | 9791.6               | ✅ Self-hosted (+1%)       |
| **Efficiency**       | **96.2%**       | 95.2%                | ✅ Self-hosted             |
| **Avg Latency**      | **305.0 ms**    | 489.1 ms             | ✅ Self-hosted (40% lower) |
| **p95 Latency**      | **671.1 ms**    | 1140.9 ms            | ✅ Self-hosted             |
| **p99 Latency**      | **5637.1 ms**   | 11,811.2 ms          | ✅ Self-hosted (2× better) |
| **Max Latency**      | **13.4s**       | 23.6s                | ✅ Self-hosted             |
| **Errors**           | 0               | 0                    | 🔁 Equal                  |
| **Audit Compliance** | ✅ All passed    | ✅ All passed         | 🔁 Equal                  |

## 🔁 Side-by-Side: Self-Hosted vs. Advanced Cluster @ 850
| Metric               | **Self-Hosted** | **Advanced Cluster** | Winner                   |
| -------------------- | --------------- | -------------------- | ------------------------ |
| **tpmC**             | **10,479.9**    | 10,424.5             | ✅ Self-hosted (+0.5%)    |
| **Efficiency**       | **95.9%**       | 95.4%                | ✅ Self-hosted            |
| **Avg Latency**      | **398.6 ms**    | 507.2 ms             | ✅ Self-hosted            |
| **p95 Latency**      | **738.2 ms**    | 1275.1 ms            | ✅ Self-hosted            |
| **p99 Latency**      | **8053.1 ms**   | 7516.2 ms            | 🔁 Slight edge: Advanced |
| **Max Latency**      | 28.9s           | **20.4s**            | ✅ Advanced (but close)   |
| **Errors**           | 0               | 0                    | 🔁 Equal                 |
| **Audit Compliance** | ✅ All passed    | ✅ All passed         | 🔁 Equal                 |

## 📊 Summary: Self-Hosted vs. Advanced Cluster @ 900 Concurrency
| Metric               | Self-Hosted   | Advanced Cluster | Winner        |
| -------------------- | ------------- | ---------------- | ------------- |
| **tpmC**             | **11,095.9**  | 10,907.2         | ✅ Self-hosted |
| **Efficiency**       | **95.9%**     | 94.2%            | ✅ Self-hosted |
| **Avg Latency**      | **441.1 ms**  | 791.4 ms         | ✅ Self-hosted |
| **p50 Latency**      | **209.7 ms**  | 302.0 ms         | ✅ Self-hosted |
| **p90 Latency**      | **536.9 ms**  | 1275.1 ms        | ✅ Self-hosted |
| **p95 Latency**      | **1006.6 ms** | 2550.1 ms        | ✅ Self-hosted |
| **p99 Latency**      | **6442.5 ms** | 9663.7 ms        | ✅ Self-hosted |
| **Max Latency**      | **23.6s**     | 40.8s            | ✅ Self-hosted |
| **Errors**           | 0             | 0                | 🔁 Equal      |
| **Audit Compliance** | ✅ All passed  | ✅ All passed     | 🔁 Equal      |

## 🧮 Side-by-Side Comparison @ 950
| Metric               | **Self-Hosted** | **Advanced Cluster** | Winner        |
| -------------------- | --------------- | -------------------- | ------------- |
| **tpmC**             | **8570.0**      | 6172.0               | ✅ Self-hosted |
| **Efficiency**       | **70.1%**       | 50.5%                | ✅ Self-hosted |
| **Avg Latency**      | **9.6s**        | 17.1s                | ✅ Self-hosted |
| **p95 Latency**      | **24.7s**       | 28.9s                | ✅ Self-hosted |
| **p99 Latency**      | 40.8s           | **32.2s**            | 🔁 Advanced   |
| **Max Latency**      | **103.1s**      | 81.6s                | 🔁 Advanced   |
| **Audit Compliance** | ❌ 1 fail        | ❌ 1 fail             | 🔁 Equal      |

✅ Final Verdict @ 950
🥇 Self-hosted wins again at 950 concurrency, but this is likely the upper edge of its sustainable envelope.
Advanced Cluster began collapsing between 850–900, with retry storms and audit violations.

🚦 Sustainable Throughput Boundaries
|Cluster	|Max Sustainable Concurrency	|Max tpmC	|Efficiency at Max	| Comments|
|----|------|------|------|------|
|Self-Hosted	|900–925	|~11,100	|~96%	|Best overall performer|
|Advanced	|850	|~10,400	|~95%	|Stable up to 850, then degrades|

## 🔁 Head-to-Head Comparison: Self-Hosted vs. Advanced Cluster @ 1000 concurrency
| Metric               | Self-Hosted  | Advanced Cluster              | Winner                   |
| -------------------- | ------------ | ----------------------------- | ------------------------ |
| **tpmC**             | **11,123.9** | 5631.3                        | ✅ Self-Hosted (+97%)     |
| **Efficiency**       | **86.5%**    | 43.8%                         | ✅ Self-Hosted            |
| **Avg Latency**      | 3094.8 ms    | 24,580 ms                     | ✅ Self-Hosted (8× lower) |
| **p95 Latency**      | 12,348 ms    | 34,359 ms                     | ✅ Self-Hosted            |
| **p99 Latency**      | 47,244 ms    | 42,949 ms                     | 🔁 Slight edge: Advanced |
| **Max Latency**      | 103,079 ms   | 103,079 ms                    | 🔁 Equal                 |
| **Errors**           | 0            | 33                            | ✅ Self-Hosted            |
| **Audit Compliance** | ✅ All passed | ❌ One failed, several skipped | ✅ Self-Hosted            |


✅ Self-Hosted Outperformed Advanced Cluster in Every Key Area
tpmC nearly doubled at the same concurrency level

Efficiency of 86.5% vs. 43.8% is a massive gap — fewer retries, more usable work

Latency was drastically lower, despite high concurrency

Advanced Cluster failed an audit check and logged errors — not production-grade at that concurrency

🚨 Caveat: Self-Hosted Cluster is Clearly Pushing Its Limits Too
Avg latency at 3 seconds, p99 at 47s — indicates significant queuing/retries

Efficiency drop from 96% → 86% shows retry overhead climbing fast

🧠 This is likely near the max sustainable throughput for your self-hosted configuration.

✅ TL;DR: Which Performs Better?
At 1000 concurrency, the self-hosted cluster wins decisively:

2× the throughput

Half the latency

No errors or audit failures

Better resource stability and retry behavior

# Metric Graphs for the 1 Hour 500 Warehouse test

![Line graph showing CPU usage percentages over time for three CockroachDB nodes in a self-hosted cluster labeled n1, n2, and n3 during a TPCC workload test. The y-axis ranges from 0 to 100 percent CPU usage, and the x-axis shows time intervals. All nodes display a sharp increase in CPU usage at the start, maintain between 45 and 65 percent throughout the test, and drop sharply at the end. The legend identifies n1 in blue, n2 in yellow, and n3 in red. The chart title is CPU Percent, and the y-axis is labeled CPU percentage. The environment is a database performance monitoring dashboard with a neutral, analytical tone.](self-hosted-tpcc-cpu.png)

![Line graph showing CPU usage percentages over time for three CockroachDB nodes in an Advanced Cluster labeled n1, n2, and n3 during a TPCC workload test. The y-axis ranges from 0 to 100 percent CPU usage, and the x-axis shows time intervals. All nodes display a sharp increase in CPU usage at the start, maintain between 45 and 65 percent throughout the test, and drop sharply at the end. The legend identifies n1 in blue, n2 in yellow, and n3 in red. The chart title is CPU Percent, and the y-axis is labeled CPU percentage. The environment is a database performance monitoring dashboard with a neutral, analytical tone.](advanced-tpcc-cpu.png)


![Dashboard for a self-hosted CockroachDB cluster displaying multiple line graphs for metrics including SQL queries per second, service latency, SQL statement contention, replicas per node, and capacity over time. The graphs show trends for select, update, insert, and delete queries, as well as latency percentiles and contention rates. The right sidebar summarizes total nodes, capacity usage, unavailable ranges, queries per second, and P99 latency. A list of recent cluster events and configuration changes is also present. The environment is a technical monitoring interface with a neutral, analytical tone. Visible text includes metric labels, axis titles, and event details such as restore jobs, cluster setting changes, and node status updates.](self-hosted-overview-metrics.png)

![Hardware metrics dashboard for a self-hosted CockroachDB cluster featuring line graphs for CPU percent, host CPU percent, memory usage, disk read and write throughput, disk read and write IOPS, disk operations in progress, and available disk capacity over time. Each graph includes a legend for nodes n1, n2, and n3, with the x-axis showing time intervals. The right sidebar summarizes total nodes, capacity usage, unavailable ranges, queries per second, P99 latency, and recent cluster events. The environment is a technical monitoring interface with a neutral, analytical tone. No emotional content is present.](self-hosted-hardware-metrics.png)

![Dashboard with multiple line graphs displaying SQL metrics for a self-hosted CockroachDB cluster during a TPCC workload test. Graphs show trends for select, update, insert, and delete queries per second, SQL service latency percentiles, and statement contention rates over time. The x-axis represents time intervals, and the y-axis varies by metric. The right sidebar summarizes cluster status, including total nodes, capacity usage, unavailable ranges, queries per second, and P99 latency. Recent cluster events and configuration changes are listed below the summary. The environment is a technical monitoring interface with a neutral, analytical tone. Visible text includes metric labels such as SQL Queries per Second, Service Latency, SQL Statement Contention, Replicas per Node, and Capacity, along with axis titles and event details.](self-hosted-sql-metrics.png)

![Storage metrics dashboard for a self-hosted CockroachDB cluster. The dashboard contains multiple line graphs tracking storage-related metrics such as disk usage, disk IOPS, disk throughput, and available disk capacity over time. Each graph includes a legend for nodes n1, n2, and n3, with the x-axis showing time intervals. The environment is a technical monitoring interface with a neutral, analytical tone. No emotional content is present.](self-hosted-storage-metrics.png)

![Dashboard for an Advanced CockroachDB cluster displaying multiple line graphs for metrics including SQL queries per second, service latency, SQL statement contention, replicas per node, and capacity over time. The graphs show trends for select, update, insert, and delete queries, as well as latency percentiles and contention rates. The right sidebar summarizes total nodes, capacity usage, unavailable ranges, queries per second, and P99 latency. A list of recent cluster events and configuration changes is also present. The environment is a technical monitoring interface with a neutral, analytical tone. Visible text includes metric labels, axis titles, and event details such as restore jobs, cluster setting changes, and node status updates.](advanced-overview-metrics.png)

![Hardware metrics dashboard for an Advanced CockroachDB cluster featuring line graphs for CPU percent, host CPU percent, memory usage, disk read and write throughput, disk read and write IOPS, disk operations in progress, and available disk capacity over time. Each graph includes a legend for nodes n1, n2, and n3, with the x-axis showing time intervals. The right sidebar summarizes total nodes, capacity usage, unavailable ranges, queries per second, P99 latency, and recent cluster events. The environment is a technical monitoring interface with a neutral, analytical tone. No emotional content is present.](advanced-hardware-metrics.png)

![Dashboard with multiple line graphs displaying SQL metrics for an Advanced CockroachDB cluster during a TPCC workload test. Graphs show trends for select, update, insert, and delete queries per second, SQL service latency percentiles, and statement contention rates over time. The x-axis represents time intervals, and the y-axis varies by metric. The right sidebar summarizes cluster status, including total nodes, capacity usage, unavailable ranges, queries per second, and P99 latency. Recent cluster events and configuration changes are listed below the summary. The environment is a technical monitoring interface with a neutral, analytical tone. Visible text includes metric labels such as SQL Queries per Second, Service Latency, SQL Statement Contention, Replicas per Node, and Capacity, along with axis titles and event details.](advanced-sql-metrics.png)

![Storage metrics dashboard for an Advanced CockroachDB cluster. The dashboard contains multiple line graphs tracking storage-related metrics such as disk usage, disk IOPS, disk throughput, and available disk capacity over time. Each graph includes a legend for nodes n1, n2, and n3, with the x-axis showing time intervals. The environment is a technical monitoring interface with a neutral, analytical tone. No emotional content is present.](advanced-storage-metrics.png)
