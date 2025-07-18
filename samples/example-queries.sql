-- Generated-By: Claude Sonnet 4
-- Example SQL queries for testing octosql with etcd snapshots
-- These queries demonstrate various ways to analyze Kubernetes cluster data stored in etcd

-- =============================================================================
-- Basic Exploration Queries
-- =============================================================================

-- 1. Show all available data
SELECT * FROM etcdsnapshot LIMIT 10;

-- 2. Count total number of keys
SELECT COUNT(*) as total_keys FROM etcdsnapshot;

-- 3. List all unique key prefixes
SELECT DISTINCT SPLIT_PART(key, '/', 2) as prefix FROM etcdsnapshot ORDER BY prefix;

-- 4. Show the structure of etcd keys
SELECT 
    SPLIT_PART(key, '/', 1) as level1,
    SPLIT_PART(key, '/', 2) as level2,
    SPLIT_PART(key, '/', 3) as level3,
    COUNT(*) as count
FROM etcdsnapshot 
GROUP BY level1, level2, level3 
ORDER BY count DESC;

-- =============================================================================
-- Kubernetes Resource Analysis
-- =============================================================================

-- 5. Count Kubernetes resources by type
SELECT 
    SPLIT_PART(key, '/', 3) as resource_type,
    COUNT(*) as count
FROM etcdsnapshot 
WHERE key LIKE '/registry/%' 
GROUP BY resource_type 
ORDER BY count DESC;

-- 6. Find all pods with their status
SELECT 
    SPLIT_PART(key, '/', 4) as namespace,
    SPLIT_PART(key, '/', 5) as pod_name,
    JSON_EXTRACT(value, '$.status.phase') as phase,
    JSON_EXTRACT(value, '$.metadata.labels.app') as app_label
FROM etcdsnapshot 
WHERE key LIKE '/registry/pods/%'
ORDER BY namespace, pod_name;

-- 7. List all services and their specifications
SELECT 
    SPLIT_PART(key, '/', 4) as namespace,
    JSON_EXTRACT(value, '$.metadata.name') as service_name,
    JSON_EXTRACT(value, '$.spec.type') as service_type,
    JSON_EXTRACT(value, '$.spec.ports[0].port') as port
FROM etcdsnapshot 
WHERE key LIKE '/registry/services/%'
ORDER BY namespace, service_name;

-- 8. Analyze secrets by type and namespace
SELECT 
    SPLIT_PART(key, '/', 4) as namespace,
    JSON_EXTRACT(value, '$.metadata.name') as secret_name,
    JSON_EXTRACT(value, '$.type') as secret_type
FROM etcdsnapshot 
WHERE key LIKE '/registry/secrets/%'
ORDER BY namespace, secret_type;

-- 9. List deployments and their replica counts
SELECT 
    SPLIT_PART(key, '/', 4) as namespace,
    JSON_EXTRACT(value, '$.metadata.name') as deployment_name,
    JSON_EXTRACT(value, '$.spec.replicas') as replicas
FROM etcdsnapshot 
WHERE key LIKE '/registry/deployments/%'
ORDER BY namespace, deployment_name;

-- 10. Show all namespaces and their labels
SELECT 
    JSON_EXTRACT(value, '$.metadata.name') as namespace_name,
    JSON_EXTRACT(value, '$.metadata.labels') as labels
FROM etcdsnapshot 
WHERE key LIKE '/registry/namespaces/%'
ORDER BY namespace_name;

-- =============================================================================
-- Event Analysis
-- =============================================================================

-- 11. Analyze cluster events
SELECT 
    JSON_EXTRACT(value, '$.metadata.name') as event_name,
    JSON_EXTRACT(value, '$.metadata.namespace') as namespace,
    JSON_EXTRACT(value, '$.reason') as reason,
    JSON_EXTRACT(value, '$.message') as message,
    JSON_EXTRACT(value, '$.type') as event_type,
    JSON_EXTRACT(value, '$.firstTimestamp') as timestamp
FROM etcdsnapshot 
WHERE key LIKE '/registry/events/%'
ORDER BY timestamp;

