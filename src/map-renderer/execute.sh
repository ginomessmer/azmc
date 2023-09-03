#!/bin/bash
set -e
export AZCOPY_BUFFER_GB=2

trap 'echo "Exiting"' SIGTERM

# Required environment variables:
# - AZURE_STORAGE_ACCOUNT:                                                                      The name of the Azure Storage Account where the Minecraft server files are stored.
# - AZURE_STORAGE_SHARE_MC_SERVER:                                                              The name of the Azure File Share where the Minecraft server files can be found.
# - AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT:                                                     The name of the Azure Blob Storage container where the BlueMap output should be uploaded to.
# - AZURE_LOGIN_TYPE:                                                                           The login type to use for Azure CLI. Available options: service-principal, interactive, managed-identity
# - AZURE_CLIENT_ID (only required if AZURE_LOGIN_TYPE is set to service-principal):            The client ID of the service principal to use for Azure CLI login.
# - AZURE_CLIENT_SECRET (only required if AZURE_LOGIN_TYPE is set to service-principal):        The client secret of the service principal to use for Azure CLI login.
# - AZURE_TENANT_ID (only required if AZURE_LOGIN_TYPE is set to service-principal):            The tenant ID of the service principal to use for Azure CLI login.
# - AZURE_SUBSCRIPTION_ID (only required if AZURE_LOGIN_TYPE is set to interactive):            The subscription ID to use for Azure CLI login.

# Check if required environment variables are set
if [ -z "$AZURE_STORAGE_ACCOUNT" ]; then
    echo "/!\ AZURE_STORAGE_ACCOUNT is not set. This is the name of the Azure Storage Account where the Minecraft server files are stored."
    exit 1
fi

if [ -z "$AZURE_STORAGE_SHARE_MC_SERVER" ]; then
    echo "/!\ AZURE_STORAGE_SHARE_MC_SERVER is not set. This is the name of the Azure File Share where the Minecraft server files can be found."
    exit 1
fi

if [ -z "$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT" ]; then
    echo "/!\ AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT is not set. This is the name of the Azure Blob Storage container where the BlueMap output should be uploaded to."
    exit 1
fi

if [ -z "$AZURE_LOGIN_TYPE" ]; then
    echo "/!\ AZURE_LOGIN_TYPE is not set. Available options: service-principal, interactive, managed-identity"
    exit 1
fi

# Log into Azure CLI
echo "=> Logging in to Azure CLI using $AZURE_LOGIN_TYPE"

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
    export APPSETTING_WEBSITE_SITE_NAME=DUMMY # Workaround as per https://github.com/Azure/azure-cli/issues/22677
    az login --identity
fi

echo "=> Logged in to Azure CLI"

# Get Azure Storage Account Key
AZURE_STORAGE_KEY=$(az storage account keys list --account-name $AZURE_STORAGE_ACCOUNT -g $AZURE_STORAGE_ACCOUNT_RG_NAME --query "[0].value" -o tsv)

# Determine date from now and add one hour for SAS token expiry
expiry=$(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ')
echo "=> SAS token expiry: $expiry"

# Generate SAS read-only token for the Azure File Share
echo "=> Generating SAS token for Azure File Share $AZURE_STORAGE_SHARE_MC_SERVER"
sas=$(az storage share generate-sas \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --account-key $AZURE_STORAGE_KEY \
    --name $AZURE_STORAGE_SHARE_MC_SERVER \
    --expiry $expiry \
    --permissions rl \
    --https-only \
    --output tsv)

echo "=> SAS token generated"

# Download directory from Azure File Share
echo "=> Downloading (1/2) :: server from Azure File Share $AZURE_STORAGE_SHARE_MC_SERVER"
mkdir -p /download/fs
azcopy copy "https://$AZURE_STORAGE_ACCOUNT.file.core.windows.net/$AZURE_STORAGE_SHARE_MC_SERVER?$sas" "/tmp" --recursive --check-md5=LogOnly
mv /tmp/server/world /app/world

echo "=> Server downloaded"

# Generate SAS read-only token for the Azure Blob Storage
echo "=> Generating SAS token for Azure Blob Storage $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT"
sas=$(az storage container generate-sas \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --account-key $AZURE_STORAGE_KEY \
    --name $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT \
    --expiry $expiry \
    --permissions rl \
    --https-only \
    --output tsv)

# Download map to accelerate rendering
echo "=> Downloading (2/2) :: previous map rendering from Azure Blob Storage $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT"
azcopy copy "https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT?$sas" "/app/web" --recursive --check-md5=LogOnly --as-subdir=false

# Run Bluemap
echo "=> Running Bluemap"
java -jar /app/cli.jar -r

echo "=> Bluemap finished rendering"

# Upload directory to Azure Blob Storage
echo "=> Uploading Bluemap web files to Azure Blob Storage $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT"

# Generate new SAS for Azure Blob Storage
echo "=> Generating SAS token for Azure Blob Storage $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT"
# Set new expiration to 12 hours
expiry=$(date -u -d "12 hours" '+%Y-%m-%dT%H:%MZ')
sas=$(az storage container generate-sas \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --account-key $AZURE_STORAGE_KEY \
    --name $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT \
    --expiry $expiry \
    --permissions rwdl \
    --https-only \
    --output tsv)

# Upload directory to Azure Blob Storage
echo "=> Uploading rendered map (1/2) :: all uncompressed Bluemap output to Azure Blob Storage $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT"
azcopy sync "/app/web/" "https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT?$sas" \
    --exclude-pattern=*.json.gz --recursive --mirror-mode

# Upload all json files to Azure Blob Storage
echo "=> Uploading rendered map (2/2) :: all compressed output files to Azure Blob Storage $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT"
azcopy copy "/app/web/" "https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT?$sas" \
    --include-pattern=*.json.gz --recursive \
    --content-encoding=gzip --content-type=application/json

echo "=> Bluemap output uploaded"

# Change content encoding of all json files to gzip and content type to application/json in blob container
echo "=> Changing content encoding of all json files to gzip in blob container $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT"

# Loop through all json files and change content encoding to gzip and content type to application/json
function change_content_encoding() {
    # Change file name ending from .json.gz to .json
    new_file_name=$(echo $1 | sed 's/\.json\.gz$/.json/')
    azcopy copy "https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT/$1?$sas" \
        "https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT/$new_file_name?$sas" --log-level=WARNING

    # Delete old file
    azcopy remove "https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT/$1?$sas" --log-level=WARNING

    echo "=> Changed content encoding of $1 to gzip and content type to application/json"
}

# Get list of all json files
json_files=$(az storage blob list \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --account-key $AZURE_STORAGE_KEY \
    --container-name $AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT \
    --query "[?ends_with(name, '.json.gz')].name" \
    --output tsv)

echo "=> Found $(echo "$json_files" | wc -l) JSON files marked as compressed"

# Loop through all json files and change content encoding to gzip and content type to application/json
for file in $json_files; do
    change_content_encoding $file &
done
wait

echo "=> Content encoding changed"

echo "\o/ Done!"
echo "=> Web map can be accessed at https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_STORAGE_CONTAINER_BLUEMAP_OUTPUT/web/index.html"
