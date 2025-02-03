# Azure Minecraft (Minecraft on Azure)

> This is a work in progress project for personal Minecraft servers.

## Introduction

Azure Minecraft is a project that aims to provide a deployment template for hosting your own Minecraft server on Azure. It also includes a management bot for Discord, allowing you to easily manage and interact with your Minecraft server.

### Key-Features

- Supports Minecraft Java Edition and Minecraft Bedrock Edition
- Ships with a Discord bot and web map
- Scalable through Container Instances
- Cost effective (only pay for it while its running)
- Secure by default (Managed Identities over secrets)
- Operational logs and back-ups enabled
- Highly flexible & easy deployment

## Disclaimer

Please note that this project is currently a work in progress and may not be suitable for production environments.

It is recommended to review the Terms of Use of your Azure Subscription before deploying this project.

## Getting Started

### Pre-Requisites

- Azure CLI
- An Azure Subscription
- A Discord app registration
- A Docker Hub account

### Deploy to Microsoft Azure

#### Deploy with Azure CLI

1. Log into the Azure CLI (`az login`) and select your preferred subscription
2. Create a new resource group (`az group create -n <<NAME, e.g. rg-azmc>> -l <<LOCATION, e.g. westeurope>>`)
3. Deploy the Bicep template with the required parameters:
    ```sh
    az deployment group create \
      --resource-group <<RESOURCE_GROUP_NAME>> \
      --template-file infra/main.bicep \
      --parameters acceptEula=true \
      --parameters serverMemorySize=3 \
      --parameters serverType='PAPER' \
      --parameters isBedrockSupportEnabled=false \
      --parameters deployDashboard=true \
      --parameters deployRenderer=false \
      --parameters rendererSchedule='weekly' \
      --parameters mapHostName='' \
      --parameters deployDiscordBot=false \
      --parameters discordBotPublicKey='' \
      --parameters discordBotToken='' \
      --parameters deployResources=false \
      --parameters resourcePackName='' \
      --parameters deployAutoShutdown=true \
      --parameters dockerHubUsername='' \
      --parameters dockerHubPassword=''
    ```
4. Start the Minecraft server container instance

## High Level Architecture

![High Level Architecture](docs/High%20Level%20Architecture.drawio.png)

## Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request on the project's GitHub repository.

## License

This project is licensed under the [Apache License](LICENSE.md).
