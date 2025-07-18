# Generated-By: GPT-4.1

# Use Red Hat UBI 10 as base image
FROM registry.access.redhat.com/ubi10/ubi:latest

# Set labels for the image
LABEL maintainer="etcd-sre-tools"
LABEL description="Red Hat UBI 10 with octosql installed"

# Update system packages and install required dependencies
RUN dnf update -y && \
    dnf install -y \
    curl \
    wget \
    tar \
    gzip \
    ca-certificates \
    && dnf clean all

# Install octosql
# Download and install the latest version of octosql
RUN OCTOSQL_VERSION=$(curl -s https://api.github.com/repos/cube2222/octosql/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    curl -L -o /tmp/octosql.tar.gz "https://github.com/cube2222/octosql/releases/download/${OCTOSQL_VERSION}/octosql_${OCTOSQL_VERSION#v}_linux_amd64.tar.gz" && \
    tar -xzf /tmp/octosql.tar.gz -C /tmp && \
    mv /tmp/octosql /usr/local/bin/ && \
    chmod +x /usr/local/bin/octosql && \
    rm -rf /tmp/octosql*

# Install octosql-plugin-etcdsnapshot
# Download and install the etcd snapshot plugin
RUN mkdir -p /usr/local/lib/octosql/plugins && \
    PLUGIN_VERSION=$(curl -s https://api.github.com/repos/tjungblu/octosql-plugin-etcdsnapshot/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    curl -L -o /tmp/octosql-plugin-etcdsnapshot.tar.gz "https://github.com/tjungblu/octosql-plugin-etcdsnapshot/releases/download/${PLUGIN_VERSION}/octosql-plugin-etcdsnapshot_${PLUGIN_VERSION#v}_linux_amd64.tar.gz" && \
    tar -xzf /tmp/octosql-plugin-etcdsnapshot.tar.gz -C /tmp && \
    mv /tmp/octosql-plugin-etcdsnapshot /usr/local/lib/octosql/plugins/ && \
    chmod +x /usr/local/lib/octosql/plugins/octosql-plugin-etcdsnapshot && \
    rm -rf /tmp/octosql-plugin-etcdsnapshot*

# Verify installation
RUN octosql --version

# Configure octosql file extension handlers for etcd snapshots
RUN mkdir -p /root/.octosql && \
    echo '{"snapshot": "etcdsnapshot"}' > /root/.octosql/file_extension_handlers.json

# Set the default command to shell
CMD ["/bin/bash"] 