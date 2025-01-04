using Azmc.DiscordBot.Services;
using Discord;
using Discord.Interactions;
using Discord.Rest;

namespace Azmc.DiscordBot.Modules;

[Group("map", "Manage the web map")]
public class RendererModule(AzmcRendererService renderer) : RestInteractionModuleBase<RestInteractionContext>
{
    [SlashCommand("update", "Updates the web map")]
    public async Task UpdateAsync()
    {
        await DeferAsync();

        // Check if there's an active job
        if (await renderer.GetActiveJobStatus())
        {
            await FollowupAsync(embed: new EmbedBuilder()
                .WithTitle("Map update cannot be started")
                .WithDescription("There's already an active job running.")
                .WithColor(Color.Orange)
                .Build());
            return;
        }

        // Otherwise, start the job
        await renderer.UpdateAsync();
        await FollowupAsync(embed: new EmbedBuilder()
            .WithTitle("Map update started")
            .WithColor(Color.Blue)
            .Build());
    }
}
