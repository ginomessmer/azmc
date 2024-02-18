using Azure.ResourceManager.ContainerInstance;

namespace Azmc.DiscordBot.Resources;

public class AzmcServerResource(ContainerGroupResource containerGroupResource)
{
    public ContainerGroupResource AzureResource => containerGroupResource;
}
