using Azure.ResourceManager.AppContainers;
using Discord.Interactions;
using Discord.Rest;

namespace Azmc.DiscordBot.Modules;

[Group("webmap", "Interact with the web map")]
public class WebMapModule([FromKeyedServices("renderer")] ContainerAppJobResource containerAppJobResource) : RestInteractionModuleBase<RestInteractionContext>
{
    private readonly ContainerAppJobResource _containerAppJobResource = containerAppJobResource;

    [SlashCommand("link", "Gets the link to the web map")]
    public Task LinkAsync()
    {
        return RespondAsync("The web map is available at https://azmc.io/map");
    }

    [SlashCommand("render", "Starts a render job for the web map")]
    public async Task RenderAsync()
    {
        await DeferAsync();
        await Task.Delay(5000);
        await FollowupAsync("The render job has been started.");
    }
}