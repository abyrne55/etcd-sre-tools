# Natural Language etcd Analysis Container

A container image that provides a CLI powered by a quantized SmolLM2-1.7B-Instruct model for analyzing etcd snapshots with natural language commands. The container runs completely offline after initial setup.

## Features

- 🧠 **SmolLM2-1.7B-Instruct Q4_K_M**: Quantized 4-bit model optimized for CPU inference (~1GB)
- 🔍 **Natural Language Queries**: Ask questions about your etcd snapshots in plain English
- 📊 **etcd Analysis**: Built-in support for analyzing Kubernetes cluster state from etcd snapshots
- 🚫 **Offline Operation**: Works without internet access after model download
- ⚡ **Fast & Lightweight**: Q4_K_M quantization provides optimal CPU performance
- 🎯 **Easy to Use**: Simple CLI interface with rich output formatting

## Quick Start

### Build the Container

```bash
docker build -t etcd-sre-tools .
```

### Run with Interactive Mode

```bash
# Mount your etcd snapshot directory
docker run -it --rm -v /path/to/snapshots:/snapshots etcd-sre-tools
```

The container will:
1. Start llama.cpp server with the quantized model
2. Auto-detect your etcd snapshot in `/snapshots/`
3. Launch the natural language CLI in interactive mode

**Note**: First run requires internet access for model download (~1GB). Subsequent runs work offline.

### Example Queries

Once the container starts, you can ask natural language questions:

```
🤔 Your question: Show me all pods in the default namespace
🤔 Your question: What are the 10 largest objects in the cluster?
🤔 Your question: Count all resources by type
🤔 Your question: List all ConfigMaps
🤔 Your question: Show cluster health metrics
🤔 Your question: Find services named api
```

## Architecture

### Components

1. **SmolLM2-1.7B-Instruct Q4_K_M**: Quantized language model via llama.cpp
2. **octosql**: SQL query engine with etcd snapshot plugin
3. **Natural Language CLI**: Python-based interface that translates natural language to SQL
4. **MCP Client**: Go-based client for query execution

### Data Flow

```
Natural Language Query → LLM Analysis → SQL Generation → octosql → Results → LLM Analysis → Formatted Output
```

## Performance Characteristics

### Model Specifications
- **Model**: SmolLM2-1.7B-Instruct
- **Quantization**: Q4_K_M (4-bit, optimal quality/size balance)
- **File Size**: ~1GB (vs ~3.4GB unquantized)
- **Context Length**: 8192 tokens
- **Inference Engine**: llama.cpp (CPU optimized)

### Performance Benefits
- **85% smaller download** compared to unquantized models
- **Excellent CPU performance** with Q4_K_M quantization
- **Fast startup time** - no GPU required
- **Low memory usage** - runs efficiently on 4GB+ systems
- **Deterministic behavior** - same results every time

## Usage Examples

### Interactive Mode (Recommended)

```bash
docker run -it --rm -v ./samples:/snapshots etcd-sre-tools
```

### Single Query Mode

```bash
docker run --rm -v ./samples:/snapshots etcd-sre-tools \
    /usr/local/bin/nl-etcd-cli query \
    "Show me all pods in the kube-system namespace" \
    --snapshot /snapshots/etcd.snapshot
```

### Direct SQL Mode

```bash
docker run --rm -v ./samples:/snapshots etcd-sre-tools \
    /usr/local/bin/etcd-mcp-client query \
    "SELECT namespace, name FROM /snapshots/etcd.snapshot WHERE resourceType='pods'" \
    /snapshots/etcd.snapshot
```

### Model Information

```bash
docker run --rm etcd-sre-tools /usr/local/bin/nl-etcd-cli models
```

## Configuration

### Environment Variables

- `LLAMA_MODEL_PATH`: Path to the GGUF model file
- `LLAMA_SERVER_HOST`: llama.cpp server host (default: 0.0.0.0)
- `LLAMA_SERVER_PORT`: llama.cpp server port (default: 8080)

### Configuration Files

- `/etc/etcd-analysis/etcd-analysis.yaml`: Main configuration
- `/etc/etcd-analysis/prompts.yaml`: LLM prompts and examples

## Advanced Usage

### Custom Model Parameters

