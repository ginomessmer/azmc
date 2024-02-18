using Azure.ResourceManager.AppContainers;

namespace Azmc.DiscordBot.Resources;

public class AzmcRendererResource(ContainerAppJobResource containerAppJobResource)
{
    /// <summary>
    /// Starts the container app job and renders the map.
    /// </summary>
    /// <param name="waitUntilCompleted">Specifies whether the method should wait until completion.</param>
    /// <returns></returns>
    public Task UpdateAsync(bool waitUntilCompleted = false) => containerAppJobResource.StartAsync(waitUntilCompleted ? Azure.WaitUntil.Completed : Azure.WaitUntil.Started);
}