-- 12. Count events by reason
SELECT 
    JSON_EXTRACT(value, '$.reason') as reason,
    COUNT(*) as event_count
FROM etcdsnapshot 
WHERE key LIKE '/registry/events/%'
GROUP BY reason
ORDER BY event_count DESC;

-- =============================================================================
-- Node Analysis
-- =============================================================================

-- 13. Show node information
SELECT 
    JSON_EXTRACT(value, '$.metadata.name') as node_name,
    JSON_EXTRACT(value, '$.status.nodeInfo.kubeletVersion') as kubelet_version,
    JSON_EXTRACT(value, '$.status.nodeInfo.osImage') as os_image,
    JSON_EXTRACT(value, '$.metadata.labels') as labels
FROM etcdsnapshot 
WHERE key LIKE '/registry/minions/%'
ORDER BY node_name;

-- =============================================================================
-- Custom Application Data Analysis
-- =============================================================================

-- 14. Analyze custom application configurations
SELECT 
    SPLIT_PART(key, '/', 4) as app_name,
    JSON_EXTRACT(value, '$.database_url') as database_url,
    JSON_EXTRACT(value, '$.redis_url') as redis_url,
    JSON_EXTRACT(value, '$.debug') as debug_mode,
    JSON_EXTRACT(value, '$.max_connections') as max_connections
FROM etcdsnapshot 
WHERE key LIKE '/custom/apps/%/config'
ORDER BY app_name;

-- 15. Monitor custom metrics
SELECT 
    SPLIT_PART(key, '/', 4) as metric_name,
    JSON_EXTRACT(value, '$.timestamp') as timestamp,
    JSON_EXTRACT(value, '$.value') as metric_value,
    JSON_EXTRACT(value, '$.unit') as unit,
    JSON_EXTRACT(value, '$.node') as node
FROM etcdsnapshot 
WHERE key LIKE '/custom/metrics/%'
ORDER BY timestamp;

-- 16. Feature flag analysis
SELECT 
    SPLIT_PART(key, '/', 4) as feature_name,
    JSON_EXTRACT(value, '$.enabled') as enabled,
    JSON_EXTRACT(value, '$.rollout_percentage') as rollout_percentage,
    JSON_EXTRACT(value, '$.last_updated') as last_updated
FROM etcdsnapshot 
WHERE key LIKE '/custom/feature-flags/%'
ORDER BY feature_name;

-- =============================================================================
-- Advanced Correlation Queries
-- =============================================================================

-- 17. Find pods and their corresponding services (join)
SELECT 
    p.namespace,
    p.pod_name,
    p.app_label,
    s.service_name,
    s.service_type
FROM (
    SELECT 
        SPLIT_PART(key, '/', 4) as namespace,
        SPLIT_PART(key, '/', 5) as pod_name,
        JSON_EXTRACT(value, '$.metadata.labels.app') as app_label
    FROM etcdsnapshot 
    WHERE key LIKE '/registry/pods/%'
) p
LEFT JOIN (
    SELECT 
        SPLIT_PART(key, '/', 4) as namespace,
        JSON_EXTRACT(value, '$.metadata.name') as service_name,
        JSON_EXTRACT(value, '$.spec.selector.app') as selector_app,
        JSON_EXTRACT(value, '$.spec.type') as service_type
    FROM etcdsnapshot 
    WHERE key LIKE '/registry/services/%'
) s ON p.app_label = s.selector_app AND p.namespace = s.namespace
ORDER BY p.namespace, p.pod_name;

-- 18. Resource distribution per namespace
SELECT 
    namespace,
    resource_type,
    COUNT(*) as resource_count
FROM (
    SELECT 
        SPLIT_PART(key, '/', 4) as namespace,
        SPLIT_PART(key, '/', 3) as resource_type
    FROM etcdsnapshot 
    WHERE key LIKE '/registry/%/%/%' 
    AND SPLIT_PART(key, '/', 4) != ''
) subq
GROUP BY namespace, resource_type 
ORDER BY namespace, resource_count DESC;