The Q4_K_M quantization provides the best balance of quality and performance for most use cases. The model configuration includes:

- **Temperature**: 0.3 (focused responses)
- **Context**: 8192 tokens (long document support)
- **Stop tokens**: Properly formatted for chat template
- **Timeout**: 120 seconds (generous for CPU inference)

### Offline Setup

```bash
docker run --rm etcd-sre-tools /usr/local/bin/setup-offline.sh
```

## Common Queries

### Resource Analysis
- "Show me all pods"
- "List services in namespace default"
- "Count resources by namespace"
- "Find largest objects by size"

### Cluster Health
- "Show cluster metadata"
- "What's the cluster version?"
- "Show etcd health metrics"

### Troubleshooting
- "Find pods that are not running"
- "Show failed jobs"
- "List orphaned resources"

## Files Structure

```
/usr/local/bin/
├── nl-etcd-cli          # Main natural language CLI
├── etcd-mcp-client      # MCP client for query execution
├── llama-server         # llama.cpp server binary
├── llama-cli            # llama.cpp CLI binary
├── startup.sh           # Container startup script
└── setup-offline.sh     # Offline configuration script

/usr/local/models/
└── SmolLM2-1.7B-Instruct-Q4_K_M.gguf  # Quantized model file

/etc/etcd-analysis/
├── etcd-analysis.yaml   # Main configuration
└── prompts.yaml         # LLM prompts and examples
```

## Sample Data

The repository includes sample etcd snapshots in the `samples/` directory:

- `etcd.snapshot`: Small sample snapshot
- `abyrneetcd.snapshot`: Larger sample snapshot
- `example-queries.sql`: Example SQL queries
- `README.md`: Sample documentation

## Troubleshooting

### Performance Tuning

**For CPU-only systems:**
- Q4_K_M quantization is optimized for CPU inference
- Model loads quickly and provides good quality responses
- Memory usage is reasonable (~2-4GB total)

**For systems with limited memory:**
- Consider Q3_K_M for even smaller memory footprint
- Reduce context length if needed
- Monitor memory usage during operation

### Common Issues

1. **Model Download Fails**: Ensure internet access on first run
2. **Permission Denied**: Use `:Z` flag for SELinux systems: `-v /path:/snapshots:Z`
3. **Out of Memory**: Monitor container memory; 4GB+ recommended
4. **Slow Responses**: Normal for CPU inference; responses typically take 10-60 seconds
5. **Server Not Starting**: Check model file exists and permissions are correct

### Debugging

```bash
# Test octosql directly
docker run --rm -v ./samples:/snapshots etcd-sre-tools \
    octosql "SELECT COUNT(*) FROM /snapshots/etcd.snapshot"

# Test MCP client
docker run --rm etcd-sre-tools /usr/local/bin/etcd-mcp-client tools

# Check model information
docker run --rm etcd-sre-tools /usr/local/bin/nl-etcd-cli models
```

## Why Q4_K_M Quantization?

Based on extensive research and benchmarking:

1. **Optimal Quality/Size Trade-off**: Q4_K_M provides excellent quality while keeping size manageable
2. **CPU Performance**: Specifically optimized for CPU inference
3. **Proven Reliability**: Widely used in the community with consistent results
4. **Memory Efficiency**: Lower memory requirements than higher precision models
5. **Fast Loading**: Quick model initialization compared to larger quantizations

## Future Improvements

We're monitoring for:
- **SmolLM3-3B-GGUF**: When quantized versions become available
- **Better quantization methods**: IQ4_XS and newer techniques
- **Performance optimizations**: Further CPU inference improvements

## Offline Operation

After the initial setup and model download, the container runs completely offline:

1. Model is cached locally in GGUF format
2. No external API calls required
3. All components run within the container
4. Deterministic and reproducible results

## License

This project uses various open-source components:
- SmolLM2: Apache 2.0 License
- llama.cpp: MIT License  
- octosql: Apache 2.0 License
- Python libraries: Various (see requirements)

## Contributing

Feel free to submit issues and enhancement requests!

## Support

For issues related to:
- etcd analysis: Check octosql documentation
- LLM responses: Verify prompts in `/etc/etcd-analysis/prompts.yaml`
- Container issues: Check logs and container startup
- Performance: Monitor CPU/memory usage and consider quantization options
