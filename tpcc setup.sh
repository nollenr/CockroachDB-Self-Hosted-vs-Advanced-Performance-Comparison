cockroach workload init tpcc \
   --warehouses=2000 \
   --drop \
   $CRDB_SH_URL

cockroach workload run tpcc \
   --warehouses=100 \
   --duration=10m \
   --display-every=10s \
   --concurrency=100 \
   $CRDB_SH_URL

cockroach workload run tpcc \
   --warehouses=2500 \
   --duration=10m \
   --display-every=10s \
   --concurrency=1000 \
   $CRDB_SH_URL

✅ Summary Table: What to Pull & Where
Metric	Source
tpmC	cockroach workload stdout
efficiency %	cockroach workload stdout
p95/p99 latency	cockroach workload stdout
CPU usage	DB Console or crdb_internal.node_metrics
Retry count	sql.txn.retries metric
Retry types	txn.restarts.% metrics
IOPS (optional)	Cloud monitoring (e.g., CloudWatch) 


🔹 Total Retries Across Cluster
sql
Copy
Edit
SELECT
  sum(value) AS total_retries
FROM crdb_internal.node_metrics
WHERE name = 'sql.txn.retries';


🔹 Retry Types Breakdown
sql
Copy
Edit
SELECT
  name,
  round(value::numeric, 2) AS val
FROM crdb_internal.node_metrics
WHERE name LIKE '%txn.restarts%';