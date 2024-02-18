using Azmc.DiscordBot.Services;
using Discord;
using Discord.Interactions;
using Discord.Rest;

namespace Azmc.DiscordBot.Modules;

public class ServerModule(AzmcServerService server) : RestInteractionModuleBase<RestInteractionContext>
{
    [SlashCommand("status", "Gets the status of the Minecraft server")]
    public Task StatusAsync()
    {
        var state = server.AzureResource.Data.Containers.First().InstanceView.CurrentState;
        return RespondAsync(embed: new EmbedBuilder()
            .WithTitle("Server status")
            .WithFields(
            [
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
            ])
            .WithColor(Color.Blue)
            .Build());
    }

    [SlashCommand("start", "Starts the Minecraft server")]
    public async Task StartAsync()
    {
        await DeferAsync();
        await server.AzureResource.StartAsync(Azure.WaitUntil.Completed);
        await FollowupAsync(embed: new EmbedBuilder()
            .WithTitle("Server started")
            .WithFooter("It may take a few additional minutes until the server is fully initialized.")
            .WithColor(Color.Green)
            .Build());
    }

    [SlashCommand("stop", "Stops the Minecraft server")]
    public async Task StopAsync()
    {
        await server.AzureResource.StopAsync();
        await RespondAsync(embed: new EmbedBuilder()
            .WithTitle("Server stopped")
            .WithColor(Color.Red)
            .Build());
    }
}
