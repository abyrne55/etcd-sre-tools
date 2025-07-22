# Generated-By: GPT-4.1

# Use Red Hat UBI 10 as base image
FROM registry.access.redhat.com/ubi10/ubi:latest

# Set labels for the image
LABEL maintainer="etcd-sre-tools"
LABEL description="Red Hat UBI 10 with octosql, llama.cpp, and quantized SmolLM2-1.7B for etcd analysis"

# Set environment variables
ENV LLAMA_MODEL_PATH="/usr/local/models/SmolLM2-1.7B-Instruct-Q4_K_M.gguf"
ENV LLAMA_SERVER_HOST="0.0.0.0"
ENV LLAMA_SERVER_PORT="8080"
ENV PATH="/usr/local/bin:$PATH"
ENV OCTOSQL_NO_TELEMETRY=1

# Update system packages and install required dependencies
RUN dnf update -y && \
    dnf install -y \
    curl \
    wget \
    tar \
    gzip \
    unzip \
    ca-certificates \
    jq \
    nodejs \
    npm \
    golang \
    git \
    python3 \
    python3-pip \
    && dnf clean all

# Install octosql
# Download and install the latest version of octosql
RUN OCTOSQL_VERSION=$(curl -s https://api.github.com/repos/cube2222/octosql/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    curl -L -o /tmp/octosql.tar.gz "https://github.com/cube2222/octosql/releases/download/${OCTOSQL_VERSION}/octosql_${OCTOSQL_VERSION#v}_linux_amd64.tar.gz" && \
    tar -xzf /tmp/octosql.tar.gz -C /tmp && \
    mv /tmp/octosql /usr/local/bin/ && \
    chmod +x /usr/local/bin/octosql && \
    rm -rf /tmp/octosql*

# Configure octosql file extension handlers for etcd snapshots
RUN mkdir -p /root/.octosql && \
    echo '{"snapshot": "etcdsnapshot"}' > /root/.octosql/file_extension_handlers.json

# Add the etcd snapshot plugin repository and install the plugin
RUN octosql plugin repository add https://raw.githubusercontent.com/tjungblu/octosql-plugin-etcdsnapshot/main/plugin_repository.json && \
    octosql plugin install etcdsnapshot/etcdsnapshot

# Install llama.cpp pre-compiled binary
RUN LLAMA_VERSION=$(curl -s https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    curl -L -o /tmp/llama.zip "https://github.com/ggml-org/llama.cpp/releases/download/${LLAMA_VERSION}/llama-${LLAMA_VERSION}-bin-ubuntu-x64.zip" && \
    unzip /tmp/llama.zip -d /tmp/llama && \
    cp /tmp/llama/build/bin/* /usr/local/bin/ && \
    chmod +x /usr/local/bin/llama-* && \
    chmod +x /usr/local/bin/lib*.so && \
    rm -rf /tmp/llama*

# Create models directory
RUN mkdir -p /usr/local/models

# Install Python dependencies for CLI interface and model download
RUN pip3 install --no-cache-dir \
    requests \
    asyncio \
    websockets \
    pydantic \
    typer \
    rich \
    httpx \
    huggingface-hub[cli]

# Download the quantized SmolLM2-1.7B-Instruct Q4_K_M model
RUN huggingface-cli download bartowski/SmolLM2-1.7B-Instruct-GGUF \
    --include "SmolLM2-1.7B-Instruct-Q4_K_M.gguf" \
    --local-dir /usr/local/models \
    --local-dir-use-symlinks False

# Copy our custom scripts
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Copy configuration files
COPY configs/ /etc/etcd-analysis/
RUN chmod 644 /etc/etcd-analysis/*

# Copy the MCP client implementation
COPY mcp-client/ /usr/local/src/mcp-client/
WORKDIR /usr/local/src/mcp-client
RUN go mod tidy && \
    go build -o /usr/local/bin/etcd-mcp-client .

# Set working directory back to root
WORKDIR /

# Verify octosql installation
RUN octosql --version

# Verify llama.cpp installation
RUN llama-cli --version

# Set the default command to our startup script
CMD ["/usr/local/bin/startup.sh"] 