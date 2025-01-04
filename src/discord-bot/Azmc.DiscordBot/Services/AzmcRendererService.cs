using Azure.ResourceManager.AppContainers;
using Azure.ResourceManager.AppContainers.Models;

namespace Azmc.DiscordBot.Services;

public class AzmcRendererService(ContainerAppJobResource containerAppJobResource)
{
    /// <summary>
    /// Starts the container app job and renders the map.
    /// </summary>
    /// <param name="waitUntilCompleted">Specifies whether the method should wait until completion.</param>
    /// <returns></returns>
    public Task UpdateAsync(bool waitUntilCompleted = false) => containerAppJobResource.StartAsync(waitUntilCompleted ? Azure.WaitUntil.Completed : Azure.WaitUntil.Started);

    /// <summary>
    /// Gets the status of the active job.
    /// </summary>
    /// <returns>Whether a job is running at the moment.</returns>
    public async Task<bool> GetActiveJobStatus()
    {
        var latestExecution = await containerAppJobResource.GetContainerAppJobExecutions().FirstAsync();
        var latestExecutionItem = await containerAppJobResource.GetContainerAppJobExecutionAsync(latestExecution.Data.Name);
        return latestExecutionItem.Value.Data.Status == JobExecutionRunningState.Running;
    }
}