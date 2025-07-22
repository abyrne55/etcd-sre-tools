#!/bin/bash
set -e

echo "🚀 Starting etcd analysis environment with SmolLM2-1.7B-Instruct Q4_K_M..."

# Start llama.cpp server in background
echo "🔄 Starting llama.cpp server..."
llama-server \
    --model "$LLAMA_MODEL_PATH" \
    --host "$LLAMA_SERVER_HOST" \
    --port "$LLAMA_SERVER_PORT" \
    --ctx-size 8192 \
    --threads $(nproc) \
    --log-disable &

LLAMA_PID=$!

# Wait for llama.cpp server to be ready
echo "⏳ Waiting for llama.cpp server to be ready..."
while ! curl -s http://$LLAMA_SERVER_HOST:$LLAMA_SERVER_PORT/health > /dev/null; do
    sleep 1
done
echo "✅ llama.cpp server is ready!"

# Start the natural language CLI
# Default to interactive mode if no command specified
if [ $# -eq 0 ]; then
    # Look for a snapshot file automatically
    SNAPSHOT_FILE=""
    for path in "/snapshots/etcd.snapshot" "/snapshots/abyrneetcd.snapshot" "etcd.snapshot" "/data/etcd.snapshot"; do
        if [ -f "$path" ]; then
            SNAPSHOT_FILE="$path"
            break
        fi
    done
    
    if [ -n "$SNAPSHOT_FILE" ]; then
        echo "📁 Found snapshot: $SNAPSHOT_FILE"
        exec /usr/local/bin/nl-etcd-cli interactive --snapshot "$SNAPSHOT_FILE"
    else
        echo "❌ No etcd snapshot found. Please mount your snapshot directory to /snapshots"
        echo "   Example: docker run -it --rm -v /path/to/snapshots:/snapshots etcd-sre-tools"
        echo ""
        echo "   Or specify a snapshot manually:"
        echo "   docker run -it --rm -v /path/to/snapshots:/snapshots etcd-sre-tools interactive --snapshot /snapshots/your-snapshot.db"
        exit 1
    fi
else
    exec /usr/local/bin/nl-etcd-cli "$@"
fi 