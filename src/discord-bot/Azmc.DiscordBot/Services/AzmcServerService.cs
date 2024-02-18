using Azure.ResourceManager.ContainerInstance;

namespace Azmc.DiscordBot.Resources;

public class AzmcServerService(ContainerGroupResource containerGroupResource)
{
    public ContainerGroupResource AzureResource => containerGroupResource;
}
