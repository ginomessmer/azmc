using Azmc.DiscordBot.Resources;
using Discord;
using Discord.Interactions;
using Discord.Rest;

namespace Azmc.DiscordBot.Modules;

public class ServerModule : RestInteractionModuleBase<RestInteractionContext>
{
    private readonly AzmcServerResource _server;

    public ServerModule(AzmcServerResource containerGroupResource)
    {
        _server = containerGroupResource;
    }

    [SlashCommand("status", "Gets the status of the Minecraft server")]
    public Task StatusAsync()
    {
        var state = _server.Data.Containers.First().InstanceView.CurrentState;
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
        await _server.StartAsync(Azure.WaitUntil.Completed);
        await FollowupAsync(embed: new EmbedBuilder()
            .WithTitle("Server started")
            .WithFooter("It may take a few additional minutes until the server is fully initialized.")
            .WithColor(Color.Green)
            .Build());
    }

    [SlashCommand("stop", "Stops the Minecraft server")]
    public async Task StopAsync()
    {
        await _server.StopAsync();
        await RespondAsync(embed: new EmbedBuilder()
            .WithTitle("Server stopped")
            .WithColor(Color.Red)
            .Build());
    }
}
