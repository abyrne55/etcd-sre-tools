Generated-By: Claude Sonnet 4

# Sample etcd Snapshot for Testing octosql

> [!WARNING]  
> Everything in this directory is AI-generated. The code runs and the sample queries work with the sample data (for the most part), but don't expect the generated etcd snapshot to match what you'd get out of a real OpenShift/K8s cluster.

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

> **💡 Important Syntax Notes:**
> - `key` is a reserved keyword in octosql, so always use a table alias like `d.key`
> - When running queries in bash/docker, use double quotes around the SQL and escape inner quotes properly
> - Use single quotes for string literals in SQL (e.g., `'/registry/pods/%'`)

### 1. List all keys in the snapshot
```sql
SELECT d.key FROM etcd.snapshot d ORDER BY d.key;
```

**Command line example:**
```bash
octosql "SELECT d.key FROM etcd.snapshot d ORDER BY d.key"
```

### 2. Count objects by type
```sql
SELECT 
    SUBSTR(d.key, 11) as resource_type,
    COUNT(*) as count
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/%' 
GROUP BY resource_type 
ORDER BY count DESC;
```

### 3. Find all pods
```sql
SELECT 
    d.key,
    name as pod_name,
    namespace,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/pods/%' AND name IS NOT NULL;
```

**Command line example:**
```bash
octosql "SELECT d.key, name as pod_name, namespace FROM etcd.snapshot d WHERE d.key LIKE '/registry/pods/%' AND name IS NOT NULL"
```

### 4. List services and their types
```sql
SELECT 
    name as service_name,
    namespace,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/services/%' AND name IS NOT NULL;
```

### 5. Find secrets by type
```sql
SELECT 
    name as secret_name,
    namespace,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/secrets/%' AND name IS NOT NULL;
```

### 6. Analyze custom application data
```sql
SELECT 
    d.key,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/custom/apps/%';
```

### 7. Monitor metrics data
```sql
SELECT 
    d.key,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/custom/metrics/%';
```

### 8. Feature flag analysis
```sql
SELECT 
    SPLIT_PART(d.key, '/', 4) as feature_name,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/custom/feature-flags/%';
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

# Run individual queries (note the table alias 'd' for accessing key column)
octosql "SELECT COUNT(*) FROM etcd.snapshot"
octosql "SELECT d.key, name, namespace FROM etcd.snapshot d LIMIT 5"
octosql "SELECT * FROM etcd.snapshot LIMIT 5" --describe
```

## Advanced Queries

### Join data across different object types
```sql
-- Find pods and their corresponding services by namespace
SELECT 
    p.name as pod_name,
    p.namespace,
    s.name as service_name
FROM etcd.snapshot p
LEFT JOIN etcd.snapshot s 
    ON p.namespace = s.namespace 
    AND p.key LIKE '/registry/pods/%' 
    AND s.key LIKE '/registry/services/%'
WHERE p.key LIKE '/registry/pods/%' 
    AND p.name IS NOT NULL;
```

### Audit namespaces and their resources
```sql
-- Count resources per namespace using pre-parsed columns
SELECT 
    namespace,
    resourceType,
    COUNT(*) as resource_count
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/%' 
    AND namespace IS NOT NULL 
    AND resourceType IS NOT NULL
GROUP BY namespace, resourceType 
ORDER BY namespace, resource_count DESC;
```

## Tips for Using octosql with etcd Snapshots

1. **Use table aliases for key column**: Since `key` is reserved, always use an alias: `SELECT d.key FROM etcd.snapshot d`
2. **Use pre-parsed columns**: The etcd plugin parses JSON data into structured columns like `name`, `namespace`, `resourceType` - use these instead of parsing JSON manually
3. **Quote escaping in bash**: Use double quotes around SQL and single quotes for string literals: `octosql "SELECT d.key FROM etcd.snapshot d WHERE d.key LIKE '/registry/pods/%'"`
4. **Filter with LIKE**: Use pattern matching to filter by resource types or namespaces
5. **Use pre-parsed columns**: The etcd plugin provides structured columns like `namespace`, `resourceType` - use these instead of parsing keys manually
6. **Save results**: You can output query results to CSV or JSON for further analysis
7. **Explore incrementally**: Start with simple queries and build up complexity
8. **Check for NULL values**: Use `WHERE name IS NOT NULL` to filter out entries without names

## Troubleshooting

If you encounter issues:

1. **Plugin not found**: Ensure the `octosql-plugin-etcd.snapshot` plugin is in the plugin directory (`/usr/local/lib/octosql/plugins/`)
2. **File extension configuration**: The file extension handler is pre-configured in the container. If you need to verify it exists:
   ```bash
   cat ~/.octosql/file_extension_handlers.json
   # Should show: {"snapshot": "etcd.snapshot"}
   ```
3. **Snapshot file**: Ensure the snapshot file has the `.snapshot` extension and exists:
   ```bash
   ls -la /samples/etcd.snapshot
   ```
4. **Query errors**: Start with simple queries to understand the data structure:
   ```bash
   octosql "SELECT * FROM etcd.snapshot LIMIT 1" --describe
   octosql "SELECT d.key, name, namespace FROM etcd.snapshot d LIMIT 5"
   ```
5. **Plugin verification**: Check that the plugin is properly installed:
   ```bash
   ls -la /usr/local/lib/octosql/plugins/octosql-plugin-etcd.snapshot
   ```
6. **Performance**: For large snapshots, use `LIMIT` clauses while developing queries
7. **SELinux permission issues**: If you're on RHEL, Fedora, or CentOS and getting permission denied errors, use the `:Z` flag:
   ```bash
   docker run -it -v $(pwd)/samples:/samples:Z etcd-sre-tools
   ```
   This properly labels the volume for SELinux context sharing.

## SELinux Systems

If you're running on a system with SELinux enabled (Red Hat Enterprise Linux, Fedora, CentOS), you need to use the `