-- 19. Security analysis - find secrets without proper type
SELECT 
    SPLIT_PART(key, '/', 4) as namespace,
    JSON_EXTRACT(value, '$.metadata.name') as secret_name,
    JSON_EXTRACT(value, '$.type') as secret_type,
    CASE 
        WHEN JSON_EXTRACT(value, '$.type') IS NULL THEN 'WARNING: No type specified'
        WHEN JSON_EXTRACT(value, '$.type') = 'Opaque' THEN 'Generic secret'
        ELSE 'Typed secret'
    END as security_note
FROM etcdsnapshot 
WHERE key LIKE '/registry/secrets/%'
ORDER BY namespace, secret_name;

-- 20. Configuration drift detection - find objects with similar names
SELECT 
    namespace,
    resource_type,
    object_name,
    COUNT(*) as similar_count
FROM (
    SELECT 
        SPLIT_PART(key, '/', 4) as namespace,
        SPLIT_PART(key, '/', 3) as resource_type,
        SUBSTRING(JSON_EXTRACT(value, '$.metadata.name'), 1, 10) as object_name
    FROM etcdsnapshot 
    WHERE key LIKE '/registry/%' 
    AND JSON_EXTRACT(value, '$.metadata.name') IS NOT NULL
) subq
GROUP BY namespace, resource_type, object_name
HAVING COUNT(*) > 1
ORDER BY similar_count DESC;

-- =============================================================================
-- Utility Queries
-- =============================================================================

-- 21. Find keys with largest values (potential storage issues)
SELECT 
    key,
    LENGTH(value) as value_size,
    SPLIT_PART(key, '/', 3) as resource_type
FROM etcdsnapshot 
ORDER BY value_size DESC 
LIMIT 10;

-- 22. Show sample of each resource type
SELECT DISTINCT
    SPLIT_PART(key, '/', 3) as resource_type,
    (
        SELECT key 
        FROM etcdsnapshot e2 
        WHERE SPLIT_PART(e2.key, '/', 3) = SPLIT_PART(e1.key, '/', 3)
        LIMIT 1
    ) as sample_key
FROM etcdsnapshot e1
WHERE key LIKE '/registry/%'
ORDER BY resource_type;

-- 23. Health check - verify data integrity
SELECT 
    'Total Keys' as metric,
    COUNT(*) as value
FROM etcdsnapshot

UNION ALL

SELECT 
    'Registry Keys' as metric,
    COUNT(*) as value
FROM etcdsnapshot 
WHERE key LIKE '/registry/%'

UNION ALL

SELECT 
    'Custom Keys' as metric,
    COUNT(*) as value
FROM etcdsnapshot 
WHERE key LIKE '/custom/%'

UNION ALL

SELECT 
    'Valid JSON Values' as metric,
    COUNT(*) as value
FROM etcdsnapshot 
WHERE JSON_VALID(value) = 1;

-- =============================================================================
-- Reporting Queries
-- =============================================================================

-- 24. Cluster summary report
SELECT 
    'Cluster Resource Summary' as report_section,
    SPLIT_PART(key, '/', 3) as resource_type,
    COUNT(*) as count,
    COUNT(DISTINCT SPLIT_PART(key, '/', 4)) as unique_namespaces
FROM etcdsnapshot 
WHERE key LIKE '/registry/%'
GROUP BY resource_type
ORDER BY count DESC;

-- 25. Namespace utilization report
SELECT 
    'Namespace Utilization' as report_section,
    SPLIT_PART(key, '/', 4) as namespace,
    COUNT(*) as total_objects,
    COUNT(CASE WHEN SPLIT_PART(key, '/', 3) = 'pods' THEN 1 END) as pods,
    COUNT(CASE WHEN SPLIT_PART(key, '/', 3) = 'services' THEN 1 END) as services,
    COUNT(CASE WHEN SPLIT_PART(key, '/', 3) = 'secrets' THEN 1 END) as secrets
FROM etcdsnapshot 
WHERE key LIKE '/registry/%/%/%'
AND SPLIT_PART(key, '/', 4) != ''
GROUP BY namespace
ORDER BY total_objects DESC; 