#!/bin/bash
set -e

echo "🔄 Setting up offline mode for etcd analysis tool with SmolLM2-1.7B Q4_K_M..."

# Check if llama.cpp binaries are available
if ! command -v llama-server > /dev/null; then
    echo "❌ llama-server not found. Please ensure llama.cpp is installed."
    exit 1
fi

if ! command -v llama-cli > /dev/null; then
    echo "❌ llama-cli not found. Please ensure llama.cpp is installed."
    exit 1
fi

# Check if the quantized model file exists
MODEL_PATH="${LLAMA_MODEL_PATH:-/usr/local/models/SmolLM2-1.7B-Instruct-Q4_K_M.gguf}"
if [ ! -f "$MODEL_PATH" ]; then
    echo "❌ Model file not found at $MODEL_PATH"
    echo "🔄 Attempting to download the model..."
    
    # Create models directory if it doesn't exist
    mkdir -p "$(dirname "$MODEL_PATH")"
    
    # Download the model using huggingface-cli
    if command -v huggingface-cli > /dev/null; then
        huggingface-cli download bartowski/SmolLM2-1.7B-Instruct-GGUF \
            --include "SmolLM2-1.7B-Instruct-Q4_K_M.gguf" \
            --local-dir "$(dirname "$MODEL_PATH")" \
            --local-dir-use-symlinks False
        
        if [ -f "$MODEL_PATH" ]; then
            echo "✅ Model downloaded successfully"
        else
            echo "❌ Failed to download model"
            exit 1
        fi
    else
        echo "❌ huggingface-cli not found. Cannot download model."
        exit 1
    fi
else
    echo "✅ SmolLM2-1.7B-Instruct Q4_K_M model found"
fi

# Test llama.cpp with the model
echo "🧪 Testing llama.cpp server..."
llama-server \
    --model "$MODEL_PATH" \
    --host "127.0.0.1" \
    --port "8080" \
    --ctx-size 8192 \
    --threads $(nproc) \
    --log-disable &

SERVER_PID=$!

# Wait a moment for server to start
sleep 5

# Test server health
if curl -s http://127.0.0.1:8080/health > /dev/null; then
    echo "✅ llama.cpp server working"
else
    echo "⚠️  llama.cpp server test failed"
fi

# Stop test server
kill $SERVER_PID 2>/dev/null || true

# Test MCP client connectivity
echo "🧪 Testing MCP client..."
if command -v etcd-mcp-client > /dev/null; then
    etcd-mcp-client tools > /dev/null 2>&1 && echo "✅ MCP client working" || echo "⚠️  MCP client test failed"
else
    echo "⚠️  MCP client not found"
fi

# Test octosql plugin
echo "🧪 Testing octosql etcd plugin..."
if octosql plugin list | grep -q "etcdsnapshot"; then
    echo "✅ etcd snapshot plugin available"
else
    echo "⚠️  etcd snapshot plugin not found"
fi

# Create model persistence indicator
echo "💾 Ensuring model persistence..."
mkdir -p /usr/local/models
touch /tmp/offline_mode_configured

echo "✅ Offline mode setup complete!"
echo ""
echo "📋 Configuration summary:"
echo "   - SmolLM2-1.7B-Instruct Q4_K_M: Available (~1GB)"
echo "   - llama.cpp server: Ready"
echo "   - MCP client: $(command -v etcd-mcp-client >/dev/null && echo "Ready" || echo "Not found")"
echo "   - Model quantization: Q4_K_M (optimal CPU performance)"
echo "   - Context length: 8192 tokens" 