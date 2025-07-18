# Generated-By: Claude Sonnet 4
#!/bin/bash

# Script to create a sample etcd snapshot for testing octosql
# This script uses Docker containers to run etcd and create a snapshot

set -e

SNAPSHOT_FILE="/tmp/sample-etcd-snapshot.db"
ETCD_PORT="2479"  # Using non-standard port to avoid conflicts
ETCD_PEER_PORT="2480"
ETCD_IMAGE="quay.io/coreos/etcd:v3.5.10"
CONTAINER_NAME="etcd-sample-container"

echo "Creating sample etcd snapshot for octosql testing using Docker..."

# Clean up any existing data and containers
rm -f ${SNAPSHOT_FILE}
docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

# Start etcd in a Docker container
echo "Starting temporary etcd instance in Docker container..."
docker run -d \
    --name ${CONTAINER_NAME} \
    -p ${ETCD_PORT}:2379 \
    -p ${ETCD_PEER_PORT}:2380 \
    ${ETCD_IMAGE} \
    /usr/local/bin/etcd \
    --name sample-etcd \
    --listen-client-urls http://0.0.0.0:2379 \
    --advertise-client-urls http://0.0.0.0:2379 \
    --listen-peer-urls http://0.0.0.0:2380 \
    --initial-advertise-peer-urls http://0.0.0.0:2380 \
    --initial-cluster sample-etcd=http://0.0.0.0:2380 \
    --initial-cluster-token sample-cluster \
    --initial-cluster-state new \
    --log-level warn

# Wait for etcd to start
echo "Waiting for etcd to start..."
sleep 5

# Function to run etcdctl commands in the container
run_etcdctl() {
    docker exec -e ETCDCTL_API=3 ${CONTAINER_NAME} /usr/local/bin/etcdctl --endpoints=http://localhost:2379 "$@"
}

# Populate with sample Kubernetes-like data
echo "Populating etcd with sample data..."

# Sample pods
run_etcdctl put /registry/pods/default/nginx-deployment-abc123 '{"apiVersion":"v1","kind":"Pod","metadata":{"name":"nginx-deployment-abc123","namespace":"default","labels":{"app":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx:1.21","ports":[{"containerPort":80}]}]},"status":{"phase":"Running"}}'

run_etcdctl put /registry/pods/default/redis-pod-def456 '{"apiVersion":"v1","kind":"Pod","metadata":{"name":"redis-pod-def456","namespace":"default","labels":{"app":"redis"}},"spec":{"containers":[{"name":"redis","image":"redis:6.2","ports":[{"containerPort":6379}]}]},"status":{"phase":"Running"}}'

run_etcdctl put /registry/pods/kube-system/kube-proxy-ghi789 '{"apiVersion":"v1","kind":"Pod","metadata":{"name":"kube-proxy-ghi789","namespace":"kube-system","labels":{"app":"kube-proxy"}},"spec":{"containers":[{"name":"kube-proxy","image":"k8s.gcr.io/kube-proxy:v1.25.0"}]},"status":{"phase":"Running"}}'

# Sample services
run_etcdctl put /registry/services/default/nginx-service '{"apiVersion":"v1","kind":"Service","metadata":{"name":"nginx-service","namespace":"default"},"spec":{"selector":{"app":"nginx"},"ports":[{"port":80,"targetPort":80}],"type":"ClusterIP"}}'

run_etcdctl put /registry/services/default/redis-service '{"apiVersion":"v1","kind":"Service","metadata":{"name":"redis-service","namespace":"default"},"spec":{"selector":{"app":"redis"},"ports":[{"port":6379,"targetPort":6379}],"type":"ClusterIP"}}'

# Sample secrets
run_etcdctl put /registry/secrets/default/app-secret '{"apiVersion":"v1","kind":"Secret","metadata":{"name":"app-secret","namespace":"default"},"type":"Opaque","data":{"username":"YWRtaW4=","password":"MWYyZDFlMmU2N2Rm"}}'

run_etcdctl put /registry/secrets/kube-system/bootstrap-token '{"apiVersion":"v1","kind":"Secret","metadata":{"name":"bootstrap-token","namespace":"kube-system"},"type":"bootstrap.kubernetes.io/token"}'

# Sample config maps
run_etcdctl put /registry/configmaps/default/app-config '{"apiVersion":"v1","kind":"ConfigMap","metadata":{"name":"app-config","namespace":"default"},"data":{"config.yml":"server:\n  port: 8080\n  host: 0.0.0.0\ndatabase:\n  url: redis://redis-service:6379"}}'

