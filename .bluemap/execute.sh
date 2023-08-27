set -e

# Required environment variables:
# - AZURE_STORAGE_ACCOUNT
# - AZURE_STORAGE_SHARE_MC_SERVER
# - AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT
# - AZURE_LOGIN_TYPE
# - AZURE_CLIENT_ID (only required if AZURE_LOGIN_TYPE is set to service-principal)
# - AZURE_CLIENT_SECRET (only required if AZURE_LOGIN_TYPE is set to service-principal)
# - AZURE_TENANT_ID (only required if AZURE_LOGIN_TYPE is set to service-principal)
# - AZURE_SUBSCRIPTION_ID (only required if AZURE_LOGIN_TYPE is set to interactive)

# Check if required environment variables are set
if [ -z "$AZURE_STORAGE_ACCOUNT" ]; then
    echo "AZURE_STORAGE_ACCOUNT is not set. This is the name of the Azure Storage Account where the Minecraft server files are stored."
    exit 1
fi

if [ -z "$AZURE_STORAGE_SHARE_MC_SERVER" ]; then
    echo "AZURE_STORAGE_SHARE_MC_SERVER is not set. This is the name of the Azure File Share where the Minecraft server files can be found."
    exit 1
fi

if [ -z "$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT" ]; then
    echo "AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT is not set. This is the name of the Azure Blob Storage container where the BlueMap output should be uploaded to."
    exit 1
fi

if [ -z "$AZURE_LOGIN_TYPE" ]; then
    echo "AZURE_LOGIN_TYPE is not set. Available options: service-principal, interactive, managed-identity"
    exit 1
fi

# Log into Azure CLI
echo "Logging in to Azure CLI using $AZURE_LOGIN_TYPE"

# Service principal login
if [ "$AZURE_LOGIN_TYPE" = "service-principal" ]; then
    az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
fi

# Interactive login
if [ "$AZURE_LOGIN_TYPE" = "interactive" ]; then
    az login
    az account set --subscription $AZURE_SUBSCRIPTION_ID
fi

# Managed identity login
if [ "$AZURE_LOGIN_TYPE" = "managed-identity" ]; then
    az login --identity
fi

echo "Logged in to Azure CLI"

# Get Azure Storage Account Key
AZURE_STORAGE_KEY=$(az storage account keys list --account-name $AZURE_STORAGE_ACCOUNT --query "[0].value" -o tsv)

# Determine date from now and add one hour for SAS token expiry
expiry=$(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ')
echo "SAS token expiry: $expiry"

# Generate SAS read-only token for the Azure File Share
echo "Generating SAS token for Azure File Share $AZURE_STORAGE_SHARE_MC_SERVER"
sas=$(az storage share generate-sas \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --account-key $AZURE_STORAGE_KEY \
    --name $AZURE_STORAGE_SHARE_MC_SERVER \
    --expiry $expiry \
    --permissions rl \
    --https-only \
    --output tsv)

echo "SAS token generated: $sas"

# Download directory from Azure File Share
echo "Downloading directory from Azure File Share $AZURE_STORAGE_SHARE_MC_SERVER"
mkdir -p /download/fs
azcopy copy "https://$AZURE_STORAGE_ACCOUNT.file.core.windows.net/$AZURE_STORAGE_SHARE_MC_SERVER?$sas" "/download/fs" --recursive
mv /download/fs/server/world /app/world

echo "Directory downloaded"

# Run Bluemap
echo "Running Bluemap"
java -jar /app/cli.jar -r

echo "Bluemap finished rendering"

# Upload directory to Azure Blob Storage
echo "Uploading Bluemap web files to Azure Blob Storage $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT"

# Generate new SAS for Azure Blob Storage
echo "Generating SAS token for Azure Blob Storage $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT"
sas=$(az storage container generate-sas \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --account-key $AZURE_STORAGE_KEY \
    --name $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT \
    --expiry $expiry \
    --permissions rwdl \
    --https-only \
    --output tsv)

# Upload directory to Azure Blob Storage
echo "Uploading Bluemap output to Azure Blob Storage $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT"
azcopy copy "/app/web/web" "https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT?$sas" --recursive

echo "Bluemap output uploaded"

# Change content encoding of all json files to gzip
echo "Changing content encoding of all json files to gzip"
for file in /output/*.json; do
    gzip -c "$file" > "$file.gz"
    rm "$file"
done

az storage blob update-batch --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY --source "/output" --pattern "*.json" --content-encoding "gzip" --content-type "application/json"

echo "Content encoding changed"

echo "Done"
echo "Web map can be accessed at https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT/index.html"
