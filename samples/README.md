Generated-By: Claude Sonnet 4

# Sample etcd Snapshot for Testing octosql

This directory contains tools and examples for testing octosql with etcd snapshots using the `octosql-plugin-etcdsnapshot` plugin.

## Contents

- `create-sample-snapshot.sh` - Script to generate a sample etcd snapshot with realistic Kubernetes data
- `example-queries.sql` - Sample SQL queries demonstrating octosql capabilities with etcd data
- `sample-etcd-snapshot.db` - Pre-generated sample snapshot (created by running the script)

## Quick Start

> **✨ New**: The etcd snapshot file extension handler is now pre-configured in the container!

### Option 1: Use the pre-generated snapshot

If you want to jump straight into testing, you can use the pre-generated snapshot:

```bash
# Build and run the container
docker build -t etcd-sre-tools .

# For most systems:
docker run -it -v $(pwd)/samples:/samples etcd-sre-tools

# For SELinux systems (RHEL/Fedora/CentOS):
docker run -it -v $(pwd)/samples:/samples:Z etcd-sre-tools

# Inside the container, test octosql with the sample snapshot
cd /samples
octosql "SELECT COUNT(*) as total_keys FROM etcd.snapshot"
```

### Option 2: Generate a fresh snapshot

If you want to create your own sample data:

```bash
# Make the script executable
chmod +x samples/create-sample-snapshot.sh

# Run the script to generate a new snapshot
./samples/create-sample-snapshot.sh

# The snapshot will be created at /tmp/sample-etcd-snapshot.db
# Copy it to the samples directory if needed
cp /tmp/sample-etcd-snapshot.db samples/etcd.snapshot
```

## What's in the Sample Data

The sample etcd snapshot contains typical Kubernetes objects and custom data:

### Kubernetes Objects
- **Pods**: 3 sample pods in different namespaces
- **Services**: 2 services exposing the sample pods
- **Secrets**: 2 secrets with different types
- **ConfigMaps**: 1 application configuration
- **Deployments**: 1 nginx deployment
- **Namespaces**: 2 additional namespaces (production, staging)
- **ServiceAccounts**: 1 sample service account
- **Events**: 2 pod lifecycle events
- **Nodes**: 1 worker node definition

### Custom Application Data
- Application configuration under `/custom/apps/`
- Metrics data under `/custom/metrics/`
- Feature flags under `/custom/feature-flags/`

## Example octosql Queries

Here are some example queries you can run against the sample snapshot:

### 1. List all keys in the snapshot
```sql
SELECT key FROM etcdsnapshot ORDER BY key;
```

### 2. Count objects by type
```sql
SELECT 
    SPLIT_PART(key, '/', 3) as resource_type,
    COUNT(*) as count
FROM etcdsnapshot 
WHERE key LIKE '/registry/%' 
GROUP BY resource_type 
ORDER BY count DESC;
```

### 3. Find all pods
```sql
SELECT 
    key,
    JSON_EXTRACT(value, '$.metadata.name') as pod_name,
    JSON_EXTRACT(value, '$.metadata.namespace') as namespace,
    JSON_EXTRACT(value, '$.status.phase') as phase
FROM etcdsnapshot 
WHERE key LIKE '/registry/pods/%';
```

### 4. List services and their types
```sql
SELECT 
    JSON_EXTRACT(value, '$.metadata.name') as service_name,
    JSON_EXTRACT(value, '$.metadata.namespace') as namespace,
    JSON_EXTRACT(value, '$.spec.type') as service_type
FROM etcdsnapshot 
WHERE key LIKE '/registry/services/%';
```

### 5. Find secrets by type
```sql
SELECT 
    JSON_EXTRACT(value, '$.metadata.name') as secret_name,
    JSON_EXTRACT(value, '$.metadata.namespace') as namespace,
    JSON_EXTRACT(value, '$.type') as secret_type
FROM etcdsnapshot 
WHERE key LIKE '/registry/secrets/%';
```

### 6. Analyze custom application data
```sql
SELECT 
    key,
    JSON_EXTRACT(value, '$.database_url') as db_url,
    JSON_EXTRACT(value, '$.max_connections') as max_conn
FROM etcdsnapshot 
WHERE key LIKE '/custom/apps/%';
```

### 7. Monitor metrics data
```sql
SELECT 
    JSON_EXTRACT(value, '$.timestamp') as timestamp,
    JSON_EXTRACT(value, '$.value') as cpu_value,
    JSON_EXTRACT(value, '$.unit') as unit,
    JSON_EXTRACT(value, '$.node') as node
FROM etcdsnapshot 
WHERE key LIKE '/custom/metrics/%';
```

### 8. Feature flag analysis
```sql
SELECT 
    SPLIT_PART(key, '/', 4) as feature_name,
    JSON_EXTRACT(value, '$.enabled') as enabled,
    JSON_EXTRACT(value, '$.rollout_percentage') as rollout_pct
FROM etcdsnapshot 
WHERE key LIKE '/custom/feature-flags/%';
```

