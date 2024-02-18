using Azure.ResourceManager.ContainerInstance;

namespace Azmc.DiscordBot.Services;

public class AzmcServerService(ContainerGroupResource containerGroupResource)
{
    public ContainerGroupResource AzureResource => containerGroupResource;
}
