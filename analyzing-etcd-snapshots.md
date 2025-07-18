# Collecting and analyzing etcd snapshots

```bash
# Pick the first etcd pod and debug-into its node
ETCD_POD=$(oc get po -nopenshift-etcd -lapp=etcd -oname | head -n1)
ETCD_POD_NODE=$(oc get -nopenshift-etcd $ETCD_POD -o=jsonpath='{.spec.nodeName}')
ocm backplane elevate -n -- debug node/$ETCD_POD_NODE

# Once in the debug pod...
chroot /host
ETCDCTL_CONTAINER_ID=$(crictl ps --name=etcdctl -o json | jq -r .containers[0].id)
TMP_DIR=$(mktemp -d)
crictl exec $ETCDCTL_CONTAINER_ID /bin/sh -c "unset ETCDCTL_ENDPOINTS; etcdctl snapshot save etcd.snapshot; gzip -f etcd.snapshot"
crictl exec $ETCDCTL_CONTAINER_ID /bin/cat etcd.snapshot.gz | gunzip > $TMP_DIR/etcd.snapshot
crictl exec $ETCDCTL_CONTAINER_ID /bin/rm etcd.snapshot.gz

# Now that we have the snapshot, hop into an octosql container
podman run -it --rmi -v $TMP_DIR:/snapshot:Z quay.io/abyrne_openshift/octosql-etcd:latest

# Once inside the tools container...
cd /snapshot

# See the schema
octosql "SELECT * FROM etcd.snapshot LIMIT 10" --describe

# See the metadata
octosql "SELECT * FROM etcd.snapshot?meta=true"

# See which namespaces are taking the most space
octosql "SELECT namespace, SUM(valueSize) AS S from etcd.snapshot GROUP BY namespace ORDER BY S DESC"
```