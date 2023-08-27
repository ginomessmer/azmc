## Naming Conventions
### Azure Resources 

| Resource Type | Name | Example |
| --- | --- | --- |
| Resource Group | `<project>-<environment>-rg` | `minecraft-dev-rg` |
| Storage Account | `<project><environment>sa` | `minecraftdevsa` |
| Container Group | `<project>-<environment>-cg` | `minecraft-dev-cg` |

---

**⚠️⚠️ Work in Progress ⚠️⚠️**
# Azure Minecraft (Minecraft on Azure)
An experimental deployment template for hosting your own Minecraft server that ships with a management bot for Discord. Check the Terms of Use of your Azure Subscription before you deploy this project.

## Configuration
### Minecraft Server
todo

### Discord Bot
- `BotOptions:DiscordToken`: Discord bot token
- `BotOptions:TenantId`: Azure tenant ID of your subscription
- `BotOptions:SubscriptionId`: Azure subscription ID
- `BotOptions:ResourceGroupName`: Resource group that holds the container group
- `BotOptions:ContainerGroupName`: Container group name that hosts the game server
