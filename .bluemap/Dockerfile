
FROM ghcr.io/bluemap-minecraft/bluemap:latest

# Set environment variables
ENV AZURE_STORAGE_ACCOUNT=
ENV AZURE_STORAGE_SHARE_MC_SERVER server
ENV AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT=map
ENV AZURE_LOGIN_TYPE managed-identity

# Copy config
COPY config /app/config
VOLUME /app/config

# Install curl
RUN apt-get update && apt-get install -y curl

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install azcopy from Azure CLI
RUN az extension add --name storage-preview

# Install azcopy
RUN curl -sL https://aka.ms/downloadazcopy-v10-linux | tar -zxf - --strip-components=1 -C /usr/local/bin

# Copy scripts
COPY execute.sh azmc_execute.sh

# Set script as executable
RUN chmod +x azmc_execute.sh

# Set entrypoint
ENTRYPOINT ["/bin/bash", "azmc_execute.sh"]
