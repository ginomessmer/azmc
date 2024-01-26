using Azure.Core;
using Azure.ResourceManager;
using Azure.ResourceManager.ContainerInstance;
using Discord.Interactions;
using Discord.Rest;

namespace Azmc.DiscordBot.Modules;

public class ServerModule : RestInteractionModuleBase<RestInteractionContext>
{
    private readonly ContainerGroupResource _containerGroupResource;

    public ServerModule(ContainerGroupResource containerGroupResource)
    {
        _containerGroupResource = containerGroupResource;
    }

    [SlashCommand("status", "Gets the status of the Minecraft server")]
    public Task PingAsync()
    {
        var state = _containerGroupResource.Data.Containers.First().InstanceView.CurrentState.State;
        return RespondAsync(state);
    }

    [SlashCommand("start", "Starts the Minecraft server")]
    public async Task StartAsync()
    {
        await DeferAsync();
        await _containerGroupResource.StartAsync(Azure.WaitUntil.Completed);
        await FollowupAsync("Server started");
    }

    [SlashCommand("stop", "Stops the Minecraft server")]
    public async Task StopAsync()
    {
        await _containerGroupResource.StopAsync();
        await RespondAsync("Server stopped");
    }
}
