using Azure.ResourceManager.AppContainers;
using Discord;
using Discord.Interactions;
using Discord.Rest;

namespace Azmc.DiscordBot.Modules;

[Group("webmap", "Interact with the web map")]
public class WebMapModule([FromKeyedServices("renderer")] ContainerAppJobResource containerAppJobResource)
    : RestInteractionModuleBase<RestInteractionContext>
{
    private readonly ContainerAppJobResource _containerAppJobResource = containerAppJobResource;

    [SlashCommand("render", "Starts a render job for the web map")]
    public async Task RenderAsync()
    {
        await DeferAsync();
        await _containerAppJobResource.StartAsync(Azure.WaitUntil.Started);
        await FollowupAsync("The render job has been started.");
    }

    [SlashCommand("status", "Gets the status of the render job for the web map")]
    public async Task StatusAsync()
    {
        await DeferAsync();
        var lastExecution = await _containerAppJobResource.GetContainerAppJobExecutions().LastOrDefaultAsync();

        if (lastExecution == null)
        {
            await FollowupAsync("No render jobs have been started. Use `/webmap render` to start one.");
            return;
        }

        await FollowupAsync(embed: new EmbedBuilder()
            .WithTitle("Web Map Render Job Status")
            .AddField("Status", lastExecution.Data.Status)
            .AddField("Started on", lastExecution.Data.StartOn, true)
            .AddField("Ended on", lastExecution.Data.EndOn, true)
            .AddField("Duration", lastExecution.Data.EndOn - lastExecution.Data.StartOn, true)
            .Build());
    }
}