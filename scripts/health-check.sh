#!/bin/bash
# Health check script for etcd analysis container with llama.cpp

set -e

echo "🏥 Running health checks..."

# Check if llama.cpp binaries are available
if command -v llama-server > /dev/null; then
    echo "✅ llama-server is installed"
else
    echo "❌ llama-server not found"
    exit 1
fi

if command -v llama-cli > /dev/null; then
    echo "✅ llama-cli is installed"
else
    echo "❌ llama-cli not found"
    exit 1
fi

# Check if the model file exists
MODEL_PATH="${LLAMA_MODEL_PATH:-/usr/local/models/SmolLM2-1.7B-Instruct-Q4_K_M.gguf}"
if [ -f "$MODEL_PATH" ]; then
    echo "✅ SmolLM2-1.7B-Instruct Q4_K_M model is available"
    echo "📊 Model size: $(du -h "$MODEL_PATH" | cut -f1)"
else
    echo "❌ SmolLM2-1.7B-Instruct Q4_K_M model not found at $MODEL_PATH"
    exit 1
fi

# Check if llama.cpp server is running and accessible
LLAMA_HOST="${LLAMA_SERVER_HOST:-localhost}"
LLAMA_PORT="${LLAMA_SERVER_PORT:-8080}"

if curl -s http://$LLAMA_HOST:$LLAMA_PORT/health > /dev/null; then
    echo "✅ llama.cpp server is accessible"
else
    echo "❌ llama.cpp server not accessible at http://$LLAMA_HOST:$LLAMA_PORT"
    echo "ℹ️  This is normal if the server hasn't been started yet"
fi

# Check if octosql is installed
if command -v octosql > /dev/null; then
    echo "✅ octosql is installed"
else
    echo "❌ octosql not found"
    exit 1
fi

# Check if etcd plugin is available
if octosql plugin list | grep -q "etcdsnapshot"; then
    echo "✅ etcd snapshot plugin is available"
else
    echo "❌ etcd snapshot plugin not found"
    exit 1
fi

# Check if MCP client is available
if command -v etcd-mcp-client > /dev/null; then
    echo "✅ MCP client is available"
else
    echo "❌ MCP client not found"
    exit 1
fi

# Check if natural language CLI is available
if command -v nl-etcd-cli > /dev/null; then
    echo "✅ Natural language CLI is available"
else
    echo "❌ Natural language CLI not found"
    exit 1
fi

# Check Python dependencies
python3 -c "import typer, rich, httpx" 2>/dev/null && echo "✅ Python dependencies are available" || {
    echo "❌ Python dependencies missing"
    exit 1
}

# Test basic LLM functionality if server is running
echo "🧪 Testing LLM functionality..."
if curl -s http://$LLAMA_HOST:$LLAMA_PORT/health > /dev/null; then
    TEST_RESPONSE=$(python3 -c "
import asyncio
import httpx
import json

async def test_llm():
    try:
        payload = {
            'prompt': '<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n<|im_start|>user\nRespond with just: OK<|im_end|>\n<|im_start|>assistant\n',
            'max_tokens': 10,
            'temperature': 0.3,
            'stop': ['<|im_end|>'],
            'stream': False
        }
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post('http://$LLAMA_HOST:$LLAMA_PORT/completion', json=payload)
            result = response.json()
            return result.get('content', '').strip()
    except:
        return 'ERROR'

print(asyncio.run(test_llm()))
" 2>/dev/null || echo "ERROR")

    if [[ "$TEST_RESPONSE" == "ERROR" ]]; then
        echo "❌ LLM test failed"
        exit 1
    else
        echo "✅ LLM is responding: '$TEST_RESPONSE'"
    fi
else
    echo "ℹ️  Skipping LLM test - server not running"
fi

echo ""
echo "🎉 All health checks passed!"
echo "📋 Configuration summary:"
echo "   - Model: SmolLM2-1.7B-Instruct Q4_K_M"
echo "   - Quantization: 4-bit for optimal CPU performance"
echo "   - Model size: ~1GB"
echo "   - Context length: 8192 tokens"
echo "   - Server: llama.cpp"
echo ""
echo "Container is ready for etcd snapshot analysis."

exit 0 