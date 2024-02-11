using Azure.ResourceManager.ContainerInstance;
using Discord;
using Discord.Interactions;
using Discord.Rest;

namespace Azmc.DiscordBot.Modules;

public class RconModule(ContainerGroupResource containerGroupResource) : RestInteractionModuleBase<RestInteractionContext>
{
    private readonly ContainerGroupResource _containerGroupResource = containerGroupResource;

    [SlashCommand("command", "Sends a command to the Minecraft server")]
    public async Task CommandAsync(string command)
    {
        await DeferAsync();
        var result = await _containerGroupResource.ExecuteContainerCommandAsync("server", new() {
            Command = $"mc rcon {command}"
        });

        await FollowupAsync(embed: new EmbedBuilder()
            .WithTitle("Command sent")
            .WithDescription($"Command `{command}` was sent to the server.")
            .WithColor(Color.Green)
            .Build());
    }
}