## Using octosql Interactive Mode

You can also use octosql in interactive mode for exploration:

```bash
# Start the container for interactive exploration
# For most systems:
docker run -it -v $(pwd)/samples:/samples etcd-sre-tools bash
# For SELinux systems:
docker run -it -v $(pwd)/samples:/samples:Z etcd-sre-tools bash

# Navigate to samples and run queries
cd /samples

# Run individual queries
octosql "SELECT COUNT(*) FROM etcd.snapshot"
octosql "SELECT * FROM etcd.snapshot LIMIT 5" --describe
```

## Advanced Queries

### Join data across different object types
```sql
-- Find pods and their corresponding services
SELECT 
    p.pod_name,
    p.namespace,
    s.service_name
FROM (
    SELECT 
        JSON_EXTRACT(value, '$.metadata.name') as pod_name,
        JSON_EXTRACT(value, '$.metadata.namespace') as namespace,
        JSON_EXTRACT(value, '$.metadata.labels.app') as app_label
    FROM etcdsnapshot 
    WHERE key LIKE '/registry/pods/%'
) p
LEFT JOIN (
    SELECT 
        JSON_EXTRACT(value, '$.metadata.name') as service_name,
        JSON_EXTRACT(value, '$.metadata.namespace') as namespace,
        JSON_EXTRACT(value, '$.spec.selector.app') as selector_app
    FROM etcdsnapshot 
    WHERE key LIKE '/registry/services/%'
) s ON p.app_label = s.selector_app AND p.namespace = s.namespace;
```

### Audit namespaces and their resources
```sql
-- Count resources per namespace
SELECT 
    SPLIT_PART(key, '/', 4) as namespace,
    SPLIT_PART(key, '/', 3) as resource_type,
    COUNT(*) as resource_count
FROM etcdsnapshot 
WHERE key LIKE '/registry/%/%/%' 
GROUP BY namespace, resource_type 
ORDER BY namespace, resource_count DESC;
```

## Tips for Using octosql with etcd Snapshots

1. **Use JSON functions**: etcd stores Kubernetes objects as JSON, so leverage `JSON_EXTRACT()` heavily
2. **Filter with LIKE**: Use pattern matching to filter by resource types or namespaces
3. **Use SPLIT_PART()**: Extract parts of the etcd key hierarchy for grouping and analysis
4. **Save results**: You can output query results to CSV or JSON for further analysis
5. **Explore incrementally**: Start with simple queries and build up complexity

## Troubleshooting

If you encounter issues:

1. **Plugin not found**: Ensure the `octosql-plugin-etcdsnapshot` plugin is in the plugin directory (`/usr/local/lib/octosql/plugins/`)
2. **File extension configuration**: The file extension handler is pre-configured in the container. If you need to verify it exists:
   ```bash
   cat ~/.octosql/file_extension_handlers.json
   # Should show: {"snapshot": "etcdsnapshot"}
   ```
3. **Snapshot file**: Ensure the snapshot file has the `.snapshot` extension and exists:
   ```bash
   ls -la /samples/etcd.snapshot
   ```
4. **Query errors**: Start with simple queries to understand the data structure:
   ```bash
   octosql "SELECT * FROM etcd.snapshot LIMIT 1" --describe
   ```
5. **Plugin verification**: Check that the plugin is properly installed:
   ```bash
   ls -la /usr/local/lib/octosql/plugins/octosql-plugin-etcdsnapshot
   ```
6. **Performance**: For large snapshots, use `LIMIT` clauses while developing queries
7. **SELinux permission issues**: If you're on RHEL, Fedora, or CentOS and getting permission denied errors, use the `:Z` flag:
   ```bash
   docker run -it -v $(pwd)/samples:/samples:Z etcd-sre-tools
   ```
   This properly labels the volume for SELinux context sharing.

## SELinux Systems

If you're running on a system with SELinux enabled (Red Hat Enterprise Linux, Fedora, CentOS), you need to use the `:Z` flag when mounting volumes to ensure proper security context labeling:

```bash
# Standard Docker command for SELinux systems
docker run -it -v $(pwd)/samples:/samples:Z etcd-sre-tools

# This applies the correct SELinux context to allow container access
```

**Why is this needed?**
- SELinux enforces mandatory access controls
- Container processes run in a confined security context
- The `:Z` flag tells Docker to apply the appropriate SELinux labels
- Without it, you'll get "Permission denied" errors even with correct file permissions

## Real-world Usage

This sample demonstrates how you can use octosql to:
- Audit Kubernetes cluster configuration
- Analyze resource distribution across namespaces
- Debug cluster issues by querying etcd directly
- Generate reports on cluster resource usage
- Monitor application-specific data stored in etcd 