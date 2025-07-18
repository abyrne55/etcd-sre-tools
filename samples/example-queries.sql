-- Generated-By: Claude Sonnet 4
-- Example SQL queries for testing octosql with etcd snapshots
-- These queries demonstrate various ways to analyze Kubernetes cluster data stored in etcd

-- =============================================================================
-- IMPORTANT SYNTAX NOTES
-- =============================================================================
-- 1. 'key' is a reserved keyword in octosql - always use table alias: d.key
-- 2. Use single quotes for string literals: '/registry/pods/%'
-- 3. Command line usage: octosql "SELECT d.key FROM etcd.snapshot d"
-- 4. The etcd plugin provides pre-parsed columns: name, namespace, resourceType
-- 5. Avoid unsupported functions like SPLIT_PART, JSON_EXTRACT - use pre-parsed columns instead
-- =============================================================================

-- =============================================================================
-- Basic Exploration Queries
-- =============================================================================

-- 1. Show all available data
SELECT * FROM etcd.snapshot LIMIT 10;

-- 2. Count total number of keys
SELECT COUNT(*) as total_keys FROM etcd.snapshot;

-- 3. List all unique resource types using pre-parsed column
SELECT DISTINCT resourceType as resource_type FROM etcd.snapshot WHERE resourceType IS NOT NULL ORDER BY resource_type;

-- 4. Show the structure of etcd keys using SUBSTR for basic parsing
SELECT 
    SUBSTR(d.key, 1, 10) as key_prefix,
    COUNT(*) as count
FROM etcd.snapshot d
GROUP BY key_prefix 
ORDER BY count DESC;

-- =============================================================================
-- Kubernetes Resource Analysis
-- =============================================================================

-- 5. Count Kubernetes resources by type using pre-parsed column
SELECT 
    resourceType,
    COUNT(*) as count
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/%' AND resourceType IS NOT NULL
GROUP BY resourceType 
ORDER BY count DESC;

-- 6. Find all pods with their status
SELECT 
    namespace,
    name as pod_name,
    resourceType,
    d.key
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/pods/%' AND name IS NOT NULL
ORDER BY namespace, pod_name;

-- 7. List all services and their specifications
SELECT 
    namespace,
    name as service_name,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/services/%' AND name IS NOT NULL
ORDER BY namespace, service_name;

-- 8. Analyze secrets by type and namespace
SELECT 
    namespace,
    name as secret_name,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/secrets/%' AND name IS NOT NULL
ORDER BY namespace, secret_name;

-- 9. List deployments and their replica counts
SELECT 
    namespace,
    name as deployment_name,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/deployments/%' AND name IS NOT NULL
ORDER BY namespace, deployment_name;

-- 10. Show all namespaces and their labels
SELECT 
    name as namespace_name,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/namespaces/%' AND name IS NOT NULL
ORDER BY namespace_name;

-- =============================================================================
-- Event Analysis
-- =============================================================================

-- 11. Analyze cluster events
SELECT 
    name as event_name,
    namespace,
    value,
    key
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/events/%' AND name IS NOT NULL
ORDER BY key;

-- 12. Count events by namespace
SELECT 
    namespace,
    COUNT(*) as event_count
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/events/%' AND namespace IS NOT NULL
GROUP BY namespace
ORDER BY event_count DESC;

-- =============================================================================
-- Node Analysis
-- =============================================================================

-- 13. Show node information
SELECT 
    name as node_name,
    value,
    key
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/minions/%' AND name IS NOT NULL
ORDER BY node_name;

-- =============================================================================
-- Custom Application Data Analysis
-- =============================================================================

-- 14. Analyze custom application configurations
SELECT 
    SUBSTR(d.key, 14) as app_config_path,
    d.key,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/custom/apps/%/config'
ORDER BY app_config_path;

-- 15. Monitor custom metrics
SELECT 
    SUBSTR(d.key, 17) as metric_path,
    d.key,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/custom/metrics/%'
ORDER BY d.key;

-- 16. Feature flag analysis
SELECT 
    SUBSTR(d.key, 22) as feature_path,
    d.key,
    value
FROM etcd.snapshot d
WHERE d.key LIKE '/custom/feature-flags/%'
ORDER BY feature_path;

