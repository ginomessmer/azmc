using Discord.Interactions;
using Discord.Rest;

namespace Azmc.DiscordBot.Modules;

public class ServerModule : RestInteractionModuleBase<RestInteractionContext>
{
    [SlashCommand("status", "Gets the status of the server")]
    public Task PingAsync()
    {
        return RespondAsync("to be implemented");
    }
}
