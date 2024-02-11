using Azure.Core;
using Azure.ResourceManager;
using Azure.ResourceManager.ContainerInstance;
using Discord;
using Discord.Interactions;
using Discord.Rest;

namespace Azmc.DiscordBot.Modules;

public class ServerModule(ContainerGroupResource containerGroupResource) : RestInteractionModuleBase<RestInteractionContext>
{
    private readonly ContainerGroupResource _containerGroupResource = containerGroupResource;

    [SlashCommand("status", "Gets the status of the Minecraft server")]
    public Task StatusAsync()
    {
        var state = _containerGroupResource.Data.Containers.First().InstanceView.CurrentState;
        return RespondAsync(embed: new EmbedBuilder()
            .WithTitle("Server status")
            .WithFields(new EmbedFieldBuilder[]
            {
                new()
                {
                    Name = "State",
                    Value = state.State,
                    IsInline = true
                },
                new()
                {
                    Name = "Exit code",
                    Value = state.ExitCode?.ToString() ?? "N/A",
                    IsInline = true
                }
            })
            .WithColor(Color.Blue)
            .Build());
    }

    [SlashCommand("start", "Starts the Minecraft server")]
    public async Task StartAsync()
    {
        await DeferAsync();
        await _containerGroupResource.StartAsync(Azure.WaitUntil.Completed);
        await FollowupAsync(embed: new EmbedBuilder()
            .WithTitle("Server started")
            .WithFooter("It may take a few additional minutes until the server is fully initialized.")
            .WithColor(Color.Green)
            .Build());
    }

    [SlashCommand("stop", "Stops the Minecraft server")]
    public async Task StopAsync()
    {
        await _containerGroupResource.StopAsync();
        await RespondAsync(embed: new EmbedBuilder()
            .WithTitle("Server stopped")
            .WithColor(Color.Red)
            .Build());
    }
}