-- =============================================================================
-- Advanced Correlation Queries
-- =============================================================================

-- 17. Find pods and their corresponding services (join by namespace)
SELECT 
    p.namespace,
    p.name as pod_name,
    s.name as service_name
FROM etcd.snapshot p
LEFT JOIN etcd.snapshot s ON p.namespace = s.namespace 
    AND s.key LIKE '/registry/services/%' 
    AND s.name IS NOT NULL
WHERE p.key LIKE '/registry/pods/%' 
    AND p.name IS NOT NULL
ORDER BY p.namespace, p.name;

-- 18. Resource distribution per namespace using pre-parsed columns
SELECT 
    namespace,
    resourceType as resource_type,
    COUNT(*) as resource_count
FROM etcd.snapshot d 
WHERE d.key LIKE '/registry/%' 
    AND namespace IS NOT NULL 
    AND resourceType IS NOT NULL
GROUP BY namespace, resourceType 
ORDER BY namespace, resource_count DESC;

-- 19. Security analysis - find secrets in each namespace
SELECT 
    namespace,
    name as secret_name,
    value,
    'Check secret type in value field' as security_note
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/secrets/%' AND name IS NOT NULL
ORDER BY namespace, secret_name;

-- 20. Configuration drift detection - find objects with similar names
SELECT 
    namespace,
    resourceType,
    SUBSTRING(name, 1, 10) as name_prefix,
    COUNT(*) as similar_count
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/%' 
    AND name IS NOT NULL
    AND namespace IS NOT NULL
    AND resourceType IS NOT NULL
GROUP BY namespace, resourceType, SUBSTRING(name, 1, 10)
HAVING COUNT(*) > 1
ORDER BY similar_count DESC;

-- =============================================================================
-- Utility Queries
-- =============================================================================

-- 21. Find keys with largest values (potential storage issues)
SELECT 
    d.key,
    LENGTH(value) as value_size,
    resourceType as resource_type
FROM etcd.snapshot d
WHERE resourceType IS NOT NULL
ORDER BY value_size DESC 
LIMIT 10;

-- 22. Show sample of each resource type
SELECT DISTINCT
    resourceType as resource_type,
    (
        SELECT e2.key 
        FROM etcd.snapshot e2 
        WHERE e2.resourceType = e1.resourceType 
        LIMIT 1
    ) as sample_key
FROM etcd.snapshot e1
WHERE e1.key LIKE '/registry/%' AND e1.resourceType IS NOT NULL
ORDER BY resource_type;

-- 23. Health check - verify data integrity
SELECT 
    'Total Keys' as metric,
    COUNT(*) as value
FROM etcd.snapshot d

UNION ALL

SELECT 
    'Registry Keys' as metric,
    COUNT(*) as value
FROM etcd.snapshot d 
WHERE d.key LIKE '/registry/%'

UNION ALL

SELECT 
    'Custom Keys' as metric,
    COUNT(*) as value
FROM etcd.snapshot d 
WHERE d.key LIKE '/custom/%'

UNION ALL

SELECT 
    'Non-empty Values' as metric,
    COUNT(*) as value
FROM etcd.snapshot d 
WHERE value IS NOT NULL AND LENGTH(value) > 0;

-- =============================================================================
-- Reporting Queries
-- =============================================================================

-- 24. Cluster summary report using pre-parsed columns
SELECT 
    'Cluster Resource Summary' as report_section,
    resourceType as resource_type,
    COUNT(*) as count,
    COUNT(DISTINCT namespace) as unique_namespaces
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/%' AND resourceType IS NOT NULL
GROUP BY resourceType
ORDER BY count DESC;

-- 25. Namespace utilization report using pre-parsed columns
SELECT 
    'Namespace Utilization' as report_section,
    namespace,
    COUNT(*) as total_objects,
    COUNT(CASE WHEN resourceType = 'pods' THEN 1 END) as pods,
    COUNT(CASE WHEN resourceType = 'services' THEN 1 END) as services,
    COUNT(CASE WHEN resourceType = 'secrets' THEN 1 END) as secrets
FROM etcd.snapshot d
WHERE d.key LIKE '/registry/%'
AND namespace IS NOT NULL
AND resourceType IS NOT NULL
GROUP BY namespace
ORDER BY total_objects DESC; 