# Sample deployments
run_etcdctl put /registry/deployments/default/nginx-deployment '{"apiVersion":"apps/v1","kind":"Deployment","metadata":{"name":"nginx-deployment","namespace":"default"},"spec":{"replicas":3,"selector":{"matchLabels":{"app":"nginx"}},"template":{"metadata":{"labels":{"app":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx:1.21","ports":[{"containerPort":80}]}]}}}}'

# Sample namespaces
run_etcdctl put /registry/namespaces/production '{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"production","labels":{"env":"prod"}}}'

run_etcdctl put /registry/namespaces/staging '{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"staging","labels":{"env":"staging"}}}'

# Sample service accounts
run_etcdctl put /registry/serviceaccounts/default/app-serviceaccount '{"apiVersion":"v1","kind":"ServiceAccount","metadata":{"name":"app-serviceaccount","namespace":"default"}}'

# Sample events (these are often numerous in real clusters)
run_etcdctl put /registry/events/default/nginx-event-1 '{"apiVersion":"v1","kind":"Event","metadata":{"name":"nginx-event-1","namespace":"default"},"involvedObject":{"kind":"Pod","name":"nginx-deployment-abc123"},"reason":"Started","message":"Started container nginx","type":"Normal","firstTimestamp":"2024-01-15T10:00:00Z"}'

run_etcdctl put /registry/events/default/nginx-event-2 '{"apiVersion":"v1","kind":"Event","metadata":{"name":"nginx-event-2","namespace":"default"},"involvedObject":{"kind":"Pod","name":"nginx-deployment-abc123"},"reason":"Pulled","message":"Container image nginx:1.21 already present on machine","type":"Normal","firstTimestamp":"2024-01-15T10:00:01Z"}'

# Sample node data
run_etcdctl put /registry/minions/worker-node-1 '{"apiVersion":"v1","kind":"Node","metadata":{"name":"worker-node-1","labels":{"kubernetes.io/hostname":"worker-node-1","node-role.kubernetes.io/worker":""}},"status":{"conditions":[{"type":"Ready","status":"True"}],"nodeInfo":{"kubeletVersion":"v1.25.0","osImage":"Ubuntu 20.04.5 LTS"}}}'

# Some custom application data
run_etcdctl put /custom/apps/web-app/config '{"database_url":"postgresql://db:5432/webapp","redis_url":"redis://redis:6379","debug":false,"max_connections":100}'

run_etcdctl put /custom/metrics/cpu_usage '{"timestamp":"2024-01-15T10:30:00Z","value":45.2,"unit":"percent","node":"worker-node-1"}'

run_etcdctl put /custom/feature-flags/new-ui '{"enabled":true,"rollout_percentage":25,"last_updated":"2024-01-15T09:00:00Z"}'

# Wait a moment for all writes to be processed
sleep 2

# Create the snapshot using etcdctl in the container
echo "Creating snapshot..."
docker exec -e ETCDCTL_API=3 ${CONTAINER_NAME} /usr/local/bin/etcdctl --endpoints=http://localhost:2379 snapshot save /tmp/snapshot.db
docker cp ${CONTAINER_NAME}:/tmp/snapshot.db ${SNAPSHOT_FILE}

# Verify the snapshot (basic file check)
echo "Verifying snapshot..."
if [ -f "${SNAPSHOT_FILE}" ] && [ -s "${SNAPSHOT_FILE}" ]; then
    echo "✓ Snapshot file created successfully"
    echo "  File size: $(du -h ${SNAPSHOT_FILE} | cut -f1)"
else
    echo "✗ Snapshot file verification failed"
    exit 1
fi

# Stop and remove the etcd container
echo "Stopping etcd container..."
docker rm -f ${CONTAINER_NAME}

# Copy to samples directory for convenience
SAMPLES_SNAPSHOT="samples/etcd.snapshot"
cp ${SNAPSHOT_FILE} ${SAMPLES_SNAPSHOT}

echo ""
echo "Sample etcd snapshot created successfully!"
echo "Snapshot file: ${SNAPSHOT_FILE}"
echo "Copied to: ${SAMPLES_SNAPSHOT}"
echo "File size: $(du -h ${SNAPSHOT_FILE} | cut -f1)"
echo ""
echo "Docker image used: ${ETCD_IMAGE}"
echo ""
echo "✓ Ready to test! You can now use octosql with this snapshot:"
echo "  docker build -t etcd-sre-tools ."
echo "  docker run -it -v \$(pwd)/samples:/samples:Z etcd-sre-tools"
echo "  # Inside container:"
echo "  cd /samples"
echo "  octosql \"SELECT COUNT(*) FROM etcd.snapshot\""
echo ""
echo "See the README.md file for sample queries and usage examples." 