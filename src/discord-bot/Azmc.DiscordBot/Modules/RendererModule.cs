using Azmc.DiscordBot.Resources;
using Discord;
using Discord.Interactions;
using Discord.Rest;

namespace Azmc.DiscordBot.Modules;

[Group("map", "Manage the web map")]
public class RendererModule(AzmcRendererResource renderer) : RestInteractionModuleBase<RestInteractionContext>
{
    [SlashCommand("update", "Updates the web map")]
    public async Task UpdateAsync()
    {
        await DeferAsync();
        await renderer.UpdateAsync();
        await FollowupAsync(embed: new EmbedBuilder()
            .WithTitle("Map update started")
            .WithColor(Color.Blue)
            .Build());
    }